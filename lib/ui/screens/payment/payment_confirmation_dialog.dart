// lib/ui/screens/cashier/payment_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentConfirmationDialog extends StatelessWidget {
  final String paymentMethod;
  final double total;
  final double? cashAmount;
  final double? changeAmount;
  final VoidCallback onConfirm;
  
  const PaymentConfirmationDialog({
    Key? key,
    required this.paymentMethod,
    required this.total,
    this.cashAmount,
    this.changeAmount,
    required this.onConfirm,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _getPaymentMethodName() {
    if (paymentMethod.startsWith('transfer_')) {
      return 'Transfer Bank ${paymentMethod.substring(9)}';
    } else if (paymentMethod.startsWith('ewallet_')) {
      return 'E-Wallet ${paymentMethod.substring(8)}';
    } else if (paymentMethod == 'qris') {
      return 'QRIS';
    } else {
      return 'Tunai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy HH:mm:ss');
    
    return AlertDialog(
      title: const Text('Konfirmasi Pembayaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Waktu: ${dateFormat.format(now)}'),
          const SizedBox(height: 16),
          
          const Text(
            'Rincian Pembayaran:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Metode Pembayaran:'),
              Text(
                _getPaymentMethodName(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:'),
              Text(
                'Rp ${_formatCurrency(total)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          // Tampilkan detail cash jika metode pembayaran cash
          if (paymentMethod == 'cash' && cashAmount != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jumlah Uang:'),
                Text(
                  'Rp ${_formatCurrency(cashAmount!)}',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian:'),
                Text(
                  'Rp ${_formatCurrency(changeAmount ?? 0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
          
          Center(
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Pembayaran Berhasil',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}