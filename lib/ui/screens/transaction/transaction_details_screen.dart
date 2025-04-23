import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/transaction_provider.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/transaction_item.dart';
import '../../widgets/custom_app_bar.dart';
import '../../../utils/currency_formatter.dart';

class TransactionDetailsScreen extends StatefulWidget {
  static const routeName = '/transaction/details';

  final int transactionId;

  const TransactionDetailsScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool _isLoading = true;
  // Initialize with a default transaction to avoid late initialization error
  Transaction? _transaction;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final loadedTransaction = await transactionProvider.getTransactionDetails(widget.transactionId);

      if (mounted) {
        setState(() {
          _transaction = loadedTransaction;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transaction: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transaction Details',
        showBackButton: true,
        onMenuPressed: () {
          // Go back to transaction history
          Navigator.pop(context);
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Implement print functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing receipt...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing receipt...')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
          ? const Center(child: Text('Transaction not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransactionHeader(context),
            const SizedBox(height: 24),
            _buildItemsList(context),
            const SizedBox(height: 24),
            _buildPaymentDetails(context),
            const SizedBox(height: 24),
            _buildTotalSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHeader(BuildContext context) {
    // Parse the date string from the transaction
    final DateTime transactionDate = DateTime.parse(_transaction!.date);

    // Format date and time for display
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('HH:mm:ss');
    final formattedDate = dateFormat.format(transactionDate);
    final formattedTime = timeFormat.format(transactionDate);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${_transaction!.id}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (_transaction!.outletId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.store, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Outlet: ${_getOutletName(_transaction!.outletId!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            // Tambahkan informasi metode pembayaran
            if (_transaction!.paymentMethod != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payment, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Payment: ${_formatPaymentMethod(_transaction!.paymentMethod!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPaymentMethod(String paymentMethod) {
    if (paymentMethod.startsWith('transfer_')) {
      final bankName = paymentMethod.substring(9);
      return 'Bank Transfer ($bankName)';
    } else if (paymentMethod.startsWith('ewallet_')) {
      final walletName = paymentMethod.substring(8);
      return 'E-Wallet ($walletName)';
    } else if (paymentMethod == 'qris') {
      return 'QRIS';
    } else {
      return 'Cash';
    }
  }

  String _getOutletName(int outletId) {
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

  Widget _buildItemsList(BuildContext context) {
    if (_transaction!.items == null || _transaction!.items!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No items in this transaction'),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Items (${_transaction!.items!.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transaction!.items!.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _transaction!.items![index];
              return _buildTransactionItemRow(context, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItemRow(BuildContext context, TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Unknown Product',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.format(item.price)} × ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.price * item.quantity),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Menambahkan bagian detail pembayaran
  Widget _buildPaymentDetails(BuildContext context) {
    // Jika tidak ada metode pembayaran, jangan tampilkan bagian ini
    if (_transaction!.paymentMethod == null) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow(
              'Method',
              _formatPaymentMethod(_transaction!.paymentMethod!),
              icon: Icons.payment,
            ),

            // Tampilkan informasi tambahan untuk pembayaran cash
            if (_transaction!.paymentMethod == 'cash' && _transaction!.cashAmount != null) ...[
              const SizedBox(height: 8),
              _buildPaymentRow(
                'Cash Amount',
                CurrencyFormatter.format(_transaction!.cashAmount!),
                icon: Icons.money,
              ),

              if (_transaction!.changeAmount != null && _transaction!.changeAmount! > 0) ...[
                const SizedBox(height: 8),
                _buildPaymentRow(
                  'Change',
                  CurrencyFormatter.format(_transaction!.changeAmount!),
                  icon: Icons.payments_outlined,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
        ],
        Text(
          '$label:',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSummary(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow(
              'Subtotal',
              CurrencyFormatter.format(_transaction!.subtotal),
            ),

            // Tampilkan total di bawah
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            _buildSummaryRow(
              'Total',
              CurrencyFormatter.format(_transaction!.total),
              isTotal: true,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final textStyle = isTotal
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    )
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(value, style: textStyle),
      ],
    );
  }
}