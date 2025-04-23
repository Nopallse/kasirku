// lib/data/models/transaction_item.dart
class TransactionItem {
  final int? id;
  final int? transactionId;
  final int? productId;
  final int quantity;
  final double price;
  String? productName; // Changed from late final to just nullable
  String? productImage;

  TransactionItem({
    this.id,
    this.transactionId,
    this.productId,
    required this.quantity,
    required this.price,
    this.productName,
    this.productImage,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      price: map['price'],
      productName: map['product_name'],
      productImage: map['product_image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
    };
  }

  double get total => price * quantity;

  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    int? quantity,
    double? price,
    String? productName,
    String? productImage,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
    );
  }

  @override
  String toString() {
    return 'TransactionItem{id: $id, transactionId: $transactionId, productId: $productId, quantity: $quantity, price: $price, productName: $productName}';
  }
}