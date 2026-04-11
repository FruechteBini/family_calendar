import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';
import '../data/knuspr_repository.dart';
import '../domain/knuspr.dart';

/// Review Knuspr matches before adding to cart (after preview API).
class KnusprReviewScreen extends ConsumerStatefulWidget {
  final int shoppingListId;

  const KnusprReviewScreen({super.key, required this.shoppingListId});

  @override
  ConsumerState<KnusprReviewScreen> createState() => _KnusprReviewScreenState();
}

class _KnusprReviewScreenState extends ConsumerState<KnusprReviewScreen> {
  PreviewShoppingListPayload? _payload;
  bool _loading = true;
  String? _error;
  /// Per line: selected match index or -1 = skip
  final Map<int, int> _choiceByItemId = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await ref
          .read(knusprRepositoryProvider)
          .previewShoppingList(widget.shoppingListId);
      for (final line in p.lines) {
        _choiceByItemId[line.shoppingItemId] =
            line.matches.isEmpty ? -1 : 0;
      }
      setState(() {
        _payload = p;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _apply() async {
    final payload = _payload;
    if (payload == null) return;
    final selections = <Map<String, dynamic>>[];
    for (final line in payload.lines) {
      final idx = _choiceByItemId[line.shoppingItemId] ?? -1;
      if (idx < 0 || idx >= line.matches.length) continue;
      final m = line.matches[idx];
      if (!m.available) continue;
      selections.add({
        'item_name': line.itemName,
        'product_id': m.productId,
        'quantity': line.quantity,
        'product_name': m.name,
      });
    }
    if (selections.isEmpty) {
      showAppToast(context,
          message: 'Keine Artikel ausgewählt', type: ToastType.warning);
      return;
    }
    try {
      final result = await ref
          .read(knusprRepositoryProvider)
          .applySelections(widget.shoppingListId, selections);
      if (!mounted) return;
      if (result.success) {
        showAppToast(context,
            message:
                '${result.totalAdded} Artikel im Knuspr-Warenkorb, ${result.totalFailed} fehlgeschlagen',
            type: result.totalFailed > 0 ? ToastType.warning : ToastType.success);
        context.pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knuspr – Auswahl'),
        actions: [
          TextButton(
            onPressed: _loading || _payload == null ? null : _apply,
            child: const Text('In Warenkorb'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _payload == null || _payload!.lines.isEmpty
                  ? const Center(child: Text('Keine offenen Artikel'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _payload!.lines.length,
                      itemBuilder: (context, i) {
                        final line = _payload!.lines[i];
                        final sel = _choiceByItemId[line.shoppingItemId] ?? 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.itemName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  'Menge: ${line.quantity}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                if (line.matches.isEmpty)
                                  const Text(
                                    'Keine Treffer bei Knuspr',
                                    style: TextStyle(color: Colors.orange),
                                  )
                                else
                                  DropdownButtonFormField<int>(
                                    value: sel < 0 ? -1 : sel,
                                    decoration: const InputDecoration(
                                      labelText: 'Produkt',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: -1,
                                        child: Text('Überspringen'),
                                      ),
                                      ...List.generate(
                                        line.matches.length,
                                        (j) {
                                          final m = line.matches[j];
                                          final price = m.price != null
                                              ? ' ${m.price!.toStringAsFixed(2)} €'
                                              : '';
                                          return DropdownMenuItem(
                                            value: j,
                                            child: Text(
                                              '${m.name}$price${m.available ? '' : ' (n.v.)'}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        _choiceByItemId[line.shoppingItemId] =
                                            v ?? -1;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
