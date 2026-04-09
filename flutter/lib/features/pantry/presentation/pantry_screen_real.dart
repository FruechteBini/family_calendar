import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/app_input_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../core/sync/sync_service.dart';
import '../data/pantry_repository.dart';
import '../domain/pantry_item.dart';

final pantrySearchProvider = StateProvider<String>((ref) => '');
final pantryCategoryProvider = StateProvider<String?>((ref) => null);

final pantryItemsProvider = FutureProvider<List<PantryItem>>((ref) {
  // Refresh when global sync tick is bumped by mutations.
  ref.watch(syncTickProvider);
  final search = ref.watch(pantrySearchProvider);
  final category = ref.watch(pantryCategoryProvider);
  return ref.watch(pantryRepositoryProvider).getItems(category: category, search: search);
});

final pantryAlertsProvider = FutureProvider<List<PantryAlert>>((ref) {
  ref.watch(syncTickProvider);
  return ref.watch(pantryRepositoryProvider).getAlerts();
});

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(pantryItemsProvider);
    final alertsAsync = ref.watch(pantryAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pantryItemsProvider);
            ref.invalidate(pantryAlertsProvider);
            await ref.read(pantryItemsProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.spacing4,
                    AppColors.spacing4,
                    AppColors.spacing4,
                    AppColors.spacing2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Vorrat',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Artikel hinzufügen',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _openAddDialog(context, ref),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppColors.spacing2),
                      AppInputField(
                        hintText: 'Suchen…',
                        prefixIcon: Icons.search,
                        onChanged: (v) => ref.read(pantrySearchProvider.notifier).state = v,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _AlertsStrip(alertsAsync: alertsAsync),
              ),
              itemsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppColors.spacing6),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.kitchen_outlined,
                    title: 'Vorrat konnte nicht geladen werden',
                    subtitle: err is ApiException ? err.message : err.toString(),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.kitchen_outlined,
                        title: 'Noch keine Artikel',
                        subtitle: 'Füge etwas hinzu oder importiere aus Einkaufslisten.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppColors.spacing4,
                      AppColors.spacing2,
                      AppColors.spacing4,
                      100,
                    ),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _PantryItemTile(item: items[i]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final catCtrl = TextEditingController();

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Artikel hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledOutlineTextField(label: 'Name', controller: nameCtrl),
              const SizedBox(height: 12),
              LabeledOutlineTextField(
                label: 'Menge (optional)',
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              LabeledOutlineTextField(
                label: 'Einheit (optional)',
                controller: unitCtrl,
              ),
              const SizedBox(height: 12),
              LabeledOutlineTextField(
                label: 'Kategorie (optional)',
                controller: catCtrl,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            PrimaryButton(
              label: 'Speichern',
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );

    if (res != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final data = <String, dynamic>{'name': name};
    final qty = double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.'));
    if (qty != null) data['quantity'] = qty;
    if (unitCtrl.text.trim().isNotEmpty) data['unit'] = unitCtrl.text.trim();
    if (catCtrl.text.trim().isNotEmpty) data['category'] = catCtrl.text.trim();

    try {
      await ref.read(pantryRepositoryProvider).addItem(data);
      ref.invalidate(pantryItemsProvider);
      ref.read(syncTickProvider.notifier).state++;
      await ref.read(pantryItemsProvider.future);
      if (context.mounted) showAppToast(context, message: 'Hinzugefuegt', type: ToastType.success);
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }
}

class _AlertsStrip extends ConsumerWidget {
  final AsyncValue<List<PantryAlert>> alertsAsync;
  const _AlertsStrip({required this.alertsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppColors.spacing4,
        0,
        AppColors.spacing4,
        AppColors.spacing2,
      ),
      child: alertsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (alerts) {
          if (alerts.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Warnungen', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: alerts.take(8).map((a) {
                  return InputChip(
                    label: Text(a.itemName),
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (sheetCtx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text(a.itemName),
                                subtitle: Text(a.alertType),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.add_shopping_cart_outlined),
                                title: const Text('Zur Einkaufsliste'),
                                onTap: () async {
                                  Navigator.pop(sheetCtx);
                                  try {
                                    await ref.read(pantryRepositoryProvider).addAlertToShopping(a.id);
                                    ref.invalidate(pantryAlertsProvider);
                                    ref.read(syncTickProvider.notifier).state++;
                                    await ref.read(pantryAlertsProvider.future);
                                    if (context.mounted) showAppToast(context, message: 'Zur Liste hinzugefügt', type: ToastType.success);
                                  } on ApiException catch (e) {
                                    if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.visibility_off_outlined),
                                title: const Text('Ignorieren'),
                                onTap: () async {
                                  Navigator.pop(sheetCtx);
                                  try {
                                    await ref.read(pantryRepositoryProvider).dismissAlert(a.id);
                                    ref.invalidate(pantryAlertsProvider);
                                    ref.read(syncTickProvider.notifier).state++;
                                    await ref.read(pantryAlertsProvider.future);
                                    if (context.mounted) showAppToast(context, message: 'Ignoriert', type: ToastType.success);
                                  } on ApiException catch (e) {
                                    if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _PantryItemTile extends ConsumerWidget {
  final PantryItem item;
  const _PantryItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleParts = <String>[];
    if (item.quantity != null) subtitleParts.add(item.quantity!.toString());
    if (item.unit != null && item.unit!.isNotEmpty) subtitleParts.add(item.unit!);
    if (item.category != null && item.category!.isNotEmpty) subtitleParts.add('· ${item.category}');
    final subtitle = subtitleParts.join(' ');

    return Card(
      color: AppColors.surfaceContainerHigh,
      child: ListTile(
        title: Text(item.name),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'delete') {
              try {
                await ref.read(pantryRepositoryProvider).deleteItem(item.id);
                ref.invalidate(pantryItemsProvider);
                ref.read(syncTickProvider.notifier).state++;
                await ref.read(pantryItemsProvider.future);
              } on ApiException catch (e) {
                if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
              }
            }
            if (v == 'edit') {
              await _openEditDialog(context, ref, item);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
            PopupMenuItem(value: 'delete', child: Text('Löschen')),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, WidgetRef ref, PantryItem item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantity?.toString() ?? '');
    final unitCtrl = TextEditingController(text: item.unit ?? '');
    final catCtrl = TextEditingController(text: item.category ?? '');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Artikel bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LabeledOutlineTextField(label: 'Name', controller: nameCtrl),
            const SizedBox(height: 12),
            LabeledOutlineTextField(
              label: 'Menge (optional)',
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            LabeledOutlineTextField(
              label: 'Einheit (optional)',
              controller: unitCtrl,
            ),
            const SizedBox(height: 12),
            LabeledOutlineTextField(
              label: 'Kategorie (optional)',
              controller: catCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          PrimaryButton(label: 'Speichern', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );

    if (res != true) return;
    final data = <String, dynamic>{'name': nameCtrl.text.trim()};
    final qty = double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.'));
    data['quantity'] = qtyCtrl.text.trim().isEmpty ? null : qty;
    data['unit'] = unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim();
    data['category'] = catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim();

    try {
      await ref.read(pantryRepositoryProvider).updateItem(item.id, data);
      ref.invalidate(pantryItemsProvider);
      ref.read(syncTickProvider.notifier).state++;
      await ref.read(pantryItemsProvider.future);
      if (context.mounted) showAppToast(context, message: 'Gespeichert', type: ToastType.success);
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }
}

