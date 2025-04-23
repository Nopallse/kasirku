import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/transaction.dart';
import '../../../../utils/currency_formatter.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(int) onViewTransaction;
  final bool showEmptyMessage;

  const RecentTransactionsList({
    Key? key,
    required this.transactions,
    required this.onViewTransaction,
    this.showEmptyMessage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return showEmptyMessage
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your recent transactions will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionCard(
          transaction: transaction,
          onViewTransaction: () => onViewTransaction(transaction.id!),
        );
      },
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onViewTransaction;

  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.onViewTransaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse the date string from the transaction
    final DateTime transactionDate = DateTime.parse(transaction.date);
    
    // Format date and time for display
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');
    final formattedDate = dateFormat.format(transactionDate);
    final formattedTime = timeFormat.format(transactionDate);

    // Format the transaction amount
    final formattedAmount = CurrencyFormatter.format(transaction.total);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onViewTransaction,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${transaction.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedDate, $formattedTime',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedAmount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (transaction.items != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.items!.length} items',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Transaction summary widget for reports
class TransactionSummary extends StatelessWidget {
  final String period;
  final int transactionCount;
  final double totalAmount;
  final double averageAmount;

  const TransactionSummary({
    Key? key,
    required this.period,
    required this.transactionCount,
    required this.totalAmount,
    required this.averageAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Transactions',
                    transactionCount.toString(),
                    Icons.receipt_outlined,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Total',
                    CurrencyFormatter.format(totalAmount),
                    Icons.payments_outlined,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Average',
                    CurrencyFormatter.format(averageAmount),
                    Icons.trending_up_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
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
}