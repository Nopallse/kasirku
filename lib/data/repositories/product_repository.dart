// lib/data/repositories/product_repository.dart
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';
import '../datasources/local/app_database.dart';

class ProductRepository {
  final dbHelper = AppDatabase.instance;

  // Get all products with category names
  Future<List<Product>> getAllProducts() async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      ORDER BY p.name
    ''');
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.category_id = ?
      ORDER BY p.name
    ''', [categoryId]);
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.name LIKE ?
      ORDER BY p.name
    ''', ['%$query%']);
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Get a product by ID
  Future<Product> getProduct(int id) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ?
    ''', [id]);

    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    } else {
      throw Exception('Product ID $id not found');
    }
  }

  // Insert a new product
  Future<int> insertProduct(Product product) async {
    final db = await dbHelper.database;
    
    return await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing product
  Future<int> updateProduct(Product product) async {
    final db = await dbHelper.database;
    
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Update product stock
  Future<int> updateProductStock(int id, int newStock) async {
    final db = await dbHelper.database;
    
    return await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a product
  Future<int> deleteProduct(int id) async {
    final db = await dbHelper.database;
    
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get product count
  Future<int> getProductCount() async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts(int threshold) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.stock <= ?
      ORDER BY p.stock
    ''', [threshold]);
    
    return result.map((map) => Product.fromMap(map)).toList();
  }
}