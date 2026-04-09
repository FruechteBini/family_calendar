class ShoppingList {
  final int id;
  final String? name;
  final List<ShoppingItem> items;

  const ShoppingList({required this.id, this.name, this.items = const []});

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as int,
      name: json['name'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get totalItems => items.length;
  int get checkedItems => items.where((i) => i.checked).length;
  double get progress => totalItems > 0 ? checkedItems / totalItems : 0;
}

class ShoppingItem {
  final int id;
  final String name;
  final String? amount;
  final String? unit;
  final bool checked;
  final bool isManual;
  final String? category;
  final int? sortOrder;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.amount,
    this.unit,
    this.checked = false,
    this.isManual = false,
    this.category,
    this.sortOrder,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: json['amount']?.toString(),
      unit: json['unit'] as String?,
      checked: json['checked'] as bool? ?? false,
      isManual: json['is_manual'] as bool? ?? false,
      category: json['category'] as String?,
      sortOrder: json['sort_order'] as int?,
    );
  }
}
