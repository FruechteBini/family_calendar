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
import '../../knuspr/data/knuspr_repository.dart';
import '../../knuspr/data/knuspr_status_provider.dart';
import '../../knuspr/domain/knuspr.dart';
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
  final Map<int, String> _knusprPriceByItemId = {};
  bool _knusprPricesLoading = false;

  Future<void> _loadKnusprPrices(ShoppingList list) async {
    setState(() => _knusprPricesLoading = true);
    _knusprPriceByItemId.clear();
    try {
      final unchecked = list.items.where((i) => !i.checked).toList();
      if (unchecked.isEmpty) {
        if (mounted) {
          showAppToast(context, message: 'Keine offenen Artikel', type: ToastType.info);
        }
        return;
      }
      final body = await ref.read(knusprRepositoryProvider).priceCheck(
            unchecked
                .map((i) => {
                      'name': i.name,
                      'shopping_item_id': i.id,
                    })
                .toList(),
          );
      final lines = body['lines'] as List<dynamic>? ?? [];
      final next = <int, String>{};
      for (final raw in lines) {
        final m = raw as Map<String, dynamic>;
        final id = m['shopping_item_id'] as int?;
        final found = m['found'] as bool? ?? false;
        if (id == null || !found) continue;
        final price = m['price'];
        if (price is num) {
          next[id] = '~${price.toStringAsFixed(2)} €';
        }
      }
      setState(() {
        _knusprPriceByItemId.addAll(next);
      });
      final total = body['estimated_total'];
      if (mounted && total is num) {
        showAppToast(
          context,
          message: 'Geschätzt bei Knuspr: ~${total.toStringAsFixed(2)} €',
          type: ToastType.success,
        );
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _knusprPricesLoading = false);
    }
  }

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
              knusprPriceByItemId: _knusprPriceByItemId,
              knusprPricesLoading: _knusprPricesLoading,
              onLoadKnusprPrices:
                  list == null ? null : () => _loadKnusprPrices(list),
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
  final Map<int, String> knusprPriceByItemId;
  final bool knusprPricesLoading;
  final VoidCallback? onLoadKnusprPrices;

  const _ShoppingListBody({
    required this.list,
    required this.alertsAsync,
    required this.addController,
    required this.knusprPriceByItemId,
    required this.knusprPricesLoading,
    required this.onLoadKnusprPrices,
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
          _ActionRow(
            list: l,
            knusprPricesLoading: knusprPricesLoading,
            onLoadKnusprPrices: onLoadKnusprPrices,
          ),
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
            _ItemsByCategory(
              items: l.items,
              knusprPriceByItemId: knusprPriceByItemId,
            ),
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
  final bool knusprPricesLoading;
  final VoidCallback? onLoadKnusprPrices;

  const _ActionRow({
    required this.list,
    required this.knusprPricesLoading,
    required this.onLoadKnusprPrices,
  });

  Future<void> _showKnusprResult(BuildContext context, KnusprSendResult r) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Knuspr'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hinzugefügt: ${r.totalAdded}, fehlgeschlagen: ${r.totalFailed}'),
              if (r.failed.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Fehler:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...r.failed.map((f) => Text('• ${f['item']}: ${f['reason']}')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showKnusprUnavailable(
    BuildContext context,
    WidgetRef ref,
    KnusprStatus? status,
  ) async {
    final configured = status?.configured ?? false;
    final msg = status?.message;
    final body = (msg != null && msg.isNotEmpty)
        ? msg
        : configured
            ? 'Die Knuspr-Verbindung ist derzeit nicht nutzbar. Bitte Server-Logs und Zugangsdaten prüfen.'
            : 'Knuspr ist auf dem Server nicht eingerichtet. Setze KNUSPR_EMAIL und KNUSPR_PASSWORD in der Backend-.env, installiere das Paket „knuspr“ und starte den Server neu.';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Knuspr'),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () {
              ref.invalidate(knusprStatusProvider);
              Navigator.pop(ctx);
            },
            child: const Text('Erneut prüfen'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final knusprAsync = ref.watch(knusprStatusProvider);
    final knusprOk = knusprAsync.maybeWhen(
      data: (s) => s.available,
      orElse: () => false,
    );
    final knusprStatusLoading = knusprAsync.isLoading;
    final knusprStatus = knusprAsync.valueOrNull;
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

    final l = list;
    List<Widget> knusprActions() {
      if (l == null) return [];
      if (knusprStatusLoading) {
        return [
          IconButton(
            tooltip: 'Knuspr wird geprüft…',
            onPressed: null,
            icon: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ];
      }
      if (!knusprOk) {
        return [
          IconButton(
            tooltip: 'Knuspr (nicht verfügbar – Tippen für Infos)',
            onPressed: () => _showKnusprUnavailable(context, ref, knusprStatus),
            icon: Icon(
              Icons.local_shipping_outlined,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.75),
            ),
          ),
        ];
      }
      return [
        if (onLoadKnusprPrices != null)
          IconButton(
            tooltip: 'Knuspr-Preise schätzen',
            onPressed: knusprPricesLoading
                ? null
                : () => onLoadKnusprPrices!(),
            icon: knusprPricesLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payments_outlined),
          ),
        PopupMenuButton<String>(
          tooltip: 'Knuspr',
          icon: const Icon(Icons.local_shipping_outlined),
          onSelected: (v) async {
            if (v == 'browse') context.push('/knuspr');
            if (v == 'review') context.push('/knuspr/review/${l.id}');
            if (v == 'quick') {
              try {
                final r =
                    await ref.read(knusprRepositoryProvider).sendShoppingList(l.id);
                if (context.mounted) await _showKnusprResult(context, r);
              } on ApiException catch (e) {
                if (context.mounted) {
                  showAppToast(context, message: e.message, type: ToastType.error);
                }
              }
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'review', child: Text('Produkte wählen…')),
            PopupMenuItem(value: 'quick', child: Text('Schnell in Warenkorb')),
            PopupMenuItem(value: 'browse', child: Text('Knuspr-App öffnen')),
          ],
        ),
      ];
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
                  ...knusprActions(),
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
            ...knusprActions(),
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
  final Map<int, String> knusprPriceByItemId;

  const _ItemsByCategory({
    required this.items,
    required this.knusprPriceByItemId,
  });

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
          child: _CategorySection(
            category: k,
            items: list,
            knusprPriceByItemId: knusprPriceByItemId,
          ),
        );
      }).toList(),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final String category;
  final List<ShoppingItem> items;
  final Map<int, String> knusprPriceByItemId;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.knusprPriceByItemId,
  });

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
          final knHint = knusprPriceByItemId[it.id];
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
              subtitle: () {
                final parts = <String>[];
                if (subtitle.isNotEmpty) parts.add(subtitle);
                if (knHint != null) parts.add('Knuspr: $knHint');
                if (parts.isEmpty) return null;
                return Text(parts.join(' · '));
              }(),
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

