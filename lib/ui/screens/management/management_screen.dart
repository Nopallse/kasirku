import 'package:flutter/material.dart';
import 'package:kasirku/ui/screens/management/products/edit_product_screen.dart';
import 'package:kasirku/ui/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/category_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'products/add_product_screen.dart';
import 'categories/add_category_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({Key? key}) : super(key: key);

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update FAB
    });

    // Load data on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Inventory Management',
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 1,
          tabs: const [
            Tab(
              text: 'Products',
            ),
            Tab(
              text: 'Categories',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ProductsTab(), CategoriesTab()],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              if (_tabController.index == 0) {
                _navigateToAddProduct(context);
              } else {
                _navigateToAddCategory(context);
              }
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
  }

  void _navigateToAddCategory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
    );
  }
}

class ProductsTab extends StatefulWidget {
  const ProductsTab({Key? key}) : super(key: key);

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize selected category from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      setState(() {
        // This ensures the UI reflects current filter state
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SearchTextField(
                  controller: _searchController,
                  hintText: 'Search products...',
                  onChanged: (query) {
                    productProvider.searchProducts(query);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: productProvider.selectedCategoryId != null
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  onPressed: () => _showFilterDialog(context),
                  tooltip: 'Filter by category',
                ),
              ),
            ],
          ),
        ),

        // Product list
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productProvider.errorMessage.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${productProvider.errorMessage}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => productProvider.loadProducts(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final products = productProvider.filteredProducts;

              if (products.isEmpty) {
                return _buildEmptyProductState(productProvider);
              }

              return RefreshIndicator(
                onRefresh: () => productProvider.loadProducts(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(context, product);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyProductState(ProductProvider productProvider) {
    // Check if empty due to filters or no products at all
    final hasProducts = productProvider.allProducts.isNotEmpty;
    final isFiltered =
        productProvider.searchQuery.isNotEmpty ||
            productProvider.selectedCategoryId != null;

    if (hasProducts && isFiltered) {
      // No products match the current filters
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_list, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No matching products found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different search terms or filters',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                productProvider.resetFilters();
              },
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    } else {
      // No products at all
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('No products found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Add your first product using the + button',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

// Ganti fungsi _buildProductCard dengan implementasi berikut

  Widget _buildProductCard(BuildContext context, product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToEditProduct(context, product.id!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: product.image != null && product.image!.isNotEmpty
                      ? FutureBuilder<File?>(
                    future: _getProductImageFile(product.image!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      if (snapshot.data != null) {
                        return Image.file(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        );
                      }

                      return Icon(
                        Icons.inventory_2,
                        size: 40,
                        color: Colors.grey[400],
                      );
                    },
                  )
                      : Icon(
                    Icons.inventory_2,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.categoryName != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.categoryName!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),
              // Stock status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color:
                  product.isLowStock
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                    product.isLowStock
                        ? Colors.red[300]!
                        : Colors.green[300]!,
                  ),
                ),
                child: Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    product.isLowStock
                        ? Colors.red[700]
                        : Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Tambahkan fungsi helper untuk mendapatkan file gambar produk
  Future<File?> _getProductImageFile(String filename) async {
    try {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/product_images/$filename';
      final file = File(filePath);

      if (await file.exists()) {
        return file;
      }

      // Coba cari di lokasi alternatif jika tidak ditemukan
      final externalDir = await path_provider.getExternalStorageDirectory();
      if (externalDir != null) {
        final altPath = '${externalDir.path}/product_images/$filename';
        final altFile = File(altPath);
        if (await altFile.exists()) {
          return altFile;
        }
      }

      return null;
    } catch (e) {
      print('Error saat mengakses file produk: $e');
      return null;
    }
  }
  void _showFilterDialog(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    // Use the provider's selectedCategoryId for the dialog's state
    int? selectedCategoryId = productProvider.selectedCategoryId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Products'),
            content: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                final categories = categoryProvider.categories;

                return SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Category:'),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListTile(
                                title: const Text('All Categories'),
                                leading: Radio<int?>(
                                  value: null,
                                  groupValue: selectedCategoryId,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedCategoryId = value;
                                    });
                                  },
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    selectedCategoryId = null;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                              ...categories.map((category) {
                                return ListTile(
                                  title: Text(category.name),
                                  subtitle: Text(
                                    '${category.productCount} products',
                                  ),
                                  leading: Radio<int?>(
                                    value: category.id,
                                    groupValue: selectedCategoryId,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedCategoryId = value;
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setDialogState(() {
                                      selectedCategoryId = category.id;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Update provider with selected category
                  productProvider.filterByCategory(selectedCategoryId);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToEditProduct(BuildContext context, int productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(productId: productId),
      ),
    );
  }


}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categoryProvider.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error: ${categoryProvider.errorMessage}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => categoryProvider.loadCategories(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final categories = categoryProvider.categories;

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No categories found',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your first category using the + button',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => categoryProvider.loadCategories(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(context, category);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToEditCategory(context, category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon with colored background
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category_outlined,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),

              // Category details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description != null &&
                        category.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          category.description!,
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),

                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.productCount} products',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Action button
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEditCategory(BuildContext context, category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(categoryToEdit: category),
      ),
    );
  }

  void _showDeleteCategoryConfirmation(BuildContext context, category) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
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
              _deleteCategory(context, category.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context, int categoryId) {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    categoryProvider.deleteCategory(categoryId).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
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
}