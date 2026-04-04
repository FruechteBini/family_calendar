import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';

final shoppingListProvider = FutureProvider<ShoppingList>((ref) {
  return ref.watch(shoppingRepositoryProvider).getList();
});

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(shoppingRepositoryProvider).addItem({'name': text});
      _addController.clear();
      ref.invalidate(shoppingListProvider);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _toggleCheck(ShoppingItem item) async {
    try {
      await ref.read(shoppingRepositoryProvider).checkItem(item.id, checked: !item.checked);
      ref.invalidate(shoppingListProvider);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _generate() async {
    try {
      await ref.read(shoppingRepositoryProvider).generate();
      ref.invalidate(shoppingListProvider);
      if (mounted) showAppToast(context, message: 'Einkaufsliste generiert', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _aiSort() async {
    final list = ref.read(shoppingListProvider).valueOrNull;
    if (list == null) return;
    try {
      await ref.read(shoppingRepositoryProvider).aiSort(list.id);
      ref.invalidate(shoppingListProvider);
      if (mounted) showAppToast(context, message: 'KI-Sortierung angewendet', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Einkaufsliste',
          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
        ),
      ),
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addController,
                  decoration: const InputDecoration(hintText: 'Artikel hinzufuegen...', prefixIcon: Icon(Icons.add_shopping_cart), isDense: true),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _addItem, icon: const Icon(Icons.send)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              OutlinedButton.icon(onPressed: _generate, icon: const Icon(Icons.auto_awesome, size: 16), label: const Text('Generieren')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _aiSort, icon: const Icon(Icons.sort, size: 16), label: const Text('KI-Sortierung')),
            ],
          ),
        ),
        listAsync.when(
          data: (list) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: LinearProgressIndicator(value: list.progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Expanded(
          child: listAsync.when(
            data: (list) {
              if (list.items.isEmpty) {
                return const EmptyState(icon: Icons.shopping_cart_outlined, title: 'Einkaufsliste leer', subtitle: 'Generiere eine Liste aus dem Wochenplan');
              }
              final grouped = <String, List<ShoppingItem>>{};
              for (final item in list.items) {
                final cat = item.category ?? 'Sonstiges';
                (grouped[cat] ??= []).add(item);
              }
              final sortedCategories = grouped.keys.toList()..sort();
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(shoppingListProvider),
                child: ListView(
                  children: sortedCategories.expand((cat) {
                    return [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(cat, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                      ),
                      ...grouped[cat]!.map((item) => CheckboxListTile(
                            value: item.checked,
                            onChanged: (_) => _toggleCheck(item),
                            title: Text(
                              '${item.amount != null ? '${item.amount}${item.unit != null ? ' ${item.unit}' : ''} ' : ''}${item.name}',
                              style: item.checked ? theme.textTheme.bodyMedium?.copyWith(decoration: TextDecoration.lineThrough, color: theme.colorScheme.outline) : null,
                            ),
                            secondary: item.isManual
                                ? IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () async {
                                    await ref.read(shoppingRepositoryProvider).deleteItem(item.id);
                                    ref.invalidate(shoppingListProvider);
                                  })
                                : null,
                            dense: true,
                          )),
                    ];
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Fehler', subtitle: e.toString()),
          ),
        ),
      ],
      ),
    );
  }
}
