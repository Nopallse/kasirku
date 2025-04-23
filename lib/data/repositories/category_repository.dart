// lib/data/repositories/category_repository.dart
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../datasources/local/app_database.dart';

class CategoryRepository {
  final dbHelper = AppDatabase.instance;

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await dbHelper.database;
    
    // Get categories with product count
    final result = await db.rawQuery('''
      SELECT c.*, COUNT(p.id) as product_count
      FROM categories c
      LEFT JOIN products p ON c.id = p.category_id
      GROUP BY c.id
      ORDER BY c.name
    ''');
    
    return result.map((map) => Category.fromMap(map)).toList();
  }

  // Get a category by ID
  Future<Category> getCategory(int id) async {
    final db = await dbHelper.database;
    
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    } else {
      throw Exception('Category ID $id not found');
    }
  }

  // Insert a new category
  Future<int> insertCategory(Category category) async {
    final db = await dbHelper.database;
    
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing category
  Future<int> updateCategory(Category category) async {
    final db = await dbHelper.database;
    
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Delete a category
  Future<bool> deleteCategory(int id) async {
    final db = await dbHelper.database;

    // Use a transaction to ensure both operations (updating products and deleting category) are atomic
    return await db.transaction((txn) async {
      try {
        // First, update all products that belong to this category
        // Set their category_id to NULL
        await txn.update(
          'products',
          {'category_id': null},
          where: 'category_id = ?',
          whereArgs: [id],
        );

        // Then delete the category
        final deletedRows = await txn.delete(
          'categories',
          where: 'id = ?',
          whereArgs: [id],
        );

        return deletedRows > 0;
      } catch (e) {
        print('Error deleting category: $e');
        return false;
      }
    });
  }

  // Get category product count
  Future<int> getCategoryProductCount(int categoryId) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM products
      WHERE category_id = ?
    ''', [categoryId]);
    
    return Sqflite.firstIntValue(result) ?? 0;
  }
}