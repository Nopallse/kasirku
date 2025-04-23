import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  static bool _isInitializing = false;
  static Completer<Database>? _dbCompleter;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (_isInitializing) {
      // If already initializing, return the same future
      return _dbCompleter!.future;
    }

    _isInitializing = true;
    _dbCompleter = Completer<Database>();

    try {
      _database = await _initDB('kasirku_pro.db');
      _dbCompleter!.complete(_database);
    } catch (e) {
      _dbCompleter!.completeError(e);
      rethrow;
    } finally {
      _isInitializing = false;
    }

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Naikan versi database
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // Tambahkan fungsi onUpgrade
    );
  }

  // Fungsi untuk upgrade database
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Untuk upgrade dari versi 2 ke 3
    if (oldVersion < 3) {
      // Tambahkan kolom payment_method, cash_amount, dan change_amount ke tabel transactions
      await db.execute('ALTER TABLE transactions ADD COLUMN payment_method TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN cash_amount REAL');
      await db.execute('ALTER TABLE transactions ADD COLUMN change_amount REAL');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL'; // For boolean (0 or 1)

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        description TEXT
      )
    ''');

    // Products table
    await db.execute('''
  CREATE TABLE products (
    id $idType,
    name $textType,
    description TEXT,
    price $realType,
    modal_price $realType,
    stock $integerType,
    category_id INTEGER,
    image TEXT,
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
  )
''');

    // Outlets table
    await db.execute('''
      CREATE TABLE outlets (
        id $idType,
        name $textType,
        address $textType,
        phone TEXT
      )
    ''');

    // Employees table
    await db.execute('''
      CREATE TABLE employees (
        id $idType,
        name $textType,
        role $textType,
        outlet_id INTEGER,
        email TEXT,
        phone TEXT,
        FOREIGN KEY (outlet_id) REFERENCES outlets (id) ON DELETE SET NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        date $textType,
        total $realType,
        subtotal $realType,
        outlet_id INTEGER,
        payment_method TEXT,
        cash_amount REAL,
        change_amount REAL,
        FOREIGN KEY (outlet_id) REFERENCES outlets (id) ON DELETE SET NULL
      )
    ''');

    // Transaction items table
    await db.execute('''
      CREATE TABLE transaction_items (
        id $idType,
        transaction_id INTEGER,
        product_id INTEGER,
        quantity $integerType,
        price $realType,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
      )
    ''');

    // Insert some initial data
    await _insertInitialData(db);
  }

  Future _insertInitialData(Database db) async {
    // Instead of creating a FinancialRepository here, directly insert financial accounts

    // Insert outlet
    final mainStoreId = await db.insert('outlets', {
      'name': 'Main Store',
      'address': '123 Main Street',
      'phone': '555-1234'
    });

    // Insert categories
    final categories = [
      {'name': 'Electronics', 'description': 'Gadgets and electronics'},
      {'name': 'Clothing', 'description': 'Clothes and accessories'},
      {'name': 'Books', 'description': 'Books and magazines'},
    ];
    for (final category in categories) {
      await db.insert('categories', category);
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}