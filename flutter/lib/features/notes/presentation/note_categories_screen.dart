import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/category_accent_chips.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_category_repository.dart';
import '../domain/note_category.dart';

class NoteCategoriesScreen extends ConsumerStatefulWidget {
  const NoteCategoriesScreen({super.key, this.initialTab = 0});

  /// 0 = persönlich, 1 = Familie
  final int initialTab;

  @override
  ConsumerState<NoteCategoriesScreen> createState() =>
      _NoteCategoriesScreenState();
}

class _NoteCategoriesScreenState extends ConsumerState<NoteCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Nur für sofortiges UI nach Drag&Drop; wird nach API-Erfolg geleert.
  final Map<bool, List<NoteCategory>?> _orderOverride = {
    true: null,
    false: null,
  };

  bool _sameIdsUnordered(List<NoteCategory> a, List<NoteCategory> b) {
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

  Future<void> _form(bool forPersonal, [NoteCategory? cat]) async {
    final name = TextEditingController(text: cat?.name ?? '');
    var selectedHex = cat?.color ?? '#1565C0';
    final icon = TextEditingController(text: cat?.icon ?? '\u{1F4DD}');
    final edit = cat != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: Text(edit ? 'Kategorie bearbeiten' : 'Neue Notiz-Kategorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CategoryColorPickerTile(
                hex: selectedHex,
                onHexChanged: (h) => setModal(() => selectedHex = h),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: icon,
                decoration: const InputDecoration(
                  labelText: 'Icon (Emoji)',
                  border: OutlineInputBorder(),
                ),
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
              child: Text(edit ? 'Speichern' : 'Erstellen'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final repo = ref.read(noteCategoryRepositoryProvider);
    final data = {
      'name': name.text.trim(),
      'color': selectedHex.trim(),
      'icon': icon.text.trim().isEmpty ? '\u{1F4DD}' : icon.text.trim(),
      if (!edit) 'is_personal': forPersonal,
    };
    try {
      if (edit) {
        await repo.updateCategory(cat.id, data);
      } else {
        await repo.createCategory(data);
      }
      invalidateNoteCategoryCaches(ref);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _delete(bool forPersonal, NoteCategory c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Löschen?'),
        content: Text('"${c.name}" löschen?'),
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
    if (ok != true) return;
    try {
      await ref.read(noteCategoryRepositoryProvider).deleteCategory(c.id);
      invalidateNoteCategoryCaches(ref);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Widget _tabBody(bool forPersonal) {
    final async = ref.watch(noteCategoriesListProvider(forPersonal));
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
            icon: Icons.folder_outlined,
            title: forPersonal
                ? 'Keine persönlichen Kategorien'
                : 'Keine Familien-Kategorien',
            subtitle: forPersonal
                ? 'Nur du siehst diese Kategorien bei persönlichen Notizen.'
                : 'Alle Familienmitglieder nutzen dieselben Kategorien bei Familien-Notizen.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(noteCategoriesListProvider(forPersonal));
          },
          child: ReorderableListView.builder(
            itemCount: display.length,
            onReorder: (oldIndex, newIndex) async {
              var ni = newIndex;
              if (ni > oldIndex) ni -= 1;
              final reordered = List<NoteCategory>.from(display);
              final item = reordered.removeAt(oldIndex);
              reordered.insert(ni, item);
              setState(() => _orderOverride[forPersonal] = reordered);
              try {
                await ref.read(noteCategoryRepositoryProvider).reorderCategories(
                      reordered.map((c) => c.id).toList(),
                      isPersonal: forPersonal,
                    );
                if (mounted) {
                  setState(() => _orderOverride[forPersonal] = null);
                }
                invalidateNoteCategoryCaches(ref);
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
              return ListTile(
                key: ValueKey('ncat_${forPersonal}_${c.id}'),
                leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
                title: Text(c.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        await _form(forPersonal, c);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
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
        title: const Text('Notiz-Kategorien'),
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
        heroTag: 'noteCatAdd',
        onPressed: () async {
          await _form(_forPersonal);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
