import 'package:flutter/material.dart';

// Dialog untuk nama transaksi yang ditahan
class HoldOrderDialog extends StatefulWidget {
  final Function(String) onSubmit;
  
  const HoldOrderDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<HoldOrderDialog> createState() => _HoldOrderDialogState();
}

class _HoldOrderDialogState extends State<HoldOrderDialog> {
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tahan Pesanan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Masukkan nama untuk pesanan ini:'),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Nama Pesanan (Opsional)',
              border: OutlineInputBorder(),
              filled: true,
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(_nameController.text.trim());
            Navigator.of(context).pop();
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}