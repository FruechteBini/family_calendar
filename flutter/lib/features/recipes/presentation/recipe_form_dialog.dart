import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';

class RecipeFormDialog extends ConsumerStatefulWidget {
  final Recipe? recipe;
  const RecipeFormDialog({super.key, this.recipe});

  @override
  ConsumerState<RecipeFormDialog> createState() => _RecipeFormDialogState();
}

class _RecipeFormDialogState extends ConsumerState<RecipeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  String _difficulty = 'mittel';
  int? _prepTime;
  final List<_IngredientEntry> _ingredients = [];
  bool _saving = false;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameController = TextEditingController(text: r?.name ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _difficulty = r?.difficulty ?? 'mittel';
    _prepTime = r?.prepTime;
    if (r != null) {
      _ingredients.addAll(r.ingredients.map((i) => _IngredientEntry(
        nameController: TextEditingController(text: i.name),
        amountController: TextEditingController(text: i.amount?.toString() ?? ''),
        unitController: TextEditingController(text: i.unit ?? ''),
      )));
    }
    if (_ingredients.isEmpty) _addIngredient();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final i in _ingredients) {
      i.nameController.dispose();
      i.amountController.dispose();
      i.unitController.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientEntry(
      nameController: TextEditingController(),
      amountController: TextEditingController(),
      unitController: TextEditingController(),
    )));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ingredients = _ingredients
          .where((i) => i.nameController.text.trim().isNotEmpty)
          .map((i) => {
                'name': i.nameController.text.trim(),
                'amount': double.tryParse(i.amountController.text),
                'unit': i.unitController.text.trim().isEmpty ? null : i.unitController.text.trim(),
              })
          .toList();
      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'difficulty': _difficulty,
        'prep_time': _prepTime,
        'ingredients': ingredients,
      };
      final repo = ref.read(recipeRepositoryProvider);
      if (_isEditing) {
        await repo.updateRecipe(widget.recipe!.id, data);
      } else {
        await repo.createRecipe(data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rezept loeschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Loeschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(recipeRepositoryProvider).deleteRecipe(widget.recipe!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(_isEditing ? 'Rezept bearbeiten' : 'Neues Rezept', style: Theme.of(context).textTheme.titleLarge)),
                      if (_isEditing) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Name erforderlich' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Beschreibung'), maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(labelText: 'Schwierigkeit'),
                    items: ['einfach', 'mittel', 'schwer'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _difficulty = v ?? 'mittel'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _prepTime?.toString(),
                    decoration: const InputDecoration(labelText: 'Zubereitungszeit (Minuten)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _prepTime = int.tryParse(v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text('Zutaten', style: Theme.of(context).textTheme.titleSmall)),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addIngredient),
                    ],
                  ),
                  ..._ingredients.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ing = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 60, child: TextField(controller: ing.amountController, decoration: const InputDecoration(hintText: 'Menge', isDense: true), keyboardType: TextInputType.number)),
                          const SizedBox(width: 4),
                          SizedBox(width: 50, child: TextField(controller: ing.unitController, decoration: const InputDecoration(hintText: 'Einh.', isDense: true))),
                          const SizedBox(width: 4),
                          Expanded(child: TextField(controller: ing.nameController, decoration: const InputDecoration(hintText: 'Zutat', isDense: true))),
                          IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18), onPressed: () => setState(() => _ingredients.removeAt(idx))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isEditing ? 'Speichern' : 'Erstellen')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientEntry {
  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController unitController;

  _IngredientEntry({required this.nameController, required this.amountController, required this.unitController});
}
