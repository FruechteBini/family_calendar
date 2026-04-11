class KnusprProduct {
  final String id;
  final String name;
  final String? imageUrl;
  final double? price;
  final String? unit;
  final String? category;
  final bool available;

  const KnusprProduct({
    required this.id,
    required this.name,
    this.imageUrl,
    this.price,
    this.unit,
    this.category,
    this.available = true,
  });

  factory KnusprProduct.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    double? p;
    if (rawPrice is num) {
      p = rawPrice.toDouble();
    }
    return KnusprProduct(
      id: (json['id'] ?? json['product_id']).toString(),
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      price: p,
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      available: json['available'] as bool? ?? true,
    );
  }
}

class KnusprDeliverySlot {
  final String id;
  final String? start;
  final String? end;
  final String? date;
  final String? timeRange;
  final bool available;
  final double? fee;

  const KnusprDeliverySlot({
    required this.id,
    this.start,
    this.end,
    this.date,
    this.timeRange,
    this.available = true,
    this.fee,
  });

  factory KnusprDeliverySlot.fromJson(Map<String, dynamic> json) {
    return KnusprDeliverySlot(
      id: (json['id'] ?? json['slot_id']).toString(),
      start: json['start'] as String?,
      end: json['end'] as String?,
      date: json['date'] as String?,
      timeRange: json['time_range'] as String?,
      available: json['available'] as bool? ?? true,
      fee: (json['fee'] as num?)?.toDouble(),
    );
  }

  String get displayLabel {
    if (timeRange != null && timeRange!.isNotEmpty) return timeRange!;
    if (date != null && start != null) return '$date $start';
    if (start != null && end != null) return '$start – $end';
    return id;
  }
}

class KnusprStatus {
  final bool available;
  final bool configured;
  final String? message;

  const KnusprStatus({
    required this.available,
    required this.configured,
    this.message,
  });

  factory KnusprStatus.fromJson(Map<String, dynamic> json) {
    return KnusprStatus(
      available: json['available'] as bool? ?? false,
      configured: json['configured'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

class KnusprCartLine {
  final String orderFieldId;
  final String productId;
  final String name;
  final int quantity;
  final double price;

  const KnusprCartLine({
    required this.orderFieldId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory KnusprCartLine.fromJson(Map<String, dynamic> json) {
    return KnusprCartLine(
      orderFieldId: json['order_field_id'] as String,
      productId: json['product_id'].toString(),
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class KnusprCartSnapshot {
  final List<KnusprCartLine> items;
  final double totalPrice;
  final int totalItems;
  final bool canMakeOrder;

  const KnusprCartSnapshot({
    this.items = const [],
    this.totalPrice = 0,
    this.totalItems = 0,
    this.canMakeOrder = false,
  });

  factory KnusprCartSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return KnusprCartSnapshot(
      items: raw
          .map((e) => KnusprCartLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      totalItems: json['total_items'] as int? ?? 0,
      canMakeOrder: json['can_make_order'] as bool? ?? false,
    );
  }
}

class KnusprSendResult {
  final bool success;
  final int totalAdded;
  final int totalFailed;
  final List<Map<String, dynamic>> added;
  final List<Map<String, dynamic>> failed;
  final String? error;

  const KnusprSendResult({
    required this.success,
    this.totalAdded = 0,
    this.totalFailed = 0,
    this.added = const [],
    this.failed = const [],
    this.error,
  });

  factory KnusprSendResult.fromJson(Map<String, dynamic> json) {
    return KnusprSendResult(
      success: json['success'] as bool? ?? false,
      totalAdded: json['total_added'] as int? ?? 0,
      totalFailed: json['total_failed'] as int? ?? 0,
      added: (json['added'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      failed: (json['failed'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      error: json['error'] as String?,
    );
  }
}

class PreviewMatch {
  final String productId;
  final String name;
  final double? price;
  final String? unit;
  final bool available;

  const PreviewMatch({
    required this.productId,
    required this.name,
    this.price,
    this.unit,
    this.available = true,
  });

  factory PreviewMatch.fromJson(Map<String, dynamic> json) {
    return PreviewMatch(
      productId: json['product_id'].toString(),
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      available: json['available'] as bool? ?? true,
    );
  }
}

class PreviewLine {
  final int shoppingItemId;
  final String itemName;
  final int quantity;
  final List<PreviewMatch> matches;

  const PreviewLine({
    required this.shoppingItemId,
    required this.itemName,
    required this.quantity,
    this.matches = const [],
  });

  factory PreviewLine.fromJson(Map<String, dynamic> json) {
    final m = (json['matches'] as List<dynamic>?)
            ?.map((e) => PreviewMatch.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PreviewLine(
      shoppingItemId: json['shopping_item_id'] as int,
      itemName: json['item_name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      matches: m,
    );
  }
}

class PreviewShoppingListPayload {
  final int shoppingListId;
  final List<PreviewLine> lines;

  const PreviewShoppingListPayload({
    required this.shoppingListId,
    this.lines = const [],
  });

  factory PreviewShoppingListPayload.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List<dynamic>?)
            ?.map((e) => PreviewLine.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PreviewShoppingListPayload(
      shoppingListId: json['shopping_list_id'] as int,
      lines: lines,
    );
  }
}

class KnusprMapping {
  final int id;
  final String itemName;
  final String knusprProductId;
  final String knusprProductName;
  final int useCount;

  const KnusprMapping({
    required this.id,
    required this.itemName,
    required this.knusprProductId,
    required this.knusprProductName,
    this.useCount = 0,
  });

  factory KnusprMapping.fromJson(Map<String, dynamic> json) {
    return KnusprMapping(
      id: json['id'] as int,
      itemName: json['item_name'] as String? ?? '',
      knusprProductId: json['knuspr_product_id'].toString(),
      knusprProductName: json['knuspr_product_name'] as String? ?? '',
      useCount: json['use_count'] as int? ?? 0,
    );
  }
}
