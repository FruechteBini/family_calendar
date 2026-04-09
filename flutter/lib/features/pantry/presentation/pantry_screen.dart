import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/primary_button.dart';

// ── Mock Data Models ──────────────────────────────────────────────────

class _PantryAlert {
  final String itemName;
  final String alertType; // 'low_stock' | 'expiring_soon'
  final String detail;

  const _PantryAlert({
    required this.itemName,
    required this.alertType,
    required this.detail,
  });
}

class _PantryItemData {
  final String name;
  final String? detail;
  final String quantity;
  final String unit;
  final double? progress; // 0.0 – 1.0, null = no bar
  final IconData categoryIcon;

  const _PantryItemData({
    required this.name,
    this.detail,
    required this.quantity,
    required this.unit,
    this.progress,
    required this.categoryIcon,
  });
}

class _PantryCategory {
  final String title;
  final IconData icon;
  final List<_PantryItemData> items;

  const _PantryCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

// ── Sample Data ───────────────────────────────────────────────────────

const List<_PantryAlert> _sampleAlerts = [
  _PantryAlert(
    itemName: 'Orangensaft',
    alertType: 'low_stock',
    detail: 'Nur noch 200ml übrig',
  ),
  _PantryAlert(
    itemName: 'Butter',
    alertType: 'expiring_soon',
    detail: 'Läuft ab am 15.04.2024',
  ),
  _PantryAlert(
    itemName: 'Müsli',
    alertType: 'low_stock',
    detail: 'Nur noch 30% vorhanden',
  ),
];

const List<_PantryCategory> _sampleCategories = [
  _PantryCategory(
    title: 'Getreide & Nudeln',
    icon: Icons.grain,
    items: [
      _PantryItemData(
        name: 'Pasta',
        detail: 'Zuletzt genutzt: 01.04.2024',
        quantity: '500',
        unit: 'g',
        progress: 0.80,
        categoryIcon: Icons.grain,
      ),
      _PantryItemData(
        name: 'Reis',
        detail: 'Läuft ab: 22.12.2024',
        quantity: '1',
        unit: 'kg',
        progress: 0.60,
        categoryIcon: Icons.grain,
      ),
      _PantryItemData(
        name: 'Müsli',
        detail: 'Zuletzt genutzt: 05.04.2024',
        quantity: '750',
        unit: 'g',
        progress: 0.30,
        categoryIcon: Icons.grain,
      ),
    ],
  ),
  _PantryCategory(
    title: 'Milchprodukte',
    icon: Icons.egg,
    items: [
      _PantryItemData(
        name: 'Butter',
        detail: 'Läuft ab: 15.04.2024',
        quantity: '250',
        unit: 'g',
        progress: 0.45,
        categoryIcon: Icons.egg,
      ),
      _PantryItemData(
        name: 'Käse',
        detail: 'Läuft ab: 28.04.2024',
        quantity: '200',
        unit: 'g',
        progress: 0.70,
        categoryIcon: Icons.egg,
      ),
    ],
  ),
  _PantryCategory(
    title: 'Gewürze',
    icon: Icons.local_fire_department,
    items: [
      _PantryItemData(
        name: 'Salz',
        detail: 'Zuletzt genutzt: 08.04.2024',
        quantity: '300',
        unit: 'g',
        categoryIcon: Icons.local_fire_department,
      ),
      _PantryItemData(
        name: 'Pfeffer',
        detail: 'Zuletzt genutzt: 07.04.2024',
        quantity: '150',
        unit: 'g',
        progress: 0.55,
        categoryIcon: Icons.local_fire_department,
      ),
      _PantryItemData(
        name: 'Paprika',
        detail: 'Läuft ab: 01.09.2024',
        quantity: '80',
        unit: 'g',
        progress: 0.40,
        categoryIcon: Icons.local_fire_department,
      ),
    ],
  ),
  _PantryCategory(
    title: 'Dosen & Konserven',
    icon: Icons.inventory_2,
    items: [
      _PantryItemData(
        name: 'Tomaten',
        detail: 'Läuft ab: 10.11.2024',
        quantity: '400',
        unit: 'g',
        progress: 0.90,
        categoryIcon: Icons.inventory_2,
      ),
      _PantryItemData(
        name: 'Kidneybohnen',
        detail: 'Läuft ab: 15.01.2025',
        quantity: '500',
        unit: 'g',
        progress: 0.85,
        categoryIcon: Icons.inventory_2,
      ),
    ],
  ),
  _PantryCategory(
    title: 'Getränke',
    icon: Icons.local_drink,
    items: [
      _PantryItemData(
        name: 'Orangensaft',
        detail: 'Läuft ab: 12.04.2024',
        quantity: '1',
        unit: 'L',
        progress: 0.20,
        categoryIcon: Icons.local_drink,
      ),
    ],
  ),
];

// ── Main Screen ───────────────────────────────────────────────────────

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.spacing4,
                  AppColors.spacing6,
                  AppColors.spacing4,
                  AppColors.spacing2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vorratskammer: Inventar',
                      style: textTheme.headlineLarge?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Behalte deinen Vorrat im Auge',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Alerts ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _QuickAlertsSection(alerts: _sampleAlerts),
            ),

            // ── Category Sections ─────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _sampleCategories[index];
                  return _CategorySection(category: category);
                },
                childCount: _sampleCategories.length,
              ),
            ),

            // ── Bottom spacing for Add Button ─────────────────────────
            const SliverToBoxAdapter(
              child: SizedBox(height: AppColors.spacing8),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppColors.spacing4,
            AppColors.spacing2,
            AppColors.spacing4,
            AppColors.spacing4,
          ),
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Artikel hinzufügen',
              icon: Icons.add,
              onPressed: () {
                // TODO: Navigate to add item screen / show dialog
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick Alerts Section ──────────────────────────────────────────────

class _QuickAlertsSection extends StatelessWidget {
  final List<_PantryAlert> alerts;

  const _QuickAlertsSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spacing4,
        vertical: AppColors.spacing2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < alerts.length; i++) ...[
            if (i > 0) const SizedBox(height: AppColors.spacing2),
            _AlertCard(alert: alerts[i]),
          ],
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _PantryAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLowStock = alert.alertType == 'low_stock';
    final statusColor =
        isLowStock ? AppColors.secondary : AppColors.error;
    final statusLabel = isLowStock ? 'LOW STOCK' : 'EXPIRING SOON';
    final statusIcon =
        isLowStock ? Icons.warning_amber_rounded : Icons.schedule;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacing4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppColors.radiusDefault),
        border: Border.all(
          color: statusColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(AppColors.radiusFull),
            ),
            child: Icon(
              statusIcon,
              size: 18,
              color: AppColors.onSecondary,
            ),
          ),
          const SizedBox(width: AppColors.spacing3),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.itemName,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.detail,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Dismiss icon
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: () {
              // TODO: Dismiss alert
            },
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Category Section ──────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final _PantryCategory category;

  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppColors.spacing6,
        left: AppColors.spacing4,
        right: AppColors.spacing4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Icon(
                category.icon,
                size: 22,
                color: cs.primary,
              ),
              const SizedBox(width: AppColors.spacing2),
              Text(
                category.title,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacing2),
          // Items
          ...category.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < category.items.length - 1
                    ? AppColors.spacing2
                    : 0,
              ),
              child: _PantryItemWidget(
                item: item,
                useAlternateBackground: index.isOdd,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Pantry Item Widget ────────────────────────────────────────────────

class _PantryItemWidget extends StatelessWidget {
  final _PantryItemData item;
  final bool useAlternateBackground;

  const _PantryItemWidget({
    required this.item,
    required this.useAlternateBackground,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final backgroundColor = useAlternateBackground
        ? AppColors.surfaceContainerLowest
        : AppColors.surfaceContainerHigh;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacing4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppColors.radiusDefault),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppColors.radiusFull),
            ),
            child: Icon(
              item.categoryIcon,
              size: 24,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: AppColors.spacing3),

          // Name + Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.detail!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                // Progress bar
                if (item.progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppColors.radiusFull),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusFull,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quantity
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.quantity,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                item.unit,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppColors.spacing2),

          // Actions
          Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () {
                  // TODO: Edit item
                },
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                onPressed: () {
                  // TODO: Delete item
                },
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
