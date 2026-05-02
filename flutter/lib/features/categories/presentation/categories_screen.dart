import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/sync/sync_service.dart';
import '../../../shared/widgets/category_accent_chips.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../shared/widgets/toast.dart';
import '../categories_providers.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key, this.initialTab = 1});

  /// 0 = persönlich, 1 = Familie (Standard: Familie, wie bisher sichtbar).
  final int initialTab;

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<bool, List<Category>?> _orderOverride = {
    true: null,
    false: null,
  };

  bool _sameIdsUnordered(List<Category> a, List<Category> b) {
    if (a.length != b.length) return false;
    final sa = a.map((e) => e.id).toSet();
    return sa.length == a.length && b.every((e) => sa.contains(e.id));
  }

  @override
  void initState() {
    super.initState();
    final idx = widget.initialTab.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: idx);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _forPersonal => _tabController.index == 0;

  Color _parseColor(String hex) {
    try {
      return Color(
          int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _form(bool forPersonal, [Category? category]) async {
    final nameController =
        TextEditingController(text: category?.name ?? '');
    final isEdit = category != null;
    var selectedHex = category?.color ?? '#1565C0';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: Text(isEdit ? 'Kategorie bearbeiten' : 'Neue Kategorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledOutlineTextField(
                label: 'Name',
                controller: nameController,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              const SizedBox(height: 12),
              CategoryColorPickerTile(
                hex: selectedHex,
                onHexChanged: (h) => setModal(() => selectedHex = h),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Speichern' : 'Erstellen'),
            ),
          ],
        ),
      ),
    );
    if (result != true || nameController.text.trim().isEmpty) return;
    try {
      final data = {
        'name': nameController.text.trim(),
        'color': selectedHex.trim(),
        if (!isEdit) 'is_personal': forPersonal,
      };
      final repo = ref.read(categoryRepositoryProvider);
      if (isEdit) {
        await repo.updateCategory(category.id, data);
      } else {
        await repo.createCategory(data);
      }
      invalidateTodoCategoryCaches(ref);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _delete(bool forPersonal, Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategorie löschen?'),
        content: Text('"${category.name}" löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
      invalidateTodoCategoryCaches(ref);
      notifyDataMutated(ref);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Widget _tabBody(bool forPersonal) {
    final async = ref.watch(todoCategoriesScopeProvider(forPersonal));
    return async.when(
      data: (cats) {
        final o = _orderOverride[forPersonal];
        final display =
            (o != null && _sameIdsUnordered(o, cats)) ? o : cats;
        if (o != null && !_sameIdsUnordered(o, cats)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _orderOverride[forPersonal] = null);
            }
          });
        }
        if (display.isEmpty) {
          return EmptyState(
            icon: Icons.label_outline,
            title: forPersonal
                ? 'Keine persönlichen Kategorien'
                : 'Keine Familien-Kategorien',
            subtitle: forPersonal
                ? 'Nur du siehst diese Kategorien; nutze sie z. B. für persönliche Todos.'
                : 'Alle Familienmitglieder sehen diese Kategorien.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todoCategoriesScopeProvider(forPersonal));
          },
          child: ReorderableListView.builder(
            itemCount: display.length,
            onReorder: (oldIndex, newIndex) async {
              var ni = newIndex;
              if (ni > oldIndex) ni -= 1;
              final reordered = List<Category>.from(display);
              final item = reordered.removeAt(oldIndex);
              reordered.insert(ni, item);
              setState(() => _orderOverride[forPersonal] = reordered);
              try {
                await ref.read(categoryRepositoryProvider).reorderCategories(
                      reordered.map((c) => c.id).toList(),
                      isPersonal: forPersonal,
                    );
                if (mounted) {
                  setState(() => _orderOverride[forPersonal] = null);
                }
                invalidateTodoCategoryCaches(ref);
              } on ApiException catch (e) {
                if (mounted) {
                  setState(() => _orderOverride[forPersonal] = null);
                  showAppToast(context,
                      message: e.message, type: ToastType.error);
                }
              }
            },
            itemBuilder: (_, i) {
              final c = display[i];
              final color = _parseColor(c.color);
              return ListTile(
                key: ValueKey('todo_cat_${forPersonal}_${c.id}'),
                leading: CircleAvatar(
                  backgroundColor: color,
                  radius: 16,
                ),
                title: Text(c.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: Icon(Icons.drag_handle,
                          color: Theme.of(context).hintColor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () async {
                        await _form(forPersonal, c);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: () async {
                        await _delete(forPersonal, c);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Fehler',
        subtitle: e.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorien'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Persönlich'),
            Tab(text: 'Familie'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _tabBody(true),
          _tabBody(false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCategory',
        onPressed: () async {
          await _form(_forPersonal);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
