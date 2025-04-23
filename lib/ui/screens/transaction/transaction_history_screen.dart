import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:grouped_list/grouped_list.dart';
import '../../../providers/transaction_provider.dart';
import '../../../data/models/transaction.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../../utils/currency_formatter.dart';

class TransactionHistoryScreen extends StatefulWidget {
  static const routeName = '/transaction/history';

  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = false;
  List<Transaction> _transactions = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Simplified filtering - just month and year
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Month names
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];

  // Years (from 2020 to current year)
  late final List<int> _years;

  // Summary statistics
  double _totalRevenue = 0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();

    // Initialize years list
    _years = List.generate(
      DateTime.now().year - 2020 + 1,
          (index) => 2020 + index,
    ).reversed.toList(); // Most recent first

    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      // Set date range for the selected month and year
      final startDate = DateTime(_selectedYear, _selectedMonth, 1);
      final endDate = (_selectedMonth < 12)
          ? DateTime(_selectedYear, _selectedMonth + 1, 0)
          : DateTime(_selectedYear + 1, 1, 0);

      // Fetch transactions with filters
      _transactions = await transactionProvider.getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate summary statistics
      _calculateStatistics();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transactions: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateStatistics() {
    _totalTransactions = _transactions.length;
    _totalRevenue = _transactions.fold(0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Transaction History',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      drawer: AppDrawer(
        currentIndex: 6, // Set appropriate index for Reports/Transactions
        onNavigate: (index) {
          // Handle navigation based on the index
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/cashier');
              break;
          // Add more cases for other sections
            default:
            // Default handling
              break;
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilterRow(context),
          _buildStatsSummary(context),
          Expanded(
            child: _transactions.isEmpty
                ? _buildEmptyState(context)
                : _buildGroupedTransactionsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Month dropdown
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMonth,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                      _loadTransactions();
                    }
                  },
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(_monthNames[index]),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Year dropdown
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedYear = newValue;
                      });
                      _loadTransactions();
                    }
                  },
                  items: _years.map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Transactions',
              _totalTransactions.toString(),
              Icons.receipt_long_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Revenue',
              CurrencyFormatter.formatCompact(_totalRevenue),
              Icons.payments,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different month or year',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // New method using GroupedListView
  // New method using GroupedListView with fixed sticky header
  Widget _buildGroupedTransactionsList(BuildContext context) {
    return GroupedListView<Transaction, String>(
      elements: _transactions,
      groupBy: (transaction) {
        final date = DateTime.parse(transaction.date);
        return DateFormat('yyyy-MM-dd').format(date); // Group by date
      },
      groupSeparatorBuilder: (String date) {
        final dateTime = DateTime.parse(date);
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor, // Background color for header
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMMM yyyy').format(dateTime),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Divider(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      itemBuilder: (context, Transaction transaction) {
        return _buildTransactionListItem(context, transaction);
      },
      itemComparator: (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)), // Sort by date descending
      order: GroupedListOrder.DESC,
      // Fix for headers overlapping issue
      useStickyGroupSeparators: true,
      floatingHeader: true,
      stickyHeaderBackgroundColor: Theme.of(context).scaffoldBackgroundColor, // Match background color
      padding: const EdgeInsets.only(top: 8, bottom: 8), // Add padding to top and bottom
      separator: const Divider(height: 0, color: Colors.transparent), // No visible separator between items
      // Add some space between groups
      groupComparator: (a, b) => b.compareTo(a), // Consistent with item sorting
    );
  }

  Widget _buildTransactionListItem(BuildContext context, Transaction transaction) {
    // Parse the date string from the transaction
    final DateTime transactionDate = DateTime.parse(transaction.date);

    // Format time for display
    final timeFormat = DateFormat('HH:mm');
    final formattedTime = timeFormat.format(transactionDate);

    // Format the transaction amount
    final formattedAmount = CurrencyFormatter.format(transaction.total);

    // Get outlet name
    final outletName = _getOutletName(transaction.outletId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to transaction details using the route
          Navigator.pushNamed(
            context,
            '/transaction/details',
            arguments: transaction.id,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice #${transaction.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formattedAmount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (outletName != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.store,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      outletName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
              if (transaction.items != null && transaction.items!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${transaction.items!.length} items',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _getOutletName(int? outletId) {
    if (outletId == null) return null;

    // This should ideally come from your outlet repository
    // For now we'll return a placeholder based on ID
    switch (outletId) {
      case 1:
        return 'Main Store';
      case 2:
        return 'Downtown';
      case 3:
        return 'Mall Branch';
      default:
        return 'Outlet #$outletId';
    }
  }
}