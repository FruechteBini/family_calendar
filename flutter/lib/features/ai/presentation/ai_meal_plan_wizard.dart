import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_repository.dart';
import '../domain/ai_models.dart';
import '../../meals/presentation/week_plan_provider.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../core/api/api_client.dart';
import '../../../core/sync/sync_service.dart';

class AiMealPlanWizard extends ConsumerStatefulWidget {
  const AiMealPlanWizard({super.key});

  @override
  ConsumerState<AiMealPlanWizard> createState() => _AiMealPlanWizardState();
}

class _AiMealPlanWizardState extends ConsumerState<AiMealPlanWizard> {
  int _step = 0; // 0=config, 1=loading, 2=preview, 3=confirmed
  AiAvailableRecipes? _available;
  Set<String> _selectedSlots = {};
  bool _includeCookidoo = false;
  bool _sendToKnuspr = false;
  int _servings = 2;
  final _preferencesController = TextEditingController();
  AiMealPlanPreview? _preview;
  AiMealPlanConfirmResult? _confirmResult;
  bool _loading = false;
  late final String _weekStart; // YYYY-MM-DD (Monday)

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayIso(DateTime.now());
    _loadAvailable();
  }

  @override
  void dispose() {
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailable() async {
    setState(() => _loading = true);
    try {
      _available = await ref.read(aiRepositoryProvider).getAvailableRecipes(
            weekStart: _weekStart,
            includeCookidoo: _includeCookidoo,
          );
      if (_available!.availableSlots.isNotEmpty) {
        _selectedSlots = _available!.availableSlots
            .where((s) => !s.occupied)
            .map((s) => '${s.date}|${s.slot}')
            .toSet();
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    if (_selectedSlots.isEmpty) {
      showAppToast(context, message: 'Bitte mindestens einen Slot wählen', type: ToastType.warning);
      return;
    }
    setState(() {
      _step = 1;
      _loading = true;
    });
    try {
      final slots = _selectedSlots.map((s) {
        final parts = s.split('|');
        return {'date': parts[0], 'slot': parts[1]};
      }).toList();
      _preview = await ref.read(aiRepositoryProvider).generateMealPlan(
        weekStart: _weekStart,
        selectedSlots: slots,
        includeCookidoo: _includeCookidoo,
        servings: _servings,
        preferences: _preferencesController.text.trim().isEmpty ? null : _preferencesController.text.trim(),
      );
      setState(() => _step = 2);
    } on ApiException catch (e) {
      setState(() => _step = 0);
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_preview == null) return;
    setState(() => _loading = true);
    try {
      _confirmResult = await ref.read(aiRepositoryProvider).confirmMealPlan(
            _weekStart,
            _preview!.suggestions,
            sendToKnuspr: _sendToKnuspr,
          );
      ref.invalidate(weekPlanProvider);
      ref.read(syncTickProvider.notifier).state++;
      await ref.read(weekPlanProvider.future);
      setState(() => _step = 3);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _undo() async {
    if (_confirmResult == null) return;
    try {
      await ref.read(aiRepositoryProvider).undoMealPlan(_confirmResult!.mealIds);
      ref.invalidate(weekPlanProvider);
      ref.read(syncTickProvider.notifier).state++;
      await ref.read(weekPlanProvider.future);
      if (mounted) {
        showAppToast(context, message: 'Plan rückgängig gemacht', type: ToastType.success);
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _step == 0
                            ? 'KI-Essensplan konfigurieren'
                            : _step == 1
                                ? 'Generiere Vorschlag...'
                                : _step == 2
                                    ? 'KI-Vorschlag'
                                    : 'Plan bestätigt!',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: _buildStep(theme),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _mondayIso(DateTime d) {
    final monday = DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
    return '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  String _knusprSummary(Map<String, dynamic> k) {
    if (k['error'] != null) return 'Knuspr: ${k['error']}';
    final ok = k['success'] == true;
    if (!ok) return 'Knuspr: fehlgeschlagen';
    final a = k['total_added'];
    final f = k['total_failed'];
    return 'Knuspr: $a Artikel hinzugefügt, $f fehlgeschlagen';
  }

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return _buildConfigStep(theme);
      case 1:
        return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
      case 2:
        return _buildPreviewStep(theme);
      case 3:
        return _buildConfirmedStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildConfigStep(ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final slots = _available?.availableSlots ?? const <AiSlotOption>[];
    final selectableKeys = slots
        .where((s) => !s.occupied)
        .map((s) => '${s.date}|${s.slot}')
        .toList(growable: false);
    final selectedCount =
        _selectedSlots.where((k) => selectableKeys.contains(k)).length;
    final totalSelectable = selectableKeys.length;

    final grouped = <String, List<AiSlotOption>>{};
    for (final s in slots) {
      final dayLabel = s.day ?? s.date;
      (grouped[dayLabel] ??= []).add(s);
    }

    // Keep ordering stable: Monday..Sunday if possible (backend uses German names)
    const weekdayOrder = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    final dayKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ia = weekdayOrder.indexOf(a);
        final ib = weekdayOrder.indexOf(b);
        if (ia == -1 && ib == -1) return a.compareTo(b);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Slots auswählen', style: theme.textTheme.titleSmall),
            ),
            if (totalSelectable > 0)
              Text(
                '$selectedCount/$totalSelectable',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_available == null)
          const SizedBox.shrink()
        else if (slots.isEmpty)
          Text(
            'Keine Slots gefunden.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: totalSelectable == 0
                    ? null
                    : () {
                        setState(() {
                          final keep = _selectedSlots
                              .where((k) => !selectableKeys.contains(k))
                              .toSet();
                          _selectedSlots = {...keep, ...selectableKeys};
                        });
                      },
                icon: const Icon(Icons.select_all),
                label: const Text('Alle'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: selectedCount == 0
                    ? null
                    : () {
                        setState(() {
                          _selectedSlots
                              .removeWhere((k) => selectableKeys.contains(k));
                        });
                      },
                icon: const Icon(Icons.clear),
                label: const Text('Keine'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...dayKeys.map((day) {
            final daySlots = grouped[day] ?? const <AiSlotOption>[];
            AiSlotOption? lunch;
            AiSlotOption? dinner;
            for (final s in daySlots) {
              if (s.slot == 'lunch') lunch = s;
              if (s.slot == 'dinner') dinner = s;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.25),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (lunch != null)
                          _SlotChip(
                            slot: lunch,
                            selectedKeys: _selectedSlots,
                            onToggle: (key, v) => setState(() => v
                                ? _selectedSlots.add(key)
                                : _selectedSlots.remove(key)),
                          ),
                        if (dinner != null)
                          _SlotChip(
                            slot: dinner,
                            selectedKeys: _selectedSlots,
                            onToggle: (key, v) => setState(() => v
                                ? _selectedSlots.add(key)
                                : _selectedSlots.remove(key)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Portionen: $_servings', style: theme.textTheme.bodyMedium),
            ),
            Slider(
              value: _servings.toDouble(),
              min: 1, max: 8, divisions: 7,
              label: '$_servings',
              onChanged: (v) => setState(() => _servings = v.round()),
            ),
          ],
        ),
        SwitchListTile(
          title: const Text('Cookidoo-Rezepte einbeziehen'),
          value: _includeCookidoo,
          onChanged: (v) {
            // Don't refetch here — it resets scroll position in the sheet.
            // The flag is applied when generating the plan.
            setState(() => _includeCookidoo = v);
          },
          contentPadding: EdgeInsets.zero,
        ),
        LabeledMultilineTextField(
          label: 'Wünsche / Präferenzen',
          controller: _preferencesController,
          hintText:
              'z.\u00a0B. vegetarisch, saisonal, schnelle Gerichte, Kinder lieber …',
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: 8),
        Text(
          '${_available?.localCount ?? 0} lokale Rezepte'
          '${(_available?.cookidooAvailable ?? false) ? ' · ${_available?.cookidooCount ?? 0} Cookidoo' : ''}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('KI-Plan generieren'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStep(ThemeData theme) {
    if (_preview == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_preview!.reasoning != null) ...[
          Card(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_preview!.reasoning!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...(_preview!.suggestions).map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(s.recipeName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.date} ${s.slot == 'lunch' ? 'Mittag' : 'Abend'}'),
                    if (s.reasoning != null)
                      Text(s.reasoning!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
                trailing: s.isCookidoo ? const Icon(Icons.cloud, size: 16) : null,
              ),
            )),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Direkt bei Knuspr bestellen'),
          subtitle: const Text(
            'Nach dem Speichern: offene Artikel in den Knuspr-Warenkorb legen',
          ),
          value: _sendToKnuspr,
          onChanged: _loading ? null : (v) => setState(() => _sendToKnuspr = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: const Icon(Icons.refresh),
                label: const Text('Neu generieren'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _loading ? null : _confirm,
                icon: const Icon(Icons.check),
                label: const Text('Bestätigen'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmedStep(ThemeData theme) {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text('Plan gespeichert!', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (_confirmResult?.shoppingListId != null)
          Text('Einkaufsliste wurde automatisch aktualisiert', style: theme.textTheme.bodyMedium),
        if (_confirmResult?.knuspr != null) ...[
          const SizedBox(height: 8),
          Text(
            _knusprSummary(_confirmResult!.knuspr!),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _undo,
              icon: const Icon(Icons.undo),
              label: const Text('Rückgängig'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fertig'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  final AiSlotOption slot;
  final Set<String> selectedKeys;
  final void Function(String key, bool selected) onToggle;

  const _SlotChip({
    required this.slot,
    required this.selectedKeys,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = '${slot.date}|${slot.slot}';
    final isSelected = selectedKeys.contains(key);
    final isDisabled = slot.occupied;
    final label = slot.label ?? (slot.slot == 'lunch' ? 'Mittag' : 'Abend');

    return FilterChip(
      selected: isSelected,
      onSelected: isDisabled ? null : (v) => onToggle(key, v),
      showCheckmark: !isDisabled,
      avatar: Icon(
        isDisabled
            ? Icons.lock
            : slot.slot == 'lunch'
                ? Icons.wb_sunny_outlined
                : Icons.nights_stay_outlined,
        size: 18,
        color: isDisabled
            ? theme.colorScheme.outline
            : isSelected
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        slot.recipeTitle != null ? '$label · ${slot.recipeTitle}' : label,
        overflow: TextOverflow.ellipsis,
      ),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: isDisabled
            ? theme.colorScheme.outline
            : isSelected
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurface,
      ),
      backgroundColor: theme.colorScheme.surface.withOpacity(0.35),
      selectedColor: theme.colorScheme.secondaryContainer,
      disabledColor:
          theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
      side: BorderSide(
        color: isDisabled
            ? theme.colorScheme.outlineVariant
            : isSelected
                ? theme.colorScheme.secondary
                : theme.colorScheme.outlineVariant,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
