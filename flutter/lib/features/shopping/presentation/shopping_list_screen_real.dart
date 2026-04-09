import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/app_input_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/toast.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../pantry/domain/pantry_item.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping.dart';

final shoppingListProvider = FutureProvider<ShoppingList?>((ref) {
  return ref.watch(shoppingRepositoryProvider).getList();
});

final pantryAlertsProvider = FutureProvider<List<PantryAlert>>((ref) {
  return ref.watch(pantryRepositoryProvider).getAlerts();
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

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider);
    final alertsAsync = ref.watch(pantryAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shoppingListProvider);
            ref.invalidate(pantryAlertsProvider);
            await ref.read(shoppingListProvider.future);
          },
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Einkaufsliste konnte nicht geladen werden',
              subtitle: err is ApiException ? err.message : err.toString(),
            ),
            data: (list) => _ShoppingListBody(
              list: list,
              alertsAsync: alertsAsync,
              addController: _addController,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShoppingListBody extends ConsumerWidget {
  final ShoppingList? list;
  final AsyncValue<List<PantryAlert>> alertsAsync;
  final TextEditingController addController;

  const _ShoppingListBody({
    required this.list,
    required this.alertsAsync,
    required this.addController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = list;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppColors.spacing4,
        AppColors.spacing6,
        AppColors.spacing4,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(list: l),
          const SizedBox(height: AppColors.spacing4),
          _ActionRow(list: l),
          const SizedBox(height: AppColors.spacing4),
          _PantryAlerts(alertsAsync: alertsAsync),
          const SizedBox(height: AppColors.spacing4),
          _AddRow(controller: addController),
          const SizedBox(height: AppColors.spacing6),
          if (l == null)
            const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Noch keine Einkaufsliste',
              subtitle: 'Tippe auf „Generieren“, um eine Liste aus dem Wochenplan zu erstellen.',
            )
          else
            _ItemsByCategory(items: l.items),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ShoppingList? list;
  const _Header({required this.list});

  @override
  Widget build(BuildContext context) {
    final l = list;
    final progress = l?.progress ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Einkauf',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: l == null ? 0 : progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l == null ? '0/0' : '${l.checkedItems}/${l.totalItems}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends ConsumerWidget {
  final ShoppingList? list;
  const _ActionRow({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> generate() async {
      try {
        await ref.read(shoppingRepositoryProvider).generate();
        ref.invalidate(shoppingListProvider);
        if (context.mounted) showAppToast(context, message: 'Liste erstellt', type: ToastType.success);
      } on ApiException catch (e) {
        if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
      }
    }

    Future<void> sortAi() async {
      try {
        await ref.read(shoppingRepositoryProvider).aiSort();
        ref.invalidate(shoppingListProvider);
        if (context.mounted) showAppToast(context, message: 'Sortiert', type: ToastType.success);
      } on ApiException catch (e) {
        if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
      }
    }

    Future<void> clearAll() async {
      try {
        await ref.read(shoppingRepositoryProvider).clearAll();
        ref.invalidate(shoppingListProvider);
        if (context.mounted) showAppToast(context, message: 'Liste geleert', type: ToastType.success);
      } on ApiException catch (e) {
        if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
      }
    }

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 380;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(label: 'Generieren', onPressed: generate),
              const SizedBox(height: 10),
              SecondaryButton(label: 'KI sortieren', onPressed: list == null ? null : sortAi),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Bei Knuspr bestellen',
                    onPressed: list == null ? null : () => context.go('/knuspr'),
                    icon: const Icon(Icons.local_shipping_outlined),
                  ),
                  IconButton(
                    tooltip: 'Alle löschen',
                    onPressed: list == null ? null : clearAll,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: PrimaryButton(label: 'Generieren', onPressed: generate)),
            const SizedBox(width: 12),
            Expanded(child: SecondaryButton(label: 'KI sortieren', onPressed: list == null ? null : sortAi)),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Bei Knuspr bestellen',
              onPressed: list == null ? null : () => context.go('/knuspr'),
              icon: const Icon(Icons.local_shipping_outlined),
            ),
            IconButton(
              tooltip: 'Alle löschen',
              onPressed: list == null ? null : clearAll,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        );
      },
    );
  }
}

class _PantryAlerts extends ConsumerWidget {
  final AsyncValue<List<PantryAlert>> alertsAsync;
  const _PantryAlerts({required this.alertsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return alertsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vorratswarnungen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: alerts.take(6).map((a) {
                return ActionChip(
                  label: Text(a.itemName),
                  onPressed: () async {
                    try {
                      await ref.read(pantryRepositoryProvider).addAlertToShopping(a.id);
                      ref.invalidate(shoppingListProvider);
                      ref.invalidate(pantryAlertsProvider);
                      if (context.mounted) {
                        showAppToast(context, message: 'Hinzugefuegt', type: ToastType.success);
                      }
                    } on ApiException catch (e) {
                      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _AddRow extends ConsumerWidget {
  final TextEditingController controller;
  const _AddRow({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: AppInputField(
            controller: controller,
            hintText: 'Artikel hinzufügen…',
            prefixIcon: Icons.add,
            onSubmitted: () => _submit(context, ref),
          ),
        ),
        const SizedBox(width: 12),
        PrimaryButton(
          label: 'Hinzufügen',
          onPressed: () => _submit(context, ref),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(shoppingRepositoryProvider).addItem({'name': text});
      controller.clear();
      ref.invalidate(shoppingListProvider);
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }
}

class _ItemsByCategory extends ConsumerWidget {
  final List<ShoppingItem> items;
  const _ItemsByCategory({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Liste ist leer',
        subtitle: 'Füge Artikel hinzu oder generiere aus dem Wochenplan.',
      );
    }

    final grouped = <String, List<ShoppingItem>>{};
    for (final it in items) {
      final key = (it.category ?? 'sonstiges').toString();
      (grouped[key] ??= []).add(it);
    }

    final keys = grouped.keys.toList()..sort();
    return Column(
      children: keys.map((k) {
        final list = grouped[k]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppColors.spacing6),
          child: _CategorySection(category: k, items: list),
        );
      }).toList(),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final String category;
  final List<ShoppingItem> items;
  const _CategorySection({required this.category, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...items.map((it) {
          final subtitle = [
            if (it.amount != null && it.amount!.isNotEmpty) it.amount!,
            if (it.unit != null && it.unit!.isNotEmpty) it.unit!,
          ].join(' ');
          return Card(
            color: AppColors.surfaceContainerHigh,
            child: ListTile(
              leading: Checkbox(
                value: it.checked,
                onChanged: (_) async {
                  try {
                    await ref.read(shoppingRepositoryProvider).checkItem(it.id, checked: !it.checked);
                    ref.invalidate(shoppingListProvider);
                  } on ApiException catch (e) {
                    if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
                  }
                },
              ),
              title: Text(it.name),
              subtitle: subtitle.isEmpty ? null : Text(subtitle),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  try {
                    await ref.read(shoppingRepositoryProvider).deleteItem(it.id);
                    ref.invalidate(shoppingListProvider);
                  } on ApiException catch (e) {
                    if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
                  }
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}

