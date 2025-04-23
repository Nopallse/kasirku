// lib/data/repositories/outlet_repository.dart
import 'package:sqflite/sqflite.dart';

import '../models/outlet.dart';
import '../datasources/local/app_database.dart';

class OutletRepository {
  final dbHelper = AppDatabase.instance;

  Future<List<Outlet>> getAllOutlets() async {
    final db = await dbHelper.database;
    final result = await db.query('outlets');
    
    return result.map((map) => Outlet.fromMap(map)).toList();
  }

  Future<Outlet> getOutlet(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'outlets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return Outlet.fromMap(result.first);
    } else {
      throw Exception('Outlet with ID $id not found');
    }
  }

  Future<int> insertOutlet(Outlet outlet) async {
    final db = await dbHelper.database;
    return await db.insert('outlets', outlet.toMap());
  }

  Future<int> updateOutlet(Outlet outlet) async {
    final db = await dbHelper.database;
    return await db.update(
      'outlets',
      outlet.toMap(),
      where: 'id = ?',
      whereArgs: [outlet.id],
    );
  }

  Future<int> deleteOutlet(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'outlets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getOutletCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM outlets');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>> getOutletWithEmployeeCount(int id) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT o.*, COUNT(e.id) as employee_count
      FROM outlets o
      LEFT JOIN employees e ON o.id = e.outlet_id
      WHERE o.id = ?
      GROUP BY o.id
    ''', [id]);
    
    if (result.isNotEmpty) {
      return result.first;
    } else {
      throw Exception('Outlet with ID $id not found');
    }
  }
}