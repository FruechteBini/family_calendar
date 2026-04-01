class KnusprProduct {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  final String? unit;
  final String? category;
  final bool available;

  const KnusprProduct({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.unit,
    this.category,
    this.available = true,
  });

  factory KnusprProduct.fromJson(Map<String, dynamic> json) {
    return KnusprProduct(
      id: json['id'].toString(),
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      available: json['available'] as bool? ?? true,
    );
  }
}

class KnusprDeliverySlot {
  final String id;
  final DateTime start;
  final DateTime end;
  final bool available;
  final double? fee;

  const KnusprDeliverySlot({
    required this.id,
    required this.start,
    required this.end,
    this.available = true,
    this.fee,
  });

  factory KnusprDeliverySlot.fromJson(Map<String, dynamic> json) {
    return KnusprDeliverySlot(
      id: json['id'].toString(),
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      available: json['available'] as bool? ?? true,
      fee: (json['fee'] as num?)?.toDouble(),
    );
  }
}
