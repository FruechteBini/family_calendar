import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pantry_repository.dart';
import '../domain/pantry_item.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/utils/date_utils.dart' as utils;
import '../../../core/api/api_client.dart';

final pantryItemsProvider = FutureProvider<List<PantryItem>>((ref) {
  return ref.watch(pantryRepositoryProvider).getItems();
});

final pantryAlertsProvider = FutureProvider<List<PantryAlert>>((ref) {
  return ref.watch(pantryRepositoryProvider).getAlerts();
});

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(pantryItemsProvider);
    final alertsAsync = ref.watch(pantryAlertsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Alerts banner
        alertsAsync.when(
          data: (alerts) {
            if (alerts.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text('${alerts.length} Warnung${alerts.length == 1 ? '' : 'en'}',
                          style: theme.textTheme.titleSmall?.copyWith(color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...alerts.take(5).map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${alert.itemName}: ${alert.alertType == 'low_stock' ? 'Niedrigbestand' : 'Laeuft ab'}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              onPressed: () async {
                                try {
                                  await ref.read(pantryRepositoryProvider).addAlertToShopping(alert.id);
                                  ref.invalidate(pantryAlertsProvider);
                                  if (mounted) showAppToast(context, message: 'Zur Einkaufsliste hinzugefuegt', type: ToastType.success);
                                } on ApiException catch (e) {
                                  if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
                                }
                              },
                              tooltip: 'Zur Einkaufsliste',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () async {
                                await ref.read(pantryRepositoryProvider).dismissAlert(alert.id);
                                ref.invalidate(pantryAlertsProvider);
                              },
                              tooltip: 'Verwerfen',
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(icon: Icons.kitchen, title: 'Vorratskammer leer', subtitle: 'Fuege Artikel hinzu');
              }
              final grouped = <String, List<PantryItem>>{};
              for (final item in items) {
                final cat = item.category ?? 'Sonstiges';
                (grouped[cat] ??= []).add(item);
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(pantryItemsProvider);
                  ref.invalidate(pantryAlertsProvider);
                },
                child: ListView(
                  children: grouped.entries.expand((entry) {
                    return [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(entry.key, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                      ),
                      ...entry.value.map((item) => _PantryTile(
                            item: item,
                            onEdit: () => _showForm(item: item),
                            onDelete: () => _delete(item),
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
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: FilledButton.icon(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text('Hinzufuegen'))),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _bulkAdd, icon: const Icon(Icons.playlist_add), label: const Text('Bulk')),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showForm({PantryItem? item}) async {
    final nameC = TextEditingController(text: item?.name ?? '');
    final quantityC = TextEditingController(text: item?.quantity?.toString() ?? '');
    final unitC = TextEditingController(text: item?.unit ?? '');
    final categoryC = TextEditingController(text: item?.category ?? '');
    final isEdit = item != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Artikel bearbeiten' : 'Neuer Artikel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: quantityC, decoration: const InputDecoration(labelText: 'Menge'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: unitC, decoration: const InputDecoration(labelText: 'Einheit'))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: categoryC, decoration: const InputDecoration(labelText: 'Kategorie')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Speichern' : 'Erstellen')),
        ],
      ),
    );
    if (result != true || nameC.text.trim().isEmpty) return;
    try {
      final data = {
        'name': nameC.text.trim(),
        'quantity': double.tryParse(quantityC.text),
        'unit': unitC.text.trim().isEmpty ? null : unitC.text.trim(),
        'category': categoryC.text.trim().isEmpty ? null : categoryC.text.trim(),
      };
      if (isEdit) {
        await ref.read(pantryRepositoryProvider).updateItem(item!.id, data);
      } else {
        await ref.read(pantryRepositoryProvider).addItem(data);
      }
      ref.invalidate(pantryItemsProvider);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _delete(PantryItem item) async {
    try {
      await ref.read(pantryRepositoryProvider).deleteItem(item.id);
      ref.invalidate(pantryItemsProvider);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _bulkAdd() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk hinzufuegen'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Salz, Pfeffer, 20 Dosen Tomaten'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Hinzufuegen')),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    try {
      final items = text.split(',').map((s) => {'name': s.trim()}).where((m) => m['name']!.isNotEmpty).toList();
      await ref.read(pantryRepositoryProvider).addBulk(items);
      ref.invalidate(pantryItemsProvider);
      if (mounted) showAppToast(context, message: '${items.length} Artikel hinzugefuegt', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }
}

class _PantryTile extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PantryTile({required this.item, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpiring = item.expiryDate != null && item.expiryDate!.difference(DateTime.now()).inDays <= 7;
    final isLowStock = item.quantity != null && item.quantity! <= (item.lowStockThreshold ?? 2);

    return ListTile(
      title: Text(item.name),
      subtitle: Row(
        children: [
          if (item.quantity != null) Text('${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}', style: theme.textTheme.bodySmall),
          if (item.expiryDate != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.schedule, size: 14, color: isExpiring ? Colors.orange : theme.colorScheme.outline),
            const SizedBox(width: 2),
            Text(utils.AppDateUtils.formatDate(item.expiryDate!),
                style: theme.textTheme.bodySmall?.copyWith(color: isExpiring ? Colors.orange : null)),
          ],
        ],
      ),
      leading: CircleAvatar(
        backgroundColor: isLowStock ? Colors.orange.withOpacity(0.2) : theme.colorScheme.primaryContainer,
        child: Icon(
          isLowStock ? Icons.warning_amber : Icons.inventory_2,
          color: isLowStock ? Colors.orange : theme.colorScheme.primary,
          size: 18,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }
}
