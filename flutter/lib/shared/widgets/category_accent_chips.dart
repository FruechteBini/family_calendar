import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Preset palette for new categories (notes / quick-create flows).
const List<String> kCategoryPresetHexColors = [
  '#00BFA6',
  '#7C4DFF',
  '#FF6B6B',
  '#42A5F5',
  '#FFCA28',
  '#8D6E63',
  '#EC407A',
  '#26A69A',
  '#5C6BC0',
  '#FF9800',
  '#66BB6A',
  '#AB47BC',
];

Color parseCategoryHexColor(String? hex, ThemeData theme, {Color? fallback}) {
  if (hex == null || hex.isEmpty) {
    return fallback ?? theme.colorScheme.outline;
  }
  try {
    final cleaned = hex.replaceFirst('#', '').trim();
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
  } catch (_) {}
  return fallback ?? theme.colorScheme.outline;
}

/// `#RRGGBB` uppercase for API / storage (no alpha).
String categoryColorToHex(Color c) {
  final argb = c.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Preset swatches plus hue/sat picker; returns `#RRGGBB` or `null` if dismissed.
Future<String?> showCategoryHexColorPicker(
  BuildContext context, {
  required String initialHex,
}) async {
  final theme = Theme.of(context);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      var current = parseCategoryHexColor(
        initialHex,
        theme,
        fallback: const Color(0xFF1565C0),
      );
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final hexStr = categoryColorToHex(current);
          return AlertDialog(
            title: const Text('Farbe wählen'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    hexStr,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  CategoryPresetColorRow(
                    selectedHex: hexStr,
                    onSelect: (h) {
                      setDialogState(() {
                        current = parseCategoryHexColor(h, theme);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ColorPicker(
                    pickerColor: current,
                    onColorChanged: (c) => setDialogState(() => current = c),
                    enableAlpha: false,
                    labelTypes: const [],
                    pickerAreaHeightPercent: 0.72,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  categoryColorToHex(current),
                ),
                child: const Text('Übernehmen'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Tappable row: preview circle, label, hex; opens [showCategoryHexColorPicker].
class CategoryColorPickerTile extends StatelessWidget {
  const CategoryColorPickerTile({
    super.key,
    required this.hex,
    required this.onHexChanged,
    this.label = 'Farbe',
  });

  final String hex;
  final ValueChanged<String> onHexChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = parseCategoryHexColor(
      hex,
      theme,
      fallback: const Color(0xFF1565C0),
    );
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final next = await showCategoryHexColorPicker(
            context,
            initialHex: hex,
          );
          if (next != null) onHexChanged(next);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      hex.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.palette_outlined,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of tappable category chips with a soft tinted background.
class CategoryFilterStrip extends StatelessWidget {
  const CategoryFilterStrip({
    super.key,
    required this.entries,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.showAllChip = true,
    this.allLabel = 'Alle',
  });

  final List<CategoryStripEntry> entries;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;
  final bool showAllChip;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          if (showAllChip) ...[
            CategoryAccentChip(
              label: allLabel,
              accentColor: null,
              selected: selectedCategoryId == null,
              onTap: () => onCategorySelected(null),
            ),
            const SizedBox(width: 8),
          ],
          ...entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryAccentChip(
                label: e.label,
                accentColor: e.colorHex,
                selected: selectedCategoryId == e.id,
                onTap: () => onCategorySelected(e.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class CategoryStripEntry {
  final int id;
  final String label;
  final String? colorHex;

  const CategoryStripEntry({
    required this.id,
    required this.label,
    this.colorHex,
  });
}

class CategoryAccentChip extends StatelessWidget {
  const CategoryAccentChip({
    super.key,
    required this.label,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  /// Hex like `#RRGGBB`, or null for a neutral “Alle” style chip.
  final String? accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = parseCategoryHexColor(accentColor, theme);
    final isDark = theme.brightness == Brightness.dark;

    final Color bg;
    final Color borderColor;
    final Color fg;
    if (accentColor == null || accentColor!.isEmpty) {
      bg = selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.55 : 0.9)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.65);
      borderColor = selected
          ? theme.colorScheme.primary
          : theme.colorScheme.outline.withValues(alpha: 0.35);
      fg = selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant;
    } else {
      bg = selected
          ? accent.withValues(alpha: isDark ? 0.38 : 0.28)
          : accent.withValues(alpha: isDark ? 0.16 : 0.12);
      borderColor = selected
          ? accent.withValues(alpha: 0.95)
          : accent.withValues(alpha: 0.4);
      fg = selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.88);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Preset color swatches for dialogs (new category from note form, etc.).
class CategoryPresetColorRow extends StatelessWidget {
  const CategoryPresetColorRow({
    super.key,
    required this.selectedHex,
    required this.onSelect,
  });

  final String selectedHex;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kCategoryPresetHexColors.map((hex) {
        final c = parseCategoryHexColor(hex, theme);
        final sel = hex.toUpperCase() == selectedHex.toUpperCase();
        return InkWell(
          onTap: () => onSelect(hex),
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              border: Border.all(
                color: sel ? theme.colorScheme.onSurface : Colors.transparent,
                width: sel ? 3 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: sel
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: c.computeLuminance() > 0.55
                        ? Colors.black87
                        : Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
