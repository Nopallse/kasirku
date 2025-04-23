// lib/ui/screens/cashier/widgets/category_filter.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/category_provider.dart';
import '../../../../data/models/category.dart';

class CategoryFilter extends StatelessWidget {
  final Function(int?) onCategorySelected;

  const CategoryFilter({
    Key? key,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;
    final selectedCategoryId = categoryProvider.selectedCategoryId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DropdownButtonFormField<int?>(
        decoration: InputDecoration(
          labelText: 'Filter by Category',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        value: selectedCategoryId,
        onChanged: (value) {
          onCategorySelected(value);
        },
        items: [
          // "All Products" option
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('All Products'),
          ),
          // Category options
          ...categories.map((Category category) {
            return DropdownMenuItem<int?>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
        ],
      ),
    );
  }
}