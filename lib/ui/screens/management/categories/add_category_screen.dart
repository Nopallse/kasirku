// lib/ui/screens/management/categories/add_category_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/category_provider.dart';
import '../../../../data/models/category.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_text_field.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? categoryToEdit;
  final bool useCustomAppBar;

  const AddCategoryScreen({
    Key? key,
    this.categoryToEdit,
    this.useCustomAppBar = true,
  }) : super(key: key);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditing => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.categoryToEdit!.name;
      if (widget.categoryToEdit!.description != null) {
        _descriptionController.text = widget.categoryToEdit!.description!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.useCustomAppBar
          ? CustomAppBar(
        title: _isEditing ? 'Edit Category' : 'Add Category',
        showBackButton: true,
        actions: _isEditing
            ? [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteCategoryConfirmation(context),
            tooltip: 'Delete Category',
          ),
        ]
            : null,
      )
          : null,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category icon (modern design touch)
              if (!_isLoading) // Don't show during loading
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

              CustomTextField(
                controller: _nameController,
                labelText: 'Category Name',
                hintText: 'Enter category name',
                prefixIcon: const Icon(Icons.category),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description (Optional)',
                hintText: 'Enter category description',
                prefixIcon: const Icon(Icons.description),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  return null; // Optional field
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  _isEditing ? 'Update Category' : 'Save Category',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteCategoryConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${widget.categoryToEdit!.name}"? '
              'This will not delete the products in this category, but they will no longer be categorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteCategory(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
    });

    categoryProvider.deleteCategory(widget.categoryToEdit!.id!).then((success) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete category: ${categoryProvider.errorMessage}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    bool success;
    if (_isEditing) {
      // Update existing category
      final updatedCategory = Category(
        id: widget.categoryToEdit!.id,
        name: name,
        description: description.isNotEmpty ? description : null,
        productCount: widget.categoryToEdit!.productCount,
      );
      success = await categoryProvider.updateCategory(updatedCategory);
    } else {
      // Create new category
      final newCategory = Category(
        name: name,
        description: description.isNotEmpty ? description : null,
        productCount: 0,
      );
      success = await categoryProvider.addCategory(newCategory);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Category updated successfully'
              : 'Category added successfully'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${categoryProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}