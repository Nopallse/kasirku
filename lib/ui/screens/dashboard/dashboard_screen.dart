import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/category_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'widgets/sales_summary_card.dart';
import 'widgets/recent_transactions_list.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Stats to display
  num _todaySales = 0;
  int _todayOrders = 0;
  int _outletCount = 3; // Placeholder until you add outlet provider
  List<Map<String, dynamic>> _topProducts = [];
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadData();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = 'Good Morning';
      } else if (hour < 17) {
        _greeting = 'Good Afternoon';
      } else {
        _greeting = 'Good Evening';
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load transactions
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.loadRecentTransactions();

      // Load products
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadProducts();

      // Load categories
      await Provider.of<CategoryProvider>(context, listen: false).loadCategories();

      // Get daily sales stats
      final salesStats = await transactionProvider.getDailySalesStats();

      // Get top products
      _topProducts = await transactionProvider.getTopProducts(5);

      setState(() {
        // Convert to appropriate types or handle both int and double
        _todaySales = salesStats['totalSales'] ?? 0;
        _todayOrders = (salesStats['orderCount'] as num?)?.toInt() ?? 0;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');
    final currentDate = dateFormat.format(DateTime.now());

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'KasirKu Pro',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),

      ),
      drawer: AppDrawer(
        currentIndex: 0,
        onNavigate: (index) {
          // Handle navigation to different sections
          if (index == 1) {
            Navigator.pushNamed(context, '/cashier');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/management');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/reports');
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Stats summary
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today\'s Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildInfoTile(
                                  'Sales',
                                  'Rp ${(_todaySales / 1000).toStringAsFixed(0)}K',
                                  Icons.attach_money,
                                  Colors.green,
                                ),
                                _buildInfoTile(
                                  'Orders',
                                  '$_todayOrders',
                                  Icons.shopping_cart,
                                  Colors.blue,
                                ),
                                _buildInfoTile(
                                  'Products',
                                  '${productProvider.products.length}',
                                  Icons.inventory_2,
                                  Colors.orange,
                                ),
                                _buildInfoTile(
                                  'Categories',
                                  '${categoryProvider.categories.length}',
                                  Icons.category,
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Neraca',
                            Icons.balance,
                            Colors.blue,
                                () => Navigator.pushNamed(context, '/balance-sheet'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Buku Besar',
                            Icons.book,
                            Colors.green,
                                () => Navigator.pushNamed(context, '/general-ledger'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Laba Rugi',
                            Icons.trending_up,
                            Colors.orange,
                                () => Navigator.pushNamed(context, '/income-statement'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Performance Charts
              if (_topProducts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Selling Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTopProductsChart(),
                    ],
                  ),
                ),

              // Inventory Status
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInventoryStatusItem(
                              'Low Stock Items',
                              _getLowStockCount(productProvider.products),
                              Icons.warning_amber,
                              Colors.orange,
                            ),
                            const Divider(),
                            _buildInventoryStatusItem(
                              'Out of Stock Items',
                              _getOutOfStockCount(productProvider.products),
                              Icons.remove_shopping_cart,
                              Colors.red,
                            ),
                            const Divider(),
                            _buildInventoryStatusItem(
                              'Good Stock Items',
                              _getGoodStockCount(productProvider.products),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProductsChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final productName = product['name'] as String;
            final quantitySold = product['quantity_sold'] as int;

            // Calculate percentage for bar width
            final maxQuantity = _topProducts.map((p) => p['quantity_sold'] as int).reduce((a, b) => a > b ? a : b);
            final percentage = quantitySold / maxQuantity;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          productName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$quantitySold sold',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForIndex(index),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInventoryStatusItem(String title, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  int _getLowStockCount(List products) {
    return products.where((p) => p.stock > 0 && p.stock <= 5).length;
  }

  int _getOutOfStockCount(List products) {
    return products.where((p) => p.stock == 0).length;
  }

  int _getGoodStockCount(List products) {
    return products.where((p) => p.stock > 5).length;
  }
}