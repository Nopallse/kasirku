// lib/ui/screens/cashier/held_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class HeldOrdersScreen extends StatelessWidget {
  const HeldOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pesanan Ditahan',
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final heldOrders = provider.heldTransactions;
          
          if (heldOrders.isEmpty) {
            return Center(
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
                    'Belum ada pesanan yang ditahan',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: heldOrders.length,
            itemBuilder: (context, index) {
              final order = heldOrders[index];
              final DateTime orderTime = DateTime.fromMillisecondsSinceEpoch(order['time']);
              final String timeString = DateFormat('HH:mm - d MMM y').format(orderTime);
              final List<dynamic> cartItems = order['cart'];
              final int itemCount = cartItems.length;
              final double total = order['total'];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showOrderOptions(context, provider, index),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeString,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$itemCount ${itemCount > 1 ? 'items' : 'item'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${total.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  void _showOrderOptions(BuildContext context, TransactionProvider provider, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Ambil Pesanan'),
            onTap: () async {
              Navigator.pop(context); // Close bottom sheet
              
              // Konfirmasi jika keranjang belanja sekarang tidak kosong
              if (provider.cart.isNotEmpty) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Keranjang Tidak Kosong'),
                    content: const Text(
                      'Keranjang belanja Anda saat ini tidak kosong. '
                      'Mengambil pesanan ini akan menghapus semua item yang ada di keranjang. '
                      'Apakah Anda yakin ingin melanjutkan?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Ya, Lanjutkan'),
                      ),
                    ],
                  ),
                ) ?? false;
                
                if (!confirm) return;
              }
              
              final success = await provider.retrieveHeldTransaction(index);
              
              if (success) {
                // Kembali ke halaman kasir
                Navigator.pop(context); 
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesanan berhasil diambil'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal mengambil pesanan'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red[700]),
            title: const Text('Hapus Pesanan'),
            textColor: Colors.red[700],
            onTap: () async {
              // Tutup bottom sheet
              Navigator.pop(context);
              
              // Konfirmasi penghapusan
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Pesanan'),
                  content: const Text('Apakah Anda yakin ingin menghapus pesanan ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              ) ?? false;
              
              if (confirm) {
                final success = await provider.removeHeldTransaction(index);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pesanan berhasil dihapus'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menghapus pesanan'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              top: 8,
            ),
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ),
        ],
      ),
    );
  }
}