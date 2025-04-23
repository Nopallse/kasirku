// lib/ui/screens/cashier/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'dart:developer' as developer;
import '../cashier/widgets/hold_order_dialog.dart';
import 'payment_confirmation_dialog.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final Function onPaymentComplete;
  final Function onCancel;
  final Function(String) onHold;

  const PaymentScreen({
    Key? key,
    required this.totalAmount,
    required this.onPaymentComplete,
    required this.onCancel,
    required this.onHold,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Metode pembayaran yang dipilih
  String _selectedPaymentMethod = 'cash';

  // Controller untuk input jumlah uang
  final TextEditingController _cashAmountController = TextEditingController();

  // Loading state
  bool _isProcessing = false;

  // Untuk menampilkan uang kembalian
  double _changeAmount = 0;
  bool _showChange = false;

  @override
  void initState() {
    super.initState();
    // Set default cash amount ke total amount
    _cashAmountController.text = widget.totalAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _cashAmountController.dispose();
    super.dispose();
  }

  // Format angka dengan pemisah ribuan
  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // Hitung kembalian
  void _calculateChange() {
    final cashAmount =
        double.tryParse(_cashAmountController.text.replaceAll('.', '')) ?? 0;
    if (cashAmount >= widget.totalAmount) {
      setState(() {
        _changeAmount = cashAmount - widget.totalAmount;
        _showChange = true;
      });
    } else {
      setState(() {
        _showChange = false;
      });
    }
  }

  // Proses pembayaran
  void _processPayment() async {
    // Validasi input
    if (_selectedPaymentMethod == 'cash') {
      final cashAmount =
          double.tryParse(_cashAmountController.text.replaceAll('.', '')) ?? 0;
      if (cashAmount < widget.totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah uang tidak mencukupi'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulasi proses pembayaran (delay 1 detik)
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Set payment method di provider
        final transactionProvider = Provider.of<TransactionProvider>(
          context,
          listen: false,
        );
        transactionProvider.setPaymentMethod(_selectedPaymentMethod);

        // Jika metode cash, set juga jumlah cash dan kembalian
        if (_selectedPaymentMethod == 'cash') {
          final cashAmount =
              double.tryParse(_cashAmountController.text.replaceAll('.', '')) ??
              0;
          transactionProvider.setCashAmount(cashAmount);
          transactionProvider.setChangeAmount(_changeAmount);
        }

        setState(() {
          _isProcessing = false;
        });

        // Tampilkan dialog konfirmasi pembayaran
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => PaymentConfirmationDialog(
                paymentMethod: _selectedPaymentMethod,
                total: widget.totalAmount,
                cashAmount:
                    _selectedPaymentMethod == 'cash'
                        ? (double.tryParse(
                              _cashAmountController.text.replaceAll('.', ''),
                            ) ??
                            0)
                        : null,
                changeAmount:
                    _selectedPaymentMethod == 'cash' ? _changeAmount : null,
                onConfirm: () {
                  Navigator.pop(context); // Tutup dialog
                  // Panggil callback onPaymentComplete
                  widget.onPaymentComplete();
                },
              ),
        );
      }
    } catch (e) {
      developer.log('Error processing payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Format input uang
  void _formatCashInput() {
    final text = _cashAmountController.text.replaceAll('.', '');
    if (text.isEmpty) return;

    final number = double.tryParse(text) ?? 0;
    final formattedText = _formatCurrency(number);

    _cashAmountController.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pembayaran',
        onMenuPressed: () => Navigator.pop(context),
        actions: [
          // Tombol Hold
          TextButton.icon(
            icon: const Icon(Icons.pause_circle_outline),
            label: const Text('Tahan'),
            onPressed: () {
              // Tampilkan dialog Hold Order
              showDialog(
                context: context,
                builder: (context) => HoldOrderDialog(
                  onSubmit: (name) {
                    widget.onHold(name);
                    Navigator.pop(context); // Tutup dialog
                    Navigator.pop(context); // Kembali ke halaman kasir
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total belanja
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Total Belanja',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${_formatCurrency(widget.totalAmount)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Metode pembayaran
              const Text(
                'Metode Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Cash payment method
              _buildPaymentMethodCard(
                method: 'cash',
                title: 'Tunai',
                icon: Icons.payments_outlined,
                child:
                    _selectedPaymentMethod == 'cash'
                        ? Column(
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Tombol nominal cepat
                                _buildQuickAmountButton(widget.totalAmount),
                                _buildQuickAmountButton(50000),
                                _buildQuickAmountButton(100000),
                                _buildQuickAmountButton(200000),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Input jumlah uang
                            TextField(
                              controller: _cashAmountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Jumlah Uang',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                _formatCashInput();
                                _calculateChange();
                              },
                            ),
                            // Kembalian
                            if (_showChange) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Kembalian:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${_formatCurrency(_changeAmount)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        )
                        : const SizedBox.shrink(),
              ),

              // Transfer payment method
              _buildPaymentMethodCard(
                method: 'transfer',
                title: 'Transfer Bank',
                icon: Icons.account_balance_outlined,
                child:
                    _selectedPaymentMethod == 'transfer'
                        ? _buildBankTransferOptions()
                        : const SizedBox.shrink(),
              ),

              // QRIS payment method
              _buildPaymentMethodCard(
                method: 'qris',
                title: 'QRIS',
                icon: Icons.qr_code,
                child:
                    _selectedPaymentMethod == 'qris'
                        ? _buildQrisPayment()
                        : const SizedBox.shrink(),
              ),

              // E-Wallet payment method
              _buildPaymentMethodCard(
                method: 'ewallet',
                title: 'E-Wallet',
                icon: Icons.account_balance_wallet_outlined,
                child:
                    _selectedPaymentMethod == 'ewallet'
                        ? _buildEWalletOptions()
                        : const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => widget.onCancel(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Confirm button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          _isProcessing
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('Bayar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk tombol nominal cepat
  Widget _buildQuickAmountButton(double amount) {
    final formattedAmount = _formatCurrency(amount);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            _cashAmountController.text = formattedAmount;
            _calculateChange();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(
            '${amount == widget.totalAmount ? "Uang Pas" : "Rp $formattedAmount"}',
          ),
        ),
      ),
    );
  }

  // Widget untuk metode pembayaran
  Widget _buildPaymentMethodCard({
    required String method,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Radio<String>(
                    value: method,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk opsi transfer bank
  Widget _buildBankTransferOptions() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // List bank
        _buildBankOption('BCA', 'assets/icons/bca.png'),
        _buildBankOption('Mandiri', 'assets/icons/mandiri.png'),
        _buildBankOption('BNI', 'assets/icons/bni.png'),
        _buildBankOption('BRI', 'assets/icons/bri.png'),
        // Notifikasi
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Simulasi pembayaran transfer bank. Pada aplikasi nyata, akan terintegrasi dengan payment gateway.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget untuk opsi bank
  Widget _buildBankOption(String bankName, String logoPath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.account_balance,
          ), // Placeholder, ganti dengan logo bank asli
        ),
        title: Text(bankName),
        trailing: Radio<String>(
          value: 'transfer_$bankName',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = 'transfer';
            });
          },
        ),
      ),
    );
  }

  // Widget untuk pembayaran QRIS
  Widget _buildQrisPayment() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // QR Code Placeholder
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2, size: 80, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              const Text(
                'Scan QR Code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'QR Code simulasi pembayaran',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        // Notifikasi
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Simulasi pembayaran QRIS. Pada aplikasi nyata, akan terintegrasi dengan QRIS generator.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget untuk opsi E-Wallet
  Widget _buildEWalletOptions() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // List E-Wallet
        _buildEWalletOption('GoPay', Icons.account_balance_wallet),
        _buildEWalletOption('OVO', Icons.account_balance_wallet),
        _buildEWalletOption('DANA', Icons.account_balance_wallet),
        _buildEWalletOption('ShopeePay', Icons.account_balance_wallet),
        // Notifikasi
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Simulasi pembayaran E-Wallet. Pada aplikasi nyata, akan terintegrasi dengan payment gateway.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget untuk opsi E-Wallet
  Widget _buildEWalletOption(String walletName, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(walletName),
        trailing: Radio<String>(
          value: 'ewallet_$walletName',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = 'ewallet';
            });
          },
        ),
      ),
    );
  }
}
