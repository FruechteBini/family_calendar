import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_repository.dart';
import '../domain/ai_models.dart';
import '../../meals/presentation/week_plan_screen.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';

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
  int _servings = 2;
  final _preferencesController = TextEditingController();
  AiMealPlanPreview? _preview;
  AiMealPlanConfirmResult? _confirmResult;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
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
      _available = await ref.read(aiRepositoryProvider).getAvailableRecipes(includeCookidoo: _includeCookidoo);
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
      showAppToast(context, message: 'Bitte mindestens einen Slot waehlen', type: ToastType.warning);
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
      _confirmResult = await ref.read(aiRepositoryProvider).confirmMealPlan(_preview!.suggestions);
      ref.invalidate(weekPlanProvider);
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
      if (mounted) {
        showAppToast(context, message: 'Plan rueckgaengig gemacht', type: ToastType.success);
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _step == 0 ? 'KI-Essensplan konfigurieren'
                        : _step == 1 ? 'Generiere Vorschlag...'
                        : _step == 2 ? 'KI-Vorschlag'
                        : 'Plan bestaetigt!',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildStep(theme),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verfuegbare Slots', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_available != null)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _available!.availableSlots.map((slot) {
              final key = '${slot.date}|${slot.slot}';
              final isSelected = _selectedSlots.contains(key);
              return FilterChip(
                selected: isSelected,
                onSelected: (v) => setState(() => v ? _selectedSlots.add(key) : _selectedSlots.remove(key)),
                label: Text('${slot.date} ${slot.slot == 'lunch' ? 'Mittag' : 'Abend'}'),
                avatar: slot.occupied ? const Icon(Icons.restaurant, size: 16) : null,
              );
            }).toList(),
          ),
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
          onChanged: (v) => setState(() => _includeCookidoo = v),
          contentPadding: EdgeInsets.zero,
        ),
        TextField(
          controller: _preferencesController,
          decoration: const InputDecoration(
            labelText: 'Wuensche / Praeferenzen',
            hintText: 'z.B. vegetarisch, saisonal, schnelle Gerichte...',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Text('${_available?.recipes.length ?? 0} Rezepte verfuegbar',
            style: theme.textTheme.bodySmall),
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
                label: const Text('Bestaetigen'),
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
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _undo,
              icon: const Icon(Icons.undo),
              label: const Text('Rueckgaengig'),
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
