// lib/data/models/product.dart
class Product {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final double? modalPrice; // Harga modal (buy price)
  final int stock;
  final int? categoryId;
  final String? categoryName; // For display purposes, not stored in DB
  final String? image;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.modalPrice,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.image,
  });

  // Create product from database map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'] is int
          ? (map['price'] as int).toDouble()
          : map['price'],
      modalPrice: map['modal_price'] != null
          ? (map['modal_price'] is int
          ? (map['modal_price'] as int).toDouble()
          : map['modal_price'])
          : null,
      stock: map['stock'],
      categoryId: map['category_id'],
      categoryName: map['category_name'],
      image: map['image'],
    );
  }

  // Convert product to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'modal_price': modalPrice,
      'stock': stock,
      'category_id': categoryId,
      'image': image,
    };
  }

  // Create copy of product with new values
  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    double? modalPrice,
    int? stock,
    int? categoryId,
    String? categoryName,
    String? image,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      modalPrice: modalPrice ?? this.modalPrice,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      image: image ?? this.image,
    );
  }

  // Format price as currency string
  String get formattedPrice {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    )}';
  }

  // Format modal price as currency string
  String get formattedModalPrice {
    if (modalPrice == null) return '-';
    return 'Rp ${modalPrice!.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    )}';
  }

  // Calculate profit
  double? get profit {
    if (modalPrice == null) return null;
    return price - modalPrice!;
  }

  // Format profit as currency string
  String get formattedProfit {
    if (profit == null) return '-';
    return 'Rp ${profit!.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    )}';
  }

  // Calculate profit margin as percentage
  double? get profitMargin {
    if (modalPrice == null || modalPrice == 0) return null;
    return ((price - modalPrice!) / modalPrice!) * 100;
  }

  // Format profit margin as percentage string
  String get formattedProfitMargin {
    if (profitMargin == null) return '-';
    return '${profitMargin!.toStringAsFixed(1)}%';
  }

  // Check if product is low on stock
  bool get isLowStock {
    return stock < 10;
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, price: $price, modalPrice: $modalPrice, stock: $stock, categoryId: $categoryId}';
  }
}