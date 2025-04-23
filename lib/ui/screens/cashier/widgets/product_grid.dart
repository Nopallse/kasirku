// lib/ui/screens/cashier/widgets/product_grid.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../../../../providers/product_provider.dart';
import '../../../../providers/category_provider.dart';
import '../../../../data/models/product.dart';

class ProductGrid extends StatelessWidget {
  final Function(Product) onProductTap;

  const ProductGrid({
    Key? key,
    required this.onProductTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.filteredProducts;
    final isLoading = productProvider.isLoading;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductListItem(context, product);
      },
    );
  }

  Widget _buildProductListItem(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final isOutOfStock = product.stock <= 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: isOutOfStock ? null : () => onProductTap(product),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Product image (smaller)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: product.image != null && product.image!.isNotEmpty
                      ? FutureBuilder<File?>(
                    future: _getProductImageFile(product.image!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot.data != null) {
                        return Image.file(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 24,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        );
                      }

                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_outlined,
                          size: 24,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_outlined,
                      size: 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    Row(
                      children: [
                        // Category badge
                        if (product.categoryId != null)
                          Consumer<CategoryProvider>(
                            builder: (context, categoryProvider, _) {
                              final category = categoryProvider.getCategoryById(product.categoryId!);
                              final categoryName = category?.name ?? 'Unknown';

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  categoryName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(width: 4),

                        // Stock info
                        Text(
                          'Stock: ${product.stock}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOutOfStock ? Colors.red : Colors.green,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Price
              Text(
                'Rp ${product.price.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOutOfStock
                      ? theme.disabledColor
                      : theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 8),

              // Add button
              if (!isOutOfStock)
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: () => onProductTap(product),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'OUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi helper untuk mendapatkan file gambar produk
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
      print('Error getting product image file: $e');
      return null;
    }
  }
}