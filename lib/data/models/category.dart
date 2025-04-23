class Category {
  final int? id;
  final String name;
  final String? description;
  final int productCount;

  Category({
    this.id,
    required this.name,
    this.description,
    required this.productCount,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      productCount: map['product_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? description,
    int? productCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      productCount: productCount ?? this.productCount,
    );
  }

   @override
  String toString() {
    return 'Category{id: $id, name: $name, description: $description, productCount: $productCount}';
  }
}
