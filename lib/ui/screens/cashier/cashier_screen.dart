// lib/ui/screens/cashier/cashier_screen.dart
import 'package:flutter/material.dart';
import 'package:kasirku/data/models/product.dart';
import 'package:kasirku/ui/screens/cashier/held_orders_screen.dart';
import 'package:kasirku/ui/screens/payment/payment_screen.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../providers/product_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/outlet_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/product_grid.dart';
import 'widgets/category_filter.dart';
import 'widgets/cart_item.dart';
import 'widgets/payment_summary.dart';
import 'widgets/draggable_bottom_cart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;


class CashierScreen extends StatefulWidget {
  const CashierScreen({Key? key}) : super(key: key);

  @override
  _CashierScreenState createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialized = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initData();
      _isInitialized = true;
    }
  }

  Future<void> _initData() async {
    developer.log('Initializing CashierScreen data');
    // Load products and categories
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.loadProducts();

    // Set default outlet if not already set
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final outletProvider = Provider.of<OutletProvider>(context, listen: false);
    await outletProvider.loadOutlets();

    if (transactionProvider.selectedOutletId == null && outletProvider.outlets.isNotEmpty) {
      transactionProvider.setOutlet(outletProvider.outlets.first.id!);
      developer.log('Default outlet set to: ${outletProvider.outlets.first.id}');
    }
  }



  @override
  Widget build(BuildContext context) {
    developer.log('Building CashierScreen');
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Cashier',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Pesanan yang ditahan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HeldOrdersScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              developer.log('Search button pressed');
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(
                  onProductSelected: (product) {
                    developer.log('Product selected from search: ${product.id} - ${product.name}');
                    transactionProvider.addToCart(product);
                  },
                ),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        currentIndex: 1, // Cashier tab index
        onNavigate: (index) {
          // Handle navigation in your main app
          developer.log('Navigation requested to index: $index');
        },
      ),
      body: Column(
        children: [
          // Category dropdown at the top
          CategoryFilter(
            onCategorySelected: (categoryId) {
              developer.log('Category selected: $categoryId');
              productProvider.filterByCategory(categoryId);
            },
          ),

          Expanded(
            child: Row(
              children: [
                // Product list (left side)
                Expanded(
                  flex: 2,
                  child: ProductGrid(
                    onProductTap: (product) {
                      developer.log('Product tapped: ${product.id} - ${product.name}');
                      transactionProvider.addToCart(product);
                    },
                  ),
                ),

                // Cart (right side) - Only for wide screens
                if (isWideScreen)
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: buildCartSection(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // Use our new draggable bottom cart for small screens
      bottomNavigationBar: !isWideScreen ? const DraggableBottomCart() : null,
    );
  }


  Widget buildCartSection([ScrollController? scrollController]) {
  return Consumer<TransactionProvider>(
    builder: (context, transactionProvider, _) {
      final outletProvider = Provider.of<OutletProvider>(context);
      // Get the bottom padding to account for safe area
      final bottomPadding = MediaQuery.of(context).padding.bottom;

      return Column(
        children: [
          // Cart header with outlet selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Order',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (outletProvider.outlets.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: transactionProvider.selectedOutletId,
                        hint: const Text('Select outlet'),
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        onChanged: (outletId) {
                          if (outletId != null) {
                            transactionProvider.setOutlet(outletId);
                          }
                        },
                        items: outletProvider.outlets.map((outlet) {
                          return DropdownMenuItem<int>(
                            value: outlet.id,
                            child: Text(
                              outlet.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider for visual separation
          const Divider(height: 1),

          // Cart items
          Expanded(
            child: transactionProvider.cart.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cart is empty',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products from the list',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Improved empty cart instruction
                  if (MediaQuery.of(context).size.width < 800)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              Icons.touch_app,
                              size: 16,
                              color: Colors.grey.shade700
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap on products to add to cart',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
                : ListView.builder(
              controller: scrollController,
              // Add padding to the list to prevent overflow
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: transactionProvider.cart.length,
              itemBuilder: (context, index) {
                final cartItem = transactionProvider.cart[index];
                return CartItemWidget(
                  product: cartItem.product,
                  quantity: cartItem.quantity,
                  onQuantityChanged: (quantity) {
                    transactionProvider.updateQuantity(
                      cartItem.product.id!,
                      quantity,
                    );
                  },
                  onRemove: () {
                    transactionProvider.removeFromCart(cartItem.product.id!);
                  },
                );
              },
            ),
          ),

          // Payment summary without Tax
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            // Padding to ensure enough space at bottom
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                return SimplifiedPaymentSummary(
                  totalAmount: provider.total,
                  onClear: () {
                    provider.clearCart();
                  },
                  onProcessPayment: () {
                    // Navigasi ke halaman pembayaran
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          totalAmount: provider.total,
                          onPaymentComplete: () async {
                            final success = await provider.processPayment();
                            if (success) {
                              Navigator.pop(context); // Kembali ke cashier screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pembayaran berhasil'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal memproses pembayaran'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          onCancel: () {
                            Navigator.pop(context); // Kembali ke cashier screen
                          },
                          onHold: (name) async {
                            if (provider.cart.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Keranjang kosong, tidak ada yang bisa ditahan'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            final success = await provider.holdTransaction(name);
                            Navigator.pop(context); // Kembali ke cashier screen
                            
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pesanan berhasil ditahan'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal menahan pesanan'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                  isProcessing: provider.isProcessing,
                  onHold: (name) async {
                    if (provider.cart.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Keranjang kosong, tidak ada yang bisa ditahan'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final success = await provider.holdTransaction(name);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pesanan berhasil ditahan'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal menahan pesanan'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    },
  );
}


  @override
  void dispose() {
    developer.log('Disposing CashierScreen');
    _searchController.dispose();
    super.dispose();
  }
}

// Search delegate for product search
class ProductSearchDelegate extends SearchDelegate<String> {
  final Function(Product) onProductSelected;

  ProductSearchDelegate({required this.onProductSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          developer.log('Search query cleared');
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        developer.log('Search closed');
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    developer.log('Building search results for query: $query');
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    developer.log('Building search suggestions for query: $query');
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.searchProducts(query);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final results = provider.filteredProducts;
        developer.log('Search returned ${results.length} products');

        if (results.isEmpty) {
          return const Center(
            child: Text('No products found'),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final product = results[index];
            return ListTile(
              leading: SizedBox(
                width: 40,
                height: 40,
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
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          );
                        },
                      );
                    }

                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_outlined, color: Colors.grey),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
              title: Text(product.name),
              subtitle: Text('Rp ${product.price.toStringAsFixed(0)}'),
              trailing: product.stock > 0
                  ? IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  developer.log('Product added from search: ${product.name}');
                  onProductSelected(product);
                  close(context, '');
                },
              )
                  : const Text(
                'Out of stock',
                style: TextStyle(color: Colors.red),
              ),
              onTap: product.stock > 0
                  ? () {
                developer.log('Product tapped in search: ${product.name}');
                onProductSelected(product);
                close(context, '');
              }
                  : null,
            );
          },
        );
      },
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