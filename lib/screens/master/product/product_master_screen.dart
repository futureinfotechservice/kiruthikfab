import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../indigator/main.dart';
import '../../../models/productmaster_model.dart';
import '../../../services/product_apiservice.dart';
import '../../navigation_provider.dart';

class ProductMasterScreen extends StatefulWidget {
  const ProductMasterScreen({super.key});

  @override
  State<ProductMasterScreen> createState() => _ProductMasterScreenState();
}

class _ProductMasterScreenState extends State<ProductMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductApiService _apiService = ProductApiService();
  final TextEditingController _productNameController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isListLoading = true;

  // Store the product being edited
  ProductMasterModel? _editingProduct;

  List<ProductMasterModel> _products = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isListLoading = true;
    });

    try {
      final products = await _apiService.fetchProducts(context);
      if (mounted) {
        setState(() {
          _products = products;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading products: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isListLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String result;

      if (_isEditMode && _editingProduct != null) {
        // Update existing product
        result = await _apiService.updateProduct(
          context: context,
          productId: _editingProduct!.id,
          productname: _productNameController.text,
        );
      } else {
        // Insert new product
        result = await _apiService.insertProduct(
          context: context,
          productname: _productNameController.text,
        );
      }

      if (result == "Success") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Product updated successfully!'
                    : 'Product created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reset form and reload list
        _cancelEdit();
        await _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(String productId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await _apiService.deleteProduct(context, productId);
      if (result == "Success" && mounted) {
        setState(() {
          _products.removeAt(index);
          // If we were editing this product, cancel edit mode
          if (_editingProduct?.id == productId) {
            _cancelEdit();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _editProduct(ProductMasterModel product) {
    setState(() {
      _isEditMode = true;
      _editingProduct = product;
      _productNameController.text = product.productname;
    });

    // Scroll to top to show the form
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _editingProduct = null;
      _productNameController.clear();
    });
  }

  List<ProductMasterModel> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((product) {
      return product.productname.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
    final navProvider = context.watch<NavigationProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            navProvider.updateIndex(
              selectedIndex: 1,
              reportSubIndex: 0,
              masterSubIndex: 0,
              entrySubIndex: 0,
            );
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('Product Master'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularWaveProgress(),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        _buildHeaderCard(),

                        const SizedBox(height: 24),

                        // Form Card
                        _buildFormCard(isWeb),

                        const SizedBox(height: 32),

                        // Product List Header
                        _buildListHeader(isWeb),

                        const SizedBox(height: 16),

                        // Product List
                        if (_isListLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularWaveProgress(),
                            ),
                          )
                        else if (_filteredProducts.isEmpty)
                          _buildEmptyState()
                        else
                          isWeb ? _buildWebTable() : _buildMobileList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? 'Edit Product' : 'Add New Product',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEditMode
                ? 'Updating: ${_editingProduct?.productname ?? ''}'
                : 'Create a new product record',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Product Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 50,

                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _productNameController,

                            // ✅ ENTER KEY SUPPORT
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              _submitForm();
                            },

                            decoration: InputDecoration(
                              hintText: 'Enter product name',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              border: InputBorder.none,
                            ),

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Product name is required';
                              }
                              if (value.length < 2) {
                                return 'Product name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        if (_isEditMode)
                          IconButton(
                            onPressed: _cancelEdit,
                            icon: Icon(Icons.close, color: Colors.grey),
                            tooltip: 'Cancel Edit',
                          ),
                      ],
                    ),
                  ),
                ),
                if (isWeb) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 300,
                              maxHeight: 50,
                              minHeight: 50,
                            ),
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isEditMode ? 'Update' : 'Create',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (_isEditMode) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _cancelEdit,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // ================= WEB BUTTONS =================

            // ================= MOBILE BUTTONS =================
            if (!isWeb) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isEditMode ? 'Update Product' : 'Create Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_isEditMode) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(bool isWeb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Product List',
          style: TextStyle(
            fontSize: isWeb ? 24 : 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        Container(
          width: 250,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching products found'
                  : 'No products yet',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: Text(
                    'S.No',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Product Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              final bool isEditing = _editingProduct?.id == product.id;

              return Container(
                decoration: BoxDecoration(
                  color: isEditing ? Colors.blue.shade50 : null,
                  border: index < _filteredProducts.length - 1
                      ? const Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        )
                      : null,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: isEditing
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isEditing ? Colors.blue : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        product.productname,
                        style: TextStyle(
                          fontWeight: isEditing
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isEditing ? Colors.blue : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Edit button
                          IconButton(
                            onPressed: isEditing
                                ? null
                                : () => _editProduct(product),
                            icon: Icon(
                              Icons.edit,
                              color: isEditing ? Colors.grey : Colors.blue,
                              size: 20,
                            ),
                            tooltip: 'Edit',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          IconButton(
                            onPressed: () => _deleteProduct(product.id, index),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'Delete',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final bool isEditing = _editingProduct?.id == product.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isEditing ? Colors.blue.shade50 : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: isEditing ? Colors.blue : Colors.blue.shade700,
              radius: 20,
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              product.productname,
              style: TextStyle(
                fontWeight: isEditing ? FontWeight.bold : FontWeight.w500,
                color: isEditing ? Colors.blue : Colors.black87,
                fontSize: 16,
              ),
            ),
            subtitle: isEditing
                ? const Text(
                    'Currently editing',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                IconButton(
                  onPressed: isEditing ? null : () => _editProduct(product),
                  icon: Icon(
                    Icons.edit,
                    color: isEditing ? Colors.grey : Colors.blue,
                    size: 22,
                  ),
                  tooltip: 'Edit',
                  splashRadius: 20,
                ),
                // Delete button
                IconButton(
                  onPressed: () => _deleteProduct(product.id, index),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                  tooltip: 'Delete',
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
