class OrderItem {
  final String id;
  final String name;
  final int price;
  final int quantity;

  const OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      quantity: json['quantity'] as int,
    );
  }
}

class OrderStatus {
  static const String newOrder = 'Новый';
  static const String accepted = 'Принят';
  static const String preparing = 'Готовится';
  static const String ready = 'Готов';
  static const String served = 'Выдан';
  static const String completed = 'Завершён';

  static const List<String> all = [
    newOrder,
    accepted,
    preparing,
    preparing,
    ready,
    served,
    completed,
  ];

  static String next(String current) {
    final index = all.indexOf(current);

    if (index == -1 || index >= all.length - 1) {
      return completed;
    }

    return all[index + 1];
  }
}

class Order {
  final String orderNumber;
  final String customerName;
  final String phone;
  final String comment;
  final int total;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  /// ID заведения, которому принадлежит заказ.
  final String? venueId;

  // Столик гостя.
  final int? floor;
  final String? tableId;
  final String? tableName;

  const Order({
    required this.orderNumber,
    required this.customerName,
    required this.phone,
    required this.comment,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
    this.venueId,
    this.floor,
    this.tableId,
    this.tableName,
  });

  Order copyWith({
    String? orderNumber,
    String? customerName,
    String? phone,
    String? comment,
    int? total,
    String? status,
    DateTime? createdAt,
    List<OrderItem>? items,
    String? venueId,
    int? floor,
    String? tableId,
    String? tableName,
  }) {
    return Order(
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      comment: comment ?? this.comment,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      venueId: venueId ?? this.venueId,
      floor: floor ?? this.floor,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderNumber': orderNumber,
      'customerName': customerName,
      'phone': phone,
      'comment': comment,
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),

      'venueId': venueId,

      'floor': floor,
      'tableId': tableId,
      'tableName': tableName,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderNumber: json['orderNumber'] as String,
      customerName: json['customerName'] as String,
      phone: json['phone'] as String,
      comment: json['comment'] as String,
      total: json['total'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List)
          .map(
            (item) => OrderItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),

      // Старые заказы могут не иметь venueId.
      venueId: json['venueId'] as String?,

      floor: json['floor'] as int?,
      tableId: json['tableId'] as String?,
      tableName: json['tableName'] as String?,
    );
  }
}
