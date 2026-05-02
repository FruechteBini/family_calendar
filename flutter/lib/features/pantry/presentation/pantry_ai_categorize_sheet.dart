import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';
import '../../ai/data/ai_repository.dart';
import '../../ai/domain/ai_models.dart';
import '../domain/pantry_item.dart';

/// Loads AI pantry preview; user confirms assignments by category before apply.
class PantryAiCategorizeSheet extends ConsumerStatefulWidget {
  const PantryAiCategorizeSheet({super.key});

  @override
  ConsumerState<PantryAiCategorizeSheet> createState() =>
      _PantryAiCategorizeSheetState();
}

class _PantryAiCategorizeSheetState extends ConsumerState<PantryAiCategorizeSheet> {
  bool _loading = true;
  String? _error;
  PantryCategorizationPreview? _preview;
  bool _applying = false;

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
      final p = await ref.read(aiRepositoryProvider).categorizePantry();
      if (mounted) {
        setState(() {
          _preview = p;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _apply() async {
    final p = _preview;
    if (p == null) return;
    setState(() => _applying = true);
    try {
      final res =
          await ref.read(aiRepositoryProvider).applyPantryCategorization(p);
      if (mounted) {
        showAppToast(
          context,
          message: '${res.updated} Artikel wurden den Kategorien zugeordnet',
          type: ToastType.success,
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'KI: Vorrat sortieren',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (!_loading && _error == null)
                      IconButton(
                        tooltip: 'Neu laden',
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: theme.colorScheme.error),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _load,
                                    child: const Text('Erneut versuchen'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildPreview(scrollController, theme),
              ),
              if (!_loading && _error == null && _preview != null)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _applying
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Abbrechen'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed:
                                (_applying || _preview!.assignments.isEmpty)
                                    ? null
                                    : _apply,
                            child: _applying
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Übernehmen'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(ScrollController sc, ThemeData theme) {
    final p = _preview!;
    if (p.assignments.isEmpty) {
      return ListView(
        controller: sc,
        padding: const EdgeInsets.all(24),
        children: [
          Text(p.summary.isEmpty ? 'Keine Artikel vorhanden.' : p.summary),
        ],
      );
    }

    final byCat = <String, List<PantryCategoryAssignment>>{};
    for (final a in p.assignments) {
      final k = a.category;
      byCat.putIfAbsent(k, () => []).add(a);
    }
    final catKeys = byCat.keys.toList()
      ..sort((a, b) =>
          pantryCategoryLabelDe(a).compareTo(pantryCategoryLabelDe(b)));

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        if (p.summary.isNotEmpty) ...[
          Text(p.summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        Text(
          '${p.assignments.length} Zuordnung(en)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final ck in catKeys) ...[
          Text(
            pantryCategoryLabelDe(ck),
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 6),
          ...byCat[ck]!.map(
            (a) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: theme.colorScheme.outline,
              ),
              title: Text(a.itemName, style: theme.textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
