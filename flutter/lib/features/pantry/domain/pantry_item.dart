class PantryItem {
  final int id;
  final String name;
  final double? quantity;
  final String? unit;
  final String? category;
  final DateTime? expiryDate;
  final int? lowStockThreshold;

  const PantryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.category,
    this.expiryDate,
    this.lowStockThreshold,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'] as int,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      lowStockThreshold: json['low_stock_threshold'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
    };
  }
}

class PantryAlert {
  final int id;
  final String itemName;
  final String alertType; // low_stock, expiring
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
      alertType: json['alert_type'] as String? ?? 'low_stock',
      currentQuantity: (json['current_quantity'] as num?)?.toDouble(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      dismissed: json['dismissed'] as bool? ?? false,
    );
  }
}
