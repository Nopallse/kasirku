import 'package:flutter/material.dart';
import 'package:kasirku/ui/screens/cashier/widgets/hold_order_dialog.dart';
import 'package:kasirku/ui/screens/payment/payment_screen.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../../providers/transaction_provider.dart';
import '../../../../providers/outlet_provider.dart';
import './cart_item.dart';
import './payment_summary.dart';

class DraggableBottomCart extends StatefulWidget {
  const DraggableBottomCart({Key? key}) : super(key: key);

  @override
  State<DraggableBottomCart> createState() => _DraggableBottomCartState();
}

class _DraggableBottomCartState extends State<DraggableBottomCart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  double _minHeight = 72.0;
  double _maxHeight = 0.0; // Will be calculated based on screen height
  bool _isExpanded = false;
  double _dragStart = 0.0;
  double _currentHeight = 72.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightFactor = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Get max height based on screen size when widget is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMaxHeight();
    });
  }

  void _updateMaxHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    // Use 70% of the screen height instead of 90%
    // Also account for safe area to prevent overflow
    setState(() {
      _maxHeight = (screenHeight * 0.7) - safeAreaBottom;
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        _currentHeight = _maxHeight;
      } else {
        _controller.reverse();
        _currentHeight = _minHeight;
      }
    });
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStart = details.localPosition.dy;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dragDistance = _dragStart - details.localPosition.dy;
    final newHeight = (_currentHeight + dragDistance).clamp(
      _minHeight,
      _maxHeight,
    );

    setState(() {
      _currentHeight = newHeight;
      _isExpanded =
          _currentHeight >
          _minHeight + 50; // Consider expanded if pulled up more than 50px

      // Update animation controller based on drag progress
      final animationValue =
          (_currentHeight - _minHeight) / (_maxHeight - _minHeight);
      _controller.value = animationValue.clamp(0.0, 1.0);
    });

    _dragStart = details.localPosition.dy;
  }

  void _handleDragEnd(DragEndDetails details) {
    // If velocity is significant, snap to min or max
    if (details.primaryVelocity != null) {
      // Negative velocity means dragging upward
      if (details.primaryVelocity! < -500) {
        _snapToMax();
      }
      // Positive velocity means dragging downward
      else if (details.primaryVelocity! > 500) {
        _snapToMin();
      }
      // Otherwise snap based on current position
      else {
        final threshold = _minHeight + (_maxHeight - _minHeight) * 0.3;
        if (_currentHeight > threshold) {
          _snapToMax();
        } else {
          _snapToMin();
        }
      }
    } else {
      // No velocity data, snap based on position
      final threshold = _minHeight + (_maxHeight - _minHeight) * 0.3;
      if (_currentHeight > threshold) {
        _snapToMax();
      } else {
        _snapToMin();
      }
    }
  }

  void _snapToMax() {
    setState(() {
      _isExpanded = true;
      _currentHeight = _maxHeight;
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 200));
    });
  }

  void _snapToMin() {
    setState(() {
      _isExpanded = false;
      _currentHeight = _minHeight;
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 200));
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    // Add safe area bottom padding to prevent overflow
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: !_isExpanded, // Only apply SafeArea when minimized
      child: GestureDetector(
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        onTap: _isExpanded ? null : _toggleExpanded,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 100,
          ), // Quick feedback for direct dragging
          height: _currentHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(_isExpanded ? 16 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Cart summary bar (always visible)
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${transactionProvider.totalItems} items',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rp ${transactionProvider.total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded cart content (visible when expanded)
              Expanded(
                child: AnimatedOpacity(
                  opacity: _isExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_isExpanded,
                    child: _buildCartContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        final outletProvider = Provider.of<OutletProvider>(context);

        return Column(
          children: [
            // Divider
            const Divider(height: 1),

            // Outlet selector
            if (outletProvider.outlets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Outlet:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
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
                          items:
                              outletProvider.outlets.map((outlet) {
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

            // Cart items
            Expanded(
              child:
                  transactionProvider.cart.isEmpty
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
                          ],
                        ),
                      )
                      : ListView.builder(
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
                              transactionProvider.removeFromCart(
                                cartItem.product.id!,
                              );
                            },
                          );
                        },
                      ),
            ),

            // Payment summary - modified to remove tax display
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
              // Modified PaymentSummary call
              child: SimplifiedPaymentSummary(
                totalAmount: transactionProvider.total,
                onClear: () {
                  transactionProvider.clearCart();
                  // Collapse the cart after clearing
                  _snapToMin();
                },
                onProcessPayment: () {
                  // Navigate to payment screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PaymentScreen(
                            totalAmount: transactionProvider.total,
                            onPaymentComplete: () async {
                              final success =
                                  await transactionProvider.processPayment();
                              if (success) {
                                if (mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Go back to cashier screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pembayaran berhasil'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  // Collapse the cart after successful payment
                                  _snapToMin();
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Gagal memproses pembayaran',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            onCancel: () {
                              Navigator.pop(
                                context,
                              ); // Go back to cashier screen
                            },
                            onHold: (name) async {
                              if (transactionProvider.cart.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Keranjang kosong, tidak ada yang bisa ditahan',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final success = await transactionProvider
                                  .holdTransaction(name);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pesanan berhasil ditahan'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                // Collapse the cart after holding
                                _snapToMin();
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
                isProcessing: transactionProvider.isProcessing,
                onHold: (name) async {
                  if (transactionProvider.cart.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Keranjang kosong, tidak ada yang bisa ditahan',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final success = await transactionProvider.holdTransaction(
                    name,
                  );
                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pesanan berhasil ditahan'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      // Collapse the cart after holding
                      _snapToMin();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal menahan pesanan'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            // Add padding at the bottom to ensure nothing is cut off
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Simplified payment summary without tax display
class SimplifiedPaymentSummary extends StatelessWidget {
  final double totalAmount;
  final VoidCallback onClear;
  final VoidCallback onProcessPayment;
  final Function(String) onHold;
  final bool isProcessing;

  const SimplifiedPaymentSummary({
    Key? key,
    required this.totalAmount,
    required this.onClear,
    required this.onProcessPayment,
    required this.onHold,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Total row
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              // Clear button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: OutlinedButton(
                    onPressed: onClear,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ),

              // Hold button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: OutlinedButton(
                    onPressed: () => _showHoldDialog(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Text('Hold'),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Process payment button (sekarang membuka halaman pembayaran)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isProcessing ? null : onProcessPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child:
                  isProcessing
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Lanjut ke Pembayaran'),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog untuk hold order
  void _showHoldDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HoldOrderDialog(onSubmit: onHold),
    );
  }
}
