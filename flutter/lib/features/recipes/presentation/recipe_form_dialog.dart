import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../data/recipe_category_repository.dart';
import '../data/recipe_repository.dart';
import '../data/recipe_tag_repository.dart';
import '../domain/recipe.dart';
import '../domain/recipe_category.dart';
import '../domain/recipe_tag.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../shared/widgets/form_input_decoration.dart';
import '../../../core/api/api_client.dart';
import '../recipe_image_auth.dart';

final _formRecipeCategoriesProvider =
    FutureProvider<List<RecipeCategory>>((ref) {
  return ref.watch(recipeCategoryRepositoryProvider).getCategories();
});

final _formRecipeTagsProvider = FutureProvider<List<RecipeTag>>((ref) {
  return ref.watch(recipeTagRepositoryProvider).getTags();
});

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
  late TextEditingController _instructionsController;
  String _difficulty = 'mittel';
  int? _prepTime;
  String? _imageUrl;
  Uint8List? _pendingRecipePhotoBytes;
  String? _pendingRecipePhotoFilename;
  final List<_IngredientEntry> _ingredients = [];
  bool _saving = false;
  int? _categoryId;
  final Set<int> _selectedTagIds = {};

  bool get _isEditing => widget.recipe != null && (widget.recipe!.id != 0);

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameController = TextEditingController(text: r?.name ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _instructionsController = TextEditingController(text: r?.instructions ?? '');
    _difficulty = r?.difficulty ?? 'mittel';
    _prepTime = r?.prepTime;
    _imageUrl = r?.imageUrl;
    if (r != null) {
      _categoryId = r.categoryId;
      _selectedTagIds.addAll(r.tags.map((t) => t.id));
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
    _instructionsController.dispose();
    for (final i in _ingredients) {
      i.nameController.dispose();
      i.amountController.dispose();
      i.unitController.dispose();
    }
    super.dispose();
  }

  Future<void> _showCreateTagDialog() async {
    final nameController = TextEditingController();
    final colorController = TextEditingController(text: '#6B7280');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neues Rezept-Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LabeledOutlineTextField(
              label: 'Name',
              controller: nameController,
              prefixIcon: const Icon(Icons.label_outline),
            ),
            const SizedBox(height: 12),
            LabeledOutlineTextField(
              label: 'Farbe (Hex)',
              controller: colorController,
              hintText: '#6B7280',
              prefixIcon: const Icon(Icons.palette_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
    if (ok != true || nameController.text.trim().isEmpty) return;
    try {
      final created = await ref.read(recipeTagRepositoryProvider).createTag({
        'name': nameController.text.trim(),
        'color': colorController.text.trim(),
      });
      ref.invalidate(_formRecipeTagsProvider);
      setState(() => _selectedTagIds.add(created.id));
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientEntry(
      nameController: TextEditingController(),
      amountController: TextEditingController(),
      unitController: TextEditingController(),
    )));
  }

  Future<void> _pickRecipePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pendingRecipePhotoBytes = bytes;
      _pendingRecipePhotoFilename =
          kIsWeb ? (x.name.isNotEmpty ? x.name : 'photo.jpg') : path.basename(x.path);
    });
  }

  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Aus Galerie wählen'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickRecipePhoto(source);
  }

  Future<void> _removeCoverPhoto() async {
    setState(() {
      _pendingRecipePhotoBytes = null;
      _pendingRecipePhotoFilename = null;
    });
    if (_isEditing &&
        widget.recipe!.id > 0 &&
        recipeImageUrlNeedsAuth(_imageUrl)) {
      try {
        await ref
            .read(recipeRepositoryProvider)
            .updateRecipe(widget.recipe!.id, {'image_url': null});
        if (mounted) setState(() => _imageUrl = null);
      } on ApiException catch (e) {
        if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
      }
    } else {
      setState(() => _imageUrl = null);
    }
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
      const diffMap = {'einfach': 'easy', 'mittel': 'medium', 'schwer': 'hard'};
      final data = <String, dynamic>{
        'title': _nameController.text.trim(),
        'notes': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'instructions': _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        'difficulty': diffMap[_difficulty] ?? 'medium',
        'prep_time_active_minutes': _prepTime,
        if (_pendingRecipePhotoBytes == null &&
            _imageUrl != null &&
            _imageUrl!.trim().isNotEmpty)
          'image_url': _imageUrl!.trim(),
        if (!_isEditing && widget.recipe?.sourceUrl != null) 'source': 'web',
        'ingredients': ingredients,
        'recipe_category_id': _categoryId,
        'tag_ids': _selectedTagIds.toList(),
      };
      final repo = ref.read(recipeRepositoryProvider);
      final Recipe saved;
      if (_isEditing) {
        saved = await repo.updateRecipe(widget.recipe!.id, data);
      } else {
        saved = await repo.createRecipe(data);
      }
      if (_pendingRecipePhotoBytes != null && saved.id > 0) {
        try {
          await repo.uploadRecipeImage(
            saved.id,
            _pendingRecipePhotoBytes!,
            _pendingRecipePhotoFilename ?? 'photo.jpg',
          );
        } on ApiException catch (e) {
          if (mounted) {
            showAppToast(
              context,
              message: 'Rezept gespeichert, Foto-Upload: ${e.message}',
              type: ToastType.error,
            );
          }
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rezept löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
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
                  if (_pendingRecipePhotoBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.memory(
                          _pendingRecipePhotoBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _saving ? null : _showPhotoSourceSheet,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text('Anderes Foto'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _saving ? null : _removeCoverPhoto,
                          child: const Text('Entfernen'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else if (_imageUrl != null && _imageUrl!.trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: recipeImageUrlNeedsAuth(_imageUrl)
                            ? CachedNetworkImage(
                                imageUrl: recipeImageAbsoluteUrl(ref, _imageUrl!),
                                httpHeaders: recipeImageRequestHeaders(ref),
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.restaurant),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.restaurant),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _saving ? null : _showPhotoSourceSheet,
                          icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                          label: const Text('Foto ändern'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _saving ? null : _removeCoverPhoto,
                          child: const Text('Entfernen'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _showPhotoSourceSheet,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Foto hinzufügen'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Name erforderlich' : null),
                  const SizedBox(height: 12),
                  LabeledMultilineTextField(
                    label: 'Beschreibung',
                    controller: _descController,
                    hintText:
                        'Optional — Kurzinfo, Notizen, Varianten, Portionshinweise …',
                  ),
                  const SizedBox(height: 12),
                  LabeledMultilineTextField(
                    label: 'Zubereitung',
                    controller: _instructionsController,
                    hintText: 'Optional — Schritt für Schritt, aus Import oder manuell',
                  ),
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
                  ref.watch(_formRecipeCategoriesProvider).when(
                        data: (cats) => DropdownButtonFormField<int?>(
                          value: _categoryId,
                          decoration: appFormInputDecoration(
                            context,
                            labelText: 'Rezept-Kategorie',
                            prefixIcon: const Icon(Icons.restaurant_menu_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Keine Kategorie'),
                            ),
                            ...cats.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text('${c.icon} ${c.name}'),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tags',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving ? null : _showCreateTagDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Neu'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ref.watch(_formRecipeTagsProvider).when(
                        data: (tags) {
                          if (tags.isEmpty) {
                            return Text(
                              'Keine Tags — unter Rezepten verwalten oder KI nutzen.',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags
                                .map(
                                  (t) => FilterChip(
                                    label: Text(t.name),
                                    selected: _selectedTagIds.contains(t.id),
                                    onSelected: (sel) {
                                      setState(() {
                                        if (sel) {
                                          _selectedTagIds.add(t.id);
                                        } else {
                                          _selectedTagIds.remove(t.id);
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
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
