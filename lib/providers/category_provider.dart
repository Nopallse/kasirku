// Fixed category_provider.dart
import 'package:flutter/foundation.dart' as flutter;
import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

class CategoryProvider with flutter.ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  List<Category> _categories = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int? _selectedCategoryId;

  // Getters
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int? get selectedCategoryId => _selectedCategoryId;

  CategoryProvider() {
    // Don't call loadCategories in constructor - it will be called from UI
  }

  // Load all categories from the database
  Future<void> loadCategories() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _categories = await _repository.getAllCategories();
    } catch (e) {
      _errorMessage = 'Failed to load categories: ${e.toString()}';
      print(_errorMessage);
      // Important: still update the categories list to empty to avoid stuck loading
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new category
  Future<bool> addCategory(Category category) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final id = await _repository.insertCategory(category);

      // Add the category with its new ID to the list
      final newCategory = Category(
        id: id,
        name: category.name,
        description: category.description,
        productCount: 0,
      );

      _categories.add(newCategory);
      _categories.sort((a, b) => a.name.compareTo(b.name));

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add category: ${e.toString()}';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing category
  Future<bool> updateCategory(Category category) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _repository.updateCategory(category);

      // Update the category in the list
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        // Preserve the product count when updating
        _categories[index] = category.copyWith(
            productCount: _categories[index].productCount
        );
        _categories.sort((a, b) => a.name.compareTo(b.name));
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update category: ${e.toString()}';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a category
  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // This will update product category_id to null AND delete the category
      final success = await _repository.deleteCategory(id);

      if (success) {
        _categories.removeWhere((c) => c.id == id);
      }

      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the selected category
  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Get a category by ID
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get category count
  int get categoryCount => _categories.length;
}