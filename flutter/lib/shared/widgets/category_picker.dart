import 'package:flutter/material.dart';
import '../../features/categories/domain/category.dart';

class CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const CategoryPicker({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onChanged,
  });

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: selectedId,
      decoration: const InputDecoration(
        labelText: 'Kategorie',
        prefixIcon: Icon(Icons.label_outline),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Keine Kategorie'),
        ),
        ...categories.map((c) => DropdownMenuItem<int?>(
              value: c.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _parseColor(c.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(c.name),
                ],
              ),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
