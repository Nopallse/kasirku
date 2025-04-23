// Fixed product_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategoryId;
  String _errorMessage = '';

  // Getters
  List<Product> get allProducts => _products;
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  ProductProvider() {
    // Don't call loadProducts in constructor - it will be called from UI
  }

  // Load all products from the database
  Future<void> loadProducts() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _products = await _repository.getAllProducts();
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load products: ${e.toString()}';
      print(_errorMessage);
      // Set products to empty list to avoid stuck in loading
      _products = [];
      _filteredProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter products by category
  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter products based on current search query and selected category
  void _applyFilters() {
    if (_searchQuery.isEmpty && _selectedCategoryId == null) {
      _filteredProducts = List.from(_products);
      return;
    }

    _filteredProducts = _products.where((product) {
      // Filter by category if selected
      bool matchesCategory = _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;

      // Filter by search query if provided
      bool matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Add a new product
  Future<bool> addProduct(Product product) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final id = await _repository.insertProduct(product);

      // Add the product with its new ID to the list
      final newProduct = product.copyWith(id: id);
      _products.add(newProduct);
      _applyFilters();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add product: ${e.toString()}';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing product
  Future<bool> updateProduct(Product product) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _repository.updateProduct(product);

      // Update the product in the list
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        _applyFilters();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update product: ${e.toString()}';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a product
  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _repository.deleteProduct(id);

      // Remove the product from the list
      _products.removeWhere((p) => p.id == id);
      _applyFilters();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete product: ${e.toString()}';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update product stock
  Future<bool> updateStock(int id, int newStock) async {
    try {
      await _repository.updateProductStock(id, newStock);

      // Update the product stock in the list
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = _products[index].copyWith(stock: newStock);
        _applyFilters();
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update stock: ${e.toString()}';
      print(_errorMessage);
      return false;
    }
  }

  // Get a single product by ID
  Future<Product?> getProduct(int id) async {
    try {
      return await _repository.getProduct(id);
    } catch (e) {
      _errorMessage = 'Failed to get product: ${e.toString()}';
      print(_errorMessage);
      return null;
    }
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts(int threshold) async {
    try {
      return await _repository.getLowStockProducts(threshold);
    } catch (e) {
      _errorMessage = 'Failed to get low stock products: ${e.toString()}';
      print(_errorMessage);
      return [];
    }
  }

  // Reset filters
  void resetFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _filteredProducts = List.from(_products);
    notifyListeners();
  }
}