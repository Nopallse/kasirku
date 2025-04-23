// Updated transaction_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/product.dart';
import '../data/models/transaction.dart';
import '../data/models/transaction_item.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  // Menambahkan metode untuk konversi ke Map
  Map<String, dynamic> toMap() {
    return {
      'product': {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'stock': product.stock,
        'categoryId': product.categoryId,
        'image': product.image,
      },
      'quantity': quantity,
    };
  }

  // Menambahkan metode untuk membuat CartItem dari Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product(
        id: map['product']['id'],
        name: map['product']['name'],
        price: map['product']['price'],
        stock: map['product']['stock'],
        categoryId: map['product']['categoryId'],
        image: map['product']['image'],
      ),
      quantity: map['quantity'],
    );
  }
}

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final ProductRepository _productRepository = ProductRepository();

  List<CartItem> _cart = [];
  int? _selectedOutletId;
  bool _isProcessing = false;
  List<Transaction> _recentTransactions = [];
  double _taxRate = 0.1; // 10% tax rate by default
  String _errorMessage = '';
  List<Map<String, dynamic>> _heldTransactions = [];
  String _paymentMethod = 'cash'; // Default payment method
  double _cashAmount = 0.0; // Jumlah uang cash
  double _changeAmount = 0.0; // Jumlah kembalian

  // Getters
  List<CartItem> get cart => _cart;
  bool get isProcessing => _isProcessing;
  List<Transaction> get recentTransactions => _recentTransactions;
  int? get selectedOutletId => _selectedOutletId;
  double get taxRate => _taxRate;
  String get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get heldTransactions => _heldTransactions;
  String get paymentMethod => _paymentMethod;
  double get cashAmount => _cashAmount;
  double get changeAmount => _changeAmount;

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // Set cash amount (untuk payment cash)
  void setCashAmount(double amount) {
    _cashAmount = amount;
    notifyListeners();
  }

  // Set change amount (kembalian)
  void setChangeAmount(double amount) {
    _changeAmount = amount;
    notifyListeners();
  }

  // Cart getters
  int get itemCount => _cart.length;

  int get totalItems => _cart.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  double get total => subtotal;

  // Constructor untuk memuat transaksi yang ditahan saat aplikasi dimulai
  TransactionProvider() {
    _loadHeldTransactions();
  }

  // Set the outlet for this transaction
  void setOutlet(int outletId) {
    _selectedOutletId = outletId;
    notifyListeners();
  }

  // Set the tax rate
  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }

  // Add product to cart
  void addToCart(Product product) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Product already in cart, increase quantity if stock allows
      if (_cart[existingIndex].quantity < product.stock) {
        _cart[existingIndex].quantity++;
        notifyListeners();
      }
    } else {
      // Add new product to cart if stock > 0
      if (product.stock > 0) {
        _cart.add(CartItem(product: product));
        notifyListeners();
      }
    }
  }

  // Remove product from cart
  void removeFromCart(int productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      // Make sure we don't exceed available stock
      final availableStock = _cart[index].product.stock;
      if (quantity <= availableStock) {
        _cart[index].quantity = quantity;
        notifyListeners();
      }
    }
  }

  // Clear cart
  void clearCart() {
    _cart = [];
    notifyListeners();
  }

  // Process payment
  Future<bool> processPayment() async {
    if (_cart.isEmpty || _selectedOutletId == null) {
      return false;
    }

    _isProcessing = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Create transaction
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      final transaction = Transaction(
        date: dateStr,
        total: total,
        subtotal: subtotal,
        outletId: _selectedOutletId,
        paymentMethod: _paymentMethod,  // Tambahkan payment method
        cashAmount: _paymentMethod == 'cash' ? _cashAmount : null,  // Tambahkan cash amount
        changeAmount: _paymentMethod == 'cash' ? _changeAmount : null,  // Tambahkan change amount
      );

      // Create transaction items
      final items = _cart.map((cartItem) =>
          TransactionItem(
            productId: cartItem.product.id,
            quantity: cartItem.quantity,
            price: cartItem.product.price,
            productName: cartItem.product.name,
          )
      ).toList();

      // Save to database
      await _transactionRepository.insertTransaction(transaction, items);

      // Refresh recent transactions
      await loadRecentTransactions();

      // Clear cart
      clearCart();

      return true;
    } catch (e) {
      _errorMessage = 'Error processing payment: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Metode untuk menahan transaksi
  Future<bool> holdTransaction(String name) async {
    if (_cart.isEmpty || _selectedOutletId == null) {
      return false;
    }

    try {
      // Buat objek transaksi yang ditahan
      final now = DateTime.now();
      final holdTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final heldTransaction = {
        'name': name.isEmpty ? 'Order $holdTime' : name,
        'time': now.millisecondsSinceEpoch,
        'outletId': _selectedOutletId,
        'cart': _cart.map((item) => item.toMap()).toList(),
        'total': total,
      };

      // Tambahkan ke daftar transaksi yang ditahan
      _heldTransactions.add(heldTransaction);

      // Simpan ke SharedPreferences
      await _saveHeldTransactions();

      // Clear cart setelah ditahan
      clearCart();

      return true;
    } catch (e) {
      _errorMessage = 'Error holding transaction: $e';
      print(_errorMessage);
      return false;
    }
  }

  // Memuat transaksi ditahan dari penyimpanan lokal
  Future<void> _loadHeldTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? heldTransactionsJson = prefs.getString('heldTransactions');

      if (heldTransactionsJson != null) {
        final List<dynamic> decoded = jsonDecode(heldTransactionsJson);
        _heldTransactions = List<Map<String, dynamic>>.from(decoded);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error loading held transactions: $e';
      print(_errorMessage);
    }
  }

  // Menyimpan transaksi ditahan ke penyimpanan lokal
  Future<void> _saveHeldTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(_heldTransactions);
      await prefs.setString('heldTransactions', encodedData);
    } catch (e) {
      _errorMessage = 'Error saving held transactions: $e';
      print(_errorMessage);
    }
  }

  // Mengambil transaksi yang ditahan
  Future<bool> retrieveHeldTransaction(int index) async {
    if (index < 0 || index >= _heldTransactions.length) {
      return false;
    }

    try {
      // Jika cart tidak kosong, konfirmasi dulu dengan pengguna
      if (_cart.isNotEmpty) {
        clearCart();
      }

      // Ambil transaksi yang ditahan
      final heldTransaction = _heldTransactions[index];

      // Set outlet
      _selectedOutletId = heldTransaction['outletId'];

      // Restore cart items
      final List<dynamic> cartItems = heldTransaction['cart'];
      _cart =
          cartItems
              .map((item) => CartItem.fromMap(Map<String, dynamic>.from(item)))
              .toList();

      // Hapus transaksi dari daftar yang ditahan
      _heldTransactions.removeAt(index);
      await _saveHeldTransactions();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error retrieving held transaction: $e';
      print(_errorMessage);
      return false;
    }
  }

  // Menghapus transaksi yang ditahan
  Future<bool> removeHeldTransaction(int index) async {
    if (index < 0 || index >= _heldTransactions.length) {
      return false;
    }

    try {
      _heldTransactions.removeAt(index);
      await _saveHeldTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error removing held transaction: $e';
      print(_errorMessage);
      return false;
    }
  }

  // Load recent transactions
  Future<void> loadRecentTransactions([int limit = 5]) async {
    try {
      _recentTransactions = await _transactionRepository.getRecentTransactions(
        limit,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading recent transactions: $e';
      print(_errorMessage);
      _recentTransactions = []; // Set to empty list to avoid loading forever
      notifyListeners();
    }
  }

  // Get a specific transaction with items
  Future<Transaction?> getTransactionDetails(int transactionId) async {
    try {
      return await _transactionRepository.getTransactionWithItems(
        transactionId,
      );
    } catch (e) {
      _errorMessage = 'Error getting transaction details: $e';
      print(_errorMessage);
      return null;
    }
  }

  // Get daily sales statistics
  Future<Map<String, dynamic>> getDailySalesStats() async {
    try {
      return await _transactionRepository.getDailySalesStats();
    } catch (e) {
      _errorMessage = 'Error getting daily sales stats: $e';
      print(_errorMessage);
      return {'totalSales': 0.0, 'orderCount': 0, 'averageOrder': 0.0};
    }
  }

  // Get monthly sales statistics
  Future<Map<String, dynamic>> getMonthlySalesStats() async {
    try {
      return await _transactionRepository.getMonthlySalesStats();
    } catch (e) {
      _errorMessage = 'Error getting monthly sales stats: $e';
      print(_errorMessage);
      return {
        'totalSales': 0.0,
        'orderCount': 0,
        'averageOrder': 0.0,
        'growthPercentage': 0.0,
      };
    }
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopProducts([int limit = 5]) async {
    try {
      return await _transactionRepository.getTopProducts(limit);
    } catch (e) {
      _errorMessage = 'Error getting top products: $e';
      print(_errorMessage);
      return [];
    }
  }

  Future<List<Transaction>> getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? outletId,
    String? searchQuery,
  }) async {
    try {
      return await _transactionRepository.getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
        outletId: outletId,
        searchQuery: searchQuery,
      );
    } catch (e) {
      _errorMessage = 'Error getting filtered transactions: $e';
      print(_errorMessage);
      return [];
    }
  }
}
