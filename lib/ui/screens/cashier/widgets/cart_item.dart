// lib/ui/screens/cashier/widgets/cart_item.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../../../../data/models/product.dart';

class CartItemWidget extends StatefulWidget {
  final Product product;
  final int quantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemWidget({
    Key? key,
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.quantity.toString());
  }

  @override
  void didUpdateWidget(CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text controller when quantity changes from outside
    if (oldWidget.quantity != widget.quantity) {
      _textController.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('cart-item-${widget.product.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        widget.onRemove();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: widget.product.image != null && widget.product.image!.isNotEmpty
                      ? FutureBuilder<File?>(
                    future: _getProductImageFile(widget.product.image!),
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
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 24,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        );
                      }

                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_outlined,
                          size: 24,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_outlined,
                      size: 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      widget.product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Price
                    Text(
                      'Rp ${widget.product.price.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Quantity and total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity selector
                        Row(
                          children: [
                            // Decrease button
                            GestureDetector(
                              onTap: () {
                                if (widget.quantity > 1) {
                                  widget.onQuantityChanged(widget.quantity - 1);
                                } else {
                                  widget.onRemove();
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            // Quantity display
                            Container(
                              width: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: TextField(
                                controller: _textController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  final newQuantity = int.tryParse(value);
                                  if (newQuantity != null && newQuantity > 0) {
                                    widget.onQuantityChanged(newQuantity);
                                  }
                                },
                                onSubmitted: (value) {
                                  final newQuantity = int.tryParse(value);
                                  if (newQuantity != null && newQuantity > 0) {
                                    widget.onQuantityChanged(newQuantity);
                                  } else {
                                    // Reset to valid value
                                    _textController.text = widget.quantity.toString();
                                  }
                                },
                              ),
                            ),
                            // Increase button
                            GestureDetector(
                              onTap: () {
                                if (widget.quantity < widget.product.stock) {
                                  widget.onQuantityChanged(widget.quantity + 1);
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Item total
                        Text(
                          'Rp ${(widget.product.price * widget.quantity).toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                onPressed: widget.onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
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