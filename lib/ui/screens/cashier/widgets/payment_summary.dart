// lib/ui/screens/cashier/widgets/payment_summary.dart
import 'package:flutter/material.dart';

class PaymentSummary extends StatelessWidget {
  final double subtotal;
  final double total;
  final VoidCallback onClear;
  final VoidCallback onProcessPayment;
  final bool isProcessing;
  final VoidCallback? onHold;

  const PaymentSummary({
    Key? key,
    required this.subtotal,
    required this.total,
    required this.onClear,
    required this.onProcessPayment,
    this.isProcessing = false,
    this.onHold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItems = subtotal > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // Summary rows
          _buildSummaryRow(
            context,
            'Subtotal',
            'Rp ${subtotal.toStringAsFixed(0)}',
            isTotal: false,
          ),



          const SizedBox(height: 8),

          _buildSummaryRow(
            context,
            'Total',
            'Rp ${total.toStringAsFixed(0)}',
            isTotal: true,
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Clear button
              Expanded(
                child: OutlinedButton(
                  onPressed: hasItems ? onClear : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: hasItems
                          ? theme.colorScheme.error
                          : theme.disabledColor,
                      width: 1,
                    ),
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.clear, size: 16, color: hasItems ? theme.colorScheme.error : theme.disabledColor),
                      const SizedBox(width: 4),
                      const Text('Clear'),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Hold button
              Expanded(
                child: OutlinedButton(
                  onPressed: hasItems ? (onHold ?? () {
                    // Default Hold action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order placed on hold'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }) : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: hasItems
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pause_circle_outline,
                           size: 16,
                           color: hasItems ? theme.colorScheme.primary : theme.disabledColor),
                      const SizedBox(width: 4),
                      const Text('Hold'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Process payment button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasItems && !isProcessing ? onProcessPayment : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: theme.disabledColor.withOpacity(0.2),
                disabledForegroundColor: theme.disabledColor,
              ),
              child: isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Processing...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 18),
                        const SizedBox(width: 8),
                        const Text('Process Payment'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    required bool isTotal,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
          ),
          Text(
            value,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
          ),
        ],
      ),
    );
  }
}