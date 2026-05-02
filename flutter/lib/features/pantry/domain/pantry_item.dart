class PantryItem {
  final int id;
  final String name;
  /// Mirrors API `amount`.
  final double? quantity;
  final String? unit;
  final String? category;
  final DateTime? expiryDate;
  final double? minStock;
  final bool isLowStock;
  final bool isExpiringSoon;
  final DateTime? updatedAt;

  const PantryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.category,
    this.expiryDate,
    this.minStock,
    this.isLowStock = false,
    this.isExpiringSoon = false,
    this.updatedAt,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    final qty = json['quantity'] as num?;
    final amt = json['amount'] as num?;
    DateTime? updated;
    final rawUp = json['updated_at'];
    if (rawUp is String && rawUp.isNotEmpty) {
      updated = DateTime.tryParse(rawUp);
    }
    return PantryItem(
      id: json['id'] as int,
      name: json['name'] as String,
      quantity: qty?.toDouble() ?? amt?.toDouble(),
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      minStock: (json['min_stock'] as num?)?.toDouble() ??
          ((json['low_stock_threshold'] as num?)?.toDouble()),
      isLowStock: json['is_low_stock'] as bool? ?? false,
      isExpiringSoon: json['is_expiring_soon'] as bool? ?? false,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (quantity != null) 'amount': quantity,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
      if (minStock != null) 'min_stock': minStock,
    };
  }
}

class PantryAlert {
  final int id;
  final String itemName;
  final String alertType; // low_stock, expiring_soon
  final double? currentQuantity;
  final DateTime? expiryDate;
  final bool dismissed;

  const PantryAlert({
    required this.id,
    required this.itemName,
    required this.alertType,
    this.currentQuantity,
    this.expiryDate,
    this.dismissed = false,
  });

  factory PantryAlert.fromJson(Map<String, dynamic> json) {
    return PantryAlert(
      id: json['id'] as int,
      itemName: json['item_name'] as String? ?? json['name'] as String? ?? '',
      alertType: (json['alert_type'] as String? ??
              json['reason'] as String? ??
              'low_stock')
          .trim(),
      currentQuantity: (json['current_quantity'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      dismissed: json['dismissed'] as bool? ?? false,
    );
  }
}

String pantryCategoryLabelDe(String? code) {
  switch (code) {
    case 'kuehlregal':
      return 'Kühlregal';
    case 'obst_gemuese':
      return 'Obst & Gemüse';
    case 'trockenware':
      return 'Trockenware';
    case 'drogerie':
      return 'Drogerie';
    case 'sonstiges':
      return 'Sonstiges';
    default:
      return code?.replaceAll('_', ' ') ?? 'Sonstiges';
  }
}
