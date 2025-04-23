import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../datasources/local/app_database.dart';

class TransactionRepository {
  final dbHelper = AppDatabase.instance;

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    final db = await dbHelper.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  // Get recent transactions
  Future<List<Transaction>> getRecentTransactions(int limit) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  // Get filtered transactions - NEW METHOD
  Future<List<Transaction>> getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? outletId,
    String? searchQuery,
  }) async {
    final db = await dbHelper.database;
    
    // Build query conditionally
    String query = 'SELECT * FROM transactions WHERE 1=1';
    List<dynamic> args = [];
    
    // Add date filters
    if (startDate != null) {
      final startDateStr = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      query += ' AND date >= ?';
      args.add('$startDateStr 00:00:00');
    }
    
    if (endDate != null) {
      final endDateStr = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      query += ' AND date <= ?';
      args.add('$endDateStr 23:59:59');
    }
    
    // Add outlet filter
    if (outletId != null) {
      query += ' AND outlet_id = ?';
      args.add(outletId);
    }
    
    // Add search
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // For a simple implementation, we can search transaction ID
      // In a real app, you might want to join with transaction_items and products tables
      query += ' AND id LIKE ?';
      args.add('%$searchQuery%');
    }
    
    // Add sorting
    query += ' ORDER BY date DESC';
    
    final result = await db.rawQuery(query, args);
    
    // Convert to transactions
    final transactions = result.map((map) => Transaction.fromMap(map)).toList();
    
    // If we have transactions, fetch items for each
    if (transactions.isNotEmpty) {
      for (var i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        if (transaction.id != null) {
          final itemsResult = await db.query(
            'transaction_items',
            where: 'transaction_id = ?',
            whereArgs: [transaction.id],
          );
          
          final items = itemsResult.map((map) => TransactionItem.fromMap(map)).toList();
          
          // Update transaction with items
          transactions[i] = Transaction(
            id: transaction.id,
            date: transaction.date,
            total: transaction.total,
            subtotal: transaction.subtotal,
            outletId: transaction.outletId,
            items: items,
          );
        }
      }
    }
    
    return transactions;
  }

  // Get transaction with items
  // Perbaikan untuk metode getTransactionWithItems

// Get transaction with items
  Future<Transaction> getTransactionWithItems(int id) async {
    final db = await dbHelper.database;

    // Get transaction
    final transResult = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (transResult.isEmpty) {
      throw Exception('Transaction with ID $id not found');
    }

    final transactionMap = transResult.first;
    final transaction = Transaction.fromMap(transactionMap);

    // Get transaction items
    final itemsResult = await db.rawQuery('''
    SELECT ti.*, p.name as product_name 
    FROM transaction_items ti
    LEFT JOIN products p ON ti.product_id = p.id
    WHERE ti.transaction_id = ?
  ''', [id]);

    final items = itemsResult.map((map) => TransactionItem.fromMap(map)..productName = map['product_name'] as String?).toList();

    // Return transaction with items
    return Transaction(
      id: transaction.id,
      date: transaction.date,
      total: transaction.total,
      subtotal: transaction.subtotal,
      outletId: transaction.outletId,
      paymentMethod: transactionMap['payment_method'] as String?,
      cashAmount: transactionMap['cash_amount'] != null ? (transactionMap['cash_amount'] as num).toDouble() : null,
      changeAmount: transactionMap['change_amount'] != null ? (transactionMap['change_amount'] as num).toDouble() : null,
      items: items,
    );
  }

  // Insert transaction with items
  Future<int> insertTransaction(Transaction transaction, List<TransactionItem> items) async {
    final db = await dbHelper.database;
    
    return await db.transaction((txn) async {
      // Insert transaction
      final transactionMap = transaction.toMap();
      
      // Pastikan field baru ada di map untuk insert
      transactionMap['payment_method'] = transaction.paymentMethod;
      if (transaction.cashAmount != null) {
        transactionMap['cash_amount'] = transaction.cashAmount;
      }
      if (transaction.changeAmount != null) {
        transactionMap['change_amount'] = transaction.changeAmount;
      }
      
      final transactionId = await txn.insert('transactions', transactionMap);
      
      // Insert items
      for (var item in items) {
        await txn.insert('transaction_items', {
          'transaction_id': transactionId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.price,
        });
        
        // Update product stock
        if (item.productId != null) {
          final productResult = await txn.query(
            'products',
            columns: ['stock'],
            where: 'id = ?',
            whereArgs: [item.productId],
          );
          
          if (productResult.isNotEmpty) {
            final currentStock = productResult.first['stock'] as int;
            final newStock = currentStock - item.quantity;
            
            await txn.update(
              'products',
              {'stock': newStock > 0 ? newStock : 0},
              where: 'id = ?',
              whereArgs: [item.productId],
            );
          }
        }
      }
      
      return transactionId;
    });
  }

  // Get daily sales statistics
  Future<Map<String, dynamic>> getDailySalesStats() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(total), 0) as total_sales, 
        COUNT(*) as order_count,
        COALESCE(AVG(total), 0) as average_order
      FROM transactions
      WHERE date LIKE '$today%'
    ''');
    
    return {
      'totalSales': result.first['total_sales'] ?? 0.0,
      'orderCount': result.first['order_count'] ?? 0,
      'averageOrder': result.first['average_order'] ?? 0.0,
    };
  }

  // Get monthly sales statistics
  Future<Map<String, dynamic>> getMonthlySalesStats() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(total), 0) as total_sales, 
        COUNT(*) as order_count,
        COALESCE(AVG(total), 0) as average_order
      FROM transactions
      WHERE date LIKE '$month-%'
    ''');
    
    // Get previous month for comparison
    final prevMonth = now.month == 1
        ? "${now.year - 1}-12"
        : "${now.year}-${(now.month - 1).toString().padLeft(2, '0')}";
        
    final prevResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(total), 0) as total_sales
      FROM transactions
      WHERE date LIKE '$prevMonth-%'
    ''');
    
    final currentMonthSales = result.first['total_sales'] as double? ?? 0.0;
    final prevMonthSales = prevResult.first['total_sales'] as double? ?? 0.0;
    
    // Calculate growth percentage
    double growthPercentage = 0;
    if (prevMonthSales > 0) {
      growthPercentage = ((currentMonthSales - prevMonthSales) / prevMonthSales) * 100;
    }
    
    return {
      'totalSales': currentMonthSales,
      'orderCount': result.first['order_count'] ?? 0,
      'averageOrder': result.first['average_order'] ?? 0.0,
      'growthPercentage': growthPercentage,
    };
  }

  // Get top products
  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT p.id, p.name, SUM(ti.quantity) as quantity_sold
      FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      GROUP BY p.id
      ORDER BY quantity_sold DESC
      LIMIT ?
    ''', [limit]);
    
    return result;
  }
} 