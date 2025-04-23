// lib/ui/screens/management/products/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import '../../../../providers/product_provider.dart';
import '../../../../providers/category_provider.dart';
import '../../../../data/models/product.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_text_field.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit;
  final bool useCustomAppBar;

  const AddProductScreen({
    Key? key,
    this.productToEdit,
    this.useCustomAppBar = true,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _modalPriceController = TextEditingController();
  final _stockController = TextEditingController();

  int? _selectedCategoryId;
  bool _isLoading = false;
  bool _categoriesLoaded = false;

  // Untuk image picker
  File? _imageFile;
  String? _existingImagePath;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();

    // Load categories if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();

      // Debug: Periksa apakah file gambar ada
      if (_existingImagePath != null) {
        _checkImageExists(_existingImagePath!);
      }
    });

    if (_isEditing) {
      _nameController.text = widget.productToEdit!.name;
      if (widget.productToEdit!.description != null) {
        _descriptionController.text = widget.productToEdit!.description!;
      }
      _priceController.text = widget.productToEdit!.price.toString();

      // Set modal price if available
      if (widget.productToEdit!.modalPrice != null) {
        _modalPriceController.text = widget.productToEdit!.modalPrice.toString();
      } else {
        _modalPriceController.text = "0";
      }

      _stockController.text = widget.productToEdit!.stock.toString();
      _selectedCategoryId = widget.productToEdit!.categoryId;

      // Set existing image path
      _existingImagePath = widget.productToEdit!.image;
      print('Existing image path: $_existingImagePath');
    }
  }

  Future<void> _checkImageExists(String filename) async {
    try {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/product_images/$filename';
      final file = File(filePath);

      print('Memeriksa file di: $filePath');
      print('File ada: ${await file.exists()}');

      // Jika file tidak ada di path yang diharapkan, coba cari di lokasi lain
      if (!(await file.exists())) {
        final externalDir = await path_provider.getExternalStorageDirectory();
        if (externalDir != null) {
          final altPath = '${externalDir.path}/product_images/$filename';
          final altFile = File(altPath);
          print('Mencoba path alternatif: $altPath');
          print('File ada: ${await altFile.exists()}');
        }
      }
    } catch (e) {
      print('Error memeriksa file: $e');
    }
  }

  Future<void> _loadCategories() async {
    if (!_categoriesLoaded) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.loadCategories();
      setState(() {
        _categoriesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _modalPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        print('Image picked: ${pickedFile.path}');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat mengakses gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _saveImage() async {
    if (_imageFile == null) return _existingImagePath;

    try {
      // Get application documents directory
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final productsDir = Directory('${appDir.path}/product_images');

      // Create directory if it doesn't exist
      if (!await productsDir.exists()) {
        await productsDir.create(recursive: true);
      }

      // Create unique filename with timestamp
      final filename = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = '${productsDir.path}/$filename';
      await _imageFile!.copy(savedImagePath);

      print('Gambar disimpan di: $savedImagePath');

      // Hanya kembalikan nama file, bukan path lengkap
      return filename;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Future<File?> _getImageFile(String filename) async {
    try {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/product_images/$filename';
      final file = File(filePath);

      if (await file.exists()) {
        print('File ditemukan: $filePath');
        return file;
      }

      // Coba cari di lokasi alternatif jika tidak ditemukan
      final externalDir = await path_provider.getExternalStorageDirectory();
      if (externalDir != null) {
        final altPath = '${externalDir.path}/product_images/$filename';
        final altFile = File(altPath);
        if (await altFile.exists()) {
          print('File ditemukan di lokasi alternatif: $altPath');
          return altFile;
        }
      }

      print('File tidak ditemukan: $filePath');
      return null;
    } catch (e) {
      print('Error mengakses file: $e');
      return null;
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imageFile != null || _existingImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove image', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _imageFile = null;
                    _existingImagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.useCustomAppBar
          ? CustomAppBar(
        title: _isEditing ? 'Edit Product' : 'Add Product',
        actions: _isEditing
            ? [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteProductConfirmation(context),
            tooltip: 'Delete Product',
          ),
        ]
            : null,
        showBackButton: true,
      )
          : null,
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          final categories = categoryProvider.categories;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product image picker
                  InkWell(
                    onTap: _showImageOptions,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                          : _existingImagePath != null
                          ? FutureBuilder<File?>(
                        future: _getImageFile(_existingImagePath!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                            );
                          }

                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Image not found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                          : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add Product Image',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Product Name
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Product Name',
                    hintText: 'Enter product name',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: 'Description (Optional)',
                    hintText: 'Enter product description',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      return null; // Optional field
                    },
                  ),
                  const SizedBox(height: 16),

                  // Modal Price
                  MoneyTextField(
                    controller: _modalPriceController,
                    labelText: 'Modal Price (Buy Price)',
                    hintText: '0',
                    currency: 'Rp',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter modal price';
                      }
                      final price = int.tryParse(value.replaceAll(',', ''));
                      if (price == null || price < 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selling Price
                  MoneyTextField(
                    controller: _priceController,
                    labelText: 'Selling Price',
                    hintText: '0',
                    currency: 'Rp',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter selling price';
                      }
                      final price = int.tryParse(value.replaceAll(',', ''));
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Stock
                  CustomTextField(
                    controller: _stockController,
                    labelText: 'Stock',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter stock';
                      }
                      final stock = int.tryParse(value);
                      if (stock == null || stock < 0) {
                        return 'Please enter valid stock';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<int?>(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    value: _selectedCategoryId,
                    hint: const Text('Select a category'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No Category'),
                      ),
                      ...categories.map((category) {
                        return DropdownMenuItem<int?>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  if (categoryProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        _isEditing ? 'Update Product' : 'Save Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteProductConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${widget.productToEdit!.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteProduct(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
    });

    productProvider.deleteProduct(widget.productToEdit!.id!).then((success) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete product: ${productProvider.errorMessage}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.replaceAll(',', ''));
      final modalPrice = double.parse(_modalPriceController.text.replaceAll(',', ''));
      final stock = int.parse(_stockController.text);

      // Save image and get the path
      final imagePath = await _saveImage();

      bool success;
      if (_isEditing) {
        // Update existing product
        final updatedProduct = Product(
          id: widget.productToEdit!.id,
          name: name,
          description: description.isNotEmpty ? description : null,
          price: price,
          modalPrice: modalPrice,
          stock: stock,
          categoryId: _selectedCategoryId,
          image: imagePath,
        );
        success = await productProvider.updateProduct(updatedProduct);
      } else {
        // Create new product
        final newProduct = Product(
          name: name,
          description: description.isNotEmpty ? description : null,
          price: price,
          modalPrice: modalPrice,
          stock: stock,
          categoryId: _selectedCategoryId,
          image: imagePath,
        );
        success = await productProvider.addProduct(newProduct);
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Product updated successfully'
                : 'Product added successfully'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${productProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Helper widget for currency input
class MoneyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String currency;
  final String? Function(String?)? validator;

  const MoneyTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.currency = 'Rp',
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: '$currency ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandsSeparatorInputFormatter(),
      ],
      validator: validator,
    );
  }
}

// Formatter for thousands separators (e.g., 1,000,000)
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ',';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Only process if the text has changed
    if (oldValue.text == newValue.text) {
      return newValue;
    }

    // Remove all separators
    final value = newValue.text.replaceAll(separator, '');

    // Format with separator
    final formatted = _formatWithSeparator(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithSeparator(String value) {
    final chars = value.split('');
    final buffer = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      // Add separator every 3 digits, but not at the beginning
      if ((chars.length - i) % 3 == 0 && i > 0) {
        buffer.write(separator);
      }
      buffer.write(chars[i]);
    }

    return buffer.toString();
  }
}