import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/app_input_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

// ── Mock Data Models ──────────────────────────────────────────────────

class _ShoppingItemData {
  final String name;
  final String quantity;
  bool checked;

  _ShoppingItemData({
    required this.name,
    required this.quantity,
    this.checked = false,
  });
}

class _CategoryData {
  final String name;
  final IconData? icon;
  final List<_ShoppingItemData> items;

  _CategoryData({
    required this.name,
    this.icon,
    required this.items,
  });
}

class _PantryAlert {
  final String itemName;
  final String reason;

  const _PantryAlert({
    required this.itemName,
    required this.reason,
  });
}

// ── Screen ────────────────────────────────────────────────────────────

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _addController = TextEditingController();
  bool _hasText = false;

  // ── Sample categories & items ───────────────────────────────────────
  late final List<_CategoryData> _categories;

  // ── Sample pantry alerts ────────────────────────────────────────────
  final List<_PantryAlert> _pantryAlerts = const [
    _PantryAlert(itemName: 'Milch', reason: 'Nur noch 200ml übrig'),
    _PantryAlert(itemName: 'Eier', reason: 'Seit 2 Wochen nicht gekauft'),
    _PantryAlert(itemName: 'Butter', reason: 'Fehlt im Vorrat'),
  ];

  @override
  void initState() {
    super.initState();
    _addController.addListener(_onTextChanged);

    _categories = [
      _CategoryData(
        name: 'Obst & Gemüse',
        icon: Icons.eco_outlined,
        items: [
          _ShoppingItemData(name: 'Äpfel', quantity: '3 Stück'),
          _ShoppingItemData(name: 'Bananen', quantity: '1 Bund'),
          _ShoppingItemData(name: 'Tomaten', quantity: '500g'),
        ],
      ),
      _CategoryData(
        name: 'Milchprodukte',
        icon: Icons.local_drink_outlined,
        items: [
          _ShoppingItemData(name: 'Milch', quantity: '1L'),
          _ShoppingItemData(name: 'Käse', quantity: '200g'),
          _ShoppingItemData(name: 'Joghurt', quantity: '500g'),
        ],
      ),
      _CategoryData(
        name: 'Fleisch & Fisch',
        icon: Icons.set_meal_outlined,
        items: [
          _ShoppingItemData(name: 'Hähnchenbrust', quantity: '400g'),
        ],
      ),
      _CategoryData(
        name: 'Backwaren',
        icon: Icons.bakery_dining_outlined,
        items: [
          _ShoppingItemData(name: 'Brot', quantity: '1 Laib'),
        ],
      ),
      _CategoryData(
        name: 'Getränke',
        icon: Icons.water_drop_outlined,
        items: [
          _ShoppingItemData(name: 'Wasser', quantity: '6 Flaschen'),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _addController.removeListener(_onTextChanged);
    _addController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _addController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  int get _totalItems =>
      _categories.fold(0, (sum, cat) => sum + cat.items.length);

  int get _checkedItems =>
      _categories.fold(0, (sum, cat) => sum + cat.items.where((i) => i.checked).length);

  void _toggleItem(_ShoppingItemData item) {
    setState(() => item.checked = !item.checked);
  }

  void _deleteItem(_CategoryData category, _ShoppingItemData item) {
    setState(() => category.items.remove(item));
  }

  void _addItem() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      // Add to first category or "Sonstiges"
      _categories.first.items.add(
        _ShoppingItemData(name: text, quantity: ''),
      );
    });
    _addController.clear();
  }

  void _addPantryItem(String itemName) {
    setState(() {
      _categories.first.items.add(
        _ShoppingItemData(name: itemName, quantity: ''),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppColors.spacing4,
            AppColors.spacing6,
            AppColors.spacing4,
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. HEADER ────────────────────────────────────────────
              _buildHeader(theme),
              const SizedBox(height: AppColors.spacing4),

              // ── 2. ACTION BUTTONS ────────────────────────────────────
              _buildActionButtons(),
              const SizedBox(height: AppColors.spacing4),

              // ── 3. PANTRY ALERTS ─────────────────────────────────────
              if (_pantryAlerts.isNotEmpty) ...[
                _buildPantryAlerts(theme),
                const SizedBox(height: AppColors.spacing4),
              ],

              // ── 4. INPUT FIELD ───────────────────────────────────────
              _buildInputField(),
              const SizedBox(height: AppColors.spacing6),

              // ── 5. CATEGORY LISTS ────────────────────────────────────
              ..._categories.map(
                (cat) => _CategorySection(
                  category: cat,
                  onToggle: _toggleItem,
                  onDelete: (item) => _deleteItem(cat, item),
                ),
              ),

              const SizedBox(height: AppColors.spacing4),

              // ── 6. VORRATSKAMMER LINK ────────────────────────────────
              _buildPantryLink(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Einkauf',
          style: theme.textTheme.displaySmall?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$_checkedItems von $_totalItems erledigt',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Action Buttons ──────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            label: 'Mit Essensplan syncen',
            icon: Icons.sync_rounded,
            horizontalPadding: AppColors.spacing3,
            onPressed: () {
              // Mock action
            },
          ),
        ),
        const SizedBox(width: AppColors.spacing3),
        Expanded(
          child: _KnusprButton(
            onPressed: () {
              // Mock action
            },
          ),
        ),
      ],
    );
  }

  // ── Pantry Alerts ───────────────────────────────────────────────────

  Widget _buildPantryAlerts(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppColors.radiusDefault),
      ),
      padding: const EdgeInsets.all(AppColors.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'PANTRY ALERTS',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacing3),
          ..._pantryAlerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.itemName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          alert.reason,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _addPantryItem(alert.itemName),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppColors.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spacing3,
                        vertical: 6,
                      ),
                      child: Text(
                        'Hinzufügen',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Field ─────────────────────────────────────────────────────

  Widget _buildInputField() {
    final cs = Theme.of(context).colorScheme;
    return AppInputField(
      controller: _addController,
      hintText: 'Neuen Artikel hinzufügen...',
      prefixIcon: Icons.add_shopping_cart,
      suffixIcon: _hasText
          ? GestureDetector(
              onTap: _addItem,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: cs.onPrimaryContainer,
                ),
              ),
            )
          : null,
      onChanged: (_) => _onTextChanged(),
      onSubmitted: _addItem,
    );
  }

  // ── Pantry Link ────────────────────────────────────────────────────

  Widget _buildPantryLink(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppColors.spacing4),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppColors.radiusDefault),
        child: Container(
          padding: const EdgeInsets.all(AppColors.spacing4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          ),
          child: Row(
            children: [
              Icon(
                Icons.kitchen_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Zur Vorratskammer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Knuspr Button (surfaceContainerHigh style) ─────────────────────────

class _KnusprButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _KnusprButton({this.onPressed});

  @override
  State<_KnusprButton> createState() => _KnusprButtonState();
}

class _KnusprButtonState extends State<_KnusprButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onPressed != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppColors.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing3,
            vertical: AppColors.spacing4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.send_outlined,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'An Knuspr senden',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Section ───────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final _CategoryData category;
  final ValueChanged<_ShoppingItemData> onToggle;
  final ValueChanged<_ShoppingItemData> onDelete;

  const _CategorySection({
    required this.category,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header — NO divider, only spacing
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (category.icon != null) ...[
                  Icon(
                    category.icon,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  category.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...category.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ShoppingItemWidget(
                item: item,
                onToggle: () => onToggle(item),
                onDelete: () => onDelete(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shopping Item Widget ───────────────────────────────────────────────

class _ShoppingItemWidget extends StatefulWidget {
  final _ShoppingItemData item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ShoppingItemWidget({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_ShoppingItemWidget> createState() => _ShoppingItemWidgetState();
}

class _ShoppingItemWidgetState extends State<_ShoppingItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChecked = widget.item.checked;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 48,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceContainerHigh
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing4),
          child: Row(
            children: [
              // Checkbox (20x20 circle)
              GestureDetector(
                onTap: widget.onToggle,
                child: _buildCheckbox(isChecked),
              ),
              const SizedBox(width: AppColors.spacing3),

              // Item name
              Expanded(
                child: Text(
                  widget.item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isChecked
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.onSurfaceVariant,
                  ),
                ),
              ),

              // Quantity
              if (widget.item.quantity.isNotEmpty) ...[
                Text(
                  widget.item.quantity,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Delete icon
              GestureDetector(
                onTap: widget.onDelete,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isChecked) {
    const double size = 20;
    final cs = Theme.of(context).colorScheme;

    if (isChecked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary,
        ),
        child: Icon(
          Icons.check,
          size: 14,
          color: cs.onPrimaryContainer,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 2,
        ),
      ),
    );
  }
}

// ── Pantry Link ────────────────────────────────────────────────────────

class _PantryLink extends StatefulWidget {
  const _PantryLink();

  @override
  State<_PantryLink> createState() => _PantryLinkState();
}

class _PantryLinkState extends State<_PantryLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Navigate to pantry
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceContainer
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          ),
          padding: const EdgeInsets.all(AppColors.spacing4),
          child: Row(
            children: [
              const Icon(
                Icons.kitchen_rounded,
                size: 24,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppColors.spacing3),
              Expanded(
                child: Text(
                  'Vorratskammer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 24,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
