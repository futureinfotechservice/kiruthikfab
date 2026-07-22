import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/indigator/main.dart';
import 'package:kiruthikfab/models/relation_master_model.dart';
import 'package:kiruthikfab/services/config.dart'; // import '../../services/customer_apiservice.dart';
import 'package:kiruthikfab/services/kyc_apiservice.dart';
import 'package:kiruthikfab/services/relation_api_service.dart';
import 'package:kiruthikfab/widgets/custom_search_dropdown_source.dart';
import 'package:kiruthikfab/widgets/customdropdownwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../master/inventory/inventory_master.dart';

typedef ProductMap = Map<String, dynamic>;
typedef MemberMap = Map<String, dynamic>;

class KYCEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? kycData;

  const KYCEntryScreen({super.key, this.kycData});

  @override
  State<KYCEntryScreen> createState() => _KYCEntryScreenState();
}

class _KYCEntryScreenState extends State<KYCEntryScreen> {
  final KYCApiService _kycService = KYCApiService();
  final RelationApiService _relService = RelationApiService();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isDropdownDataLoaded = false;

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _genders = [];
  List<RelationMasterModel> _relations = [];
  List<Map<String, dynamic>> _sizes = [];
  List<Map<String, dynamic>> _occupations = [];

  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String _totalAmount = '0.00';

  List<Map<String, dynamic>> _familyMembersWithProducts = [];
  List<InventoryItem> inventoryItems = [];
  String? _selectedInventoryId;

  List<InventoryItem> filteredInventoryItems = [];
  final Map<String, List<InventoryItem>> _cachedInventoryByProduct = {};

  // bool _isInventoryLoaded = false;

  Future<void> fetchInventoryItems() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyid') ?? '';

      if (companyId.isEmpty) {
        return;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/inventory_fetch_all.php'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'companyid': companyId},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            if (mounted) {
              setState(() {
                inventoryItems = data
                    .map((item) => InventoryItem.fromJson(item))
                    .toList();
                filteredInventoryItems = List.from(inventoryItems);
                // _isInventoryLoaded = true;
                // Build the cache after setting inventory items
                _buildInventoryCache();
              });
            }
          }
        } catch (e) {
          return;
        }
      }
    } catch (e) {
      return;
    }
  }

  void _buildInventoryCache() {
    _cachedInventoryByProduct.clear();
    for (var item in inventoryItems) {
      final productId = item.productId.toString();
      if (!_cachedInventoryByProduct.containsKey(productId)) {
        _cachedInventoryByProduct[productId] = [];
      }
      _cachedInventoryByProduct[productId]!.add(item);
    }
  }

  List<String> _getAvailableSizesForProduct(String productId) {
    if (productId.isEmpty) return [];

    final inventory = _cachedInventoryByProduct[productId] ?? [];
    final sizes = inventory
        .map((item) => item.sizeName)
        .where((size) => size.isNotEmpty)
        .toSet()
        .toList();
    return sizes;
  }

  bool _productHasInventory(String productId) {
    return _cachedInventoryByProduct.containsKey(productId) &&
        _cachedInventoryByProduct[productId]!.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.kycData != null;
    _addFamilyMember();
    _loadDropdownData();
  }

  Map<String, dynamic> _createEmptyProduct() {
    return <String, dynamic>{
      'product_id': '',
      'product_name': '',
      'size': '',
      'quantity': '0',
      'price': '0.00',
      'total': '0.00',
      // 'is_autofilled': false,
      'inventoryid': '',
      'selectedInventoryDropdown': '',
    };
  }

  Map<String, dynamic> _createEmptyFamilyMember() {
    return {
      'name': '',
      'gender': '',
      'age': '',
      'relation': '',
      'occupation': '',
      'occupation_id': '',
      'products': <Map<String, dynamic>>[_createEmptyProduct()],
      // Explicit type casting
      'member_total': '0.00',
    };
  }

  Future<void> _loadDropdownData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _kycService.fetchCustomers(context),
        _kycService.fetchProducts(context),
        _kycService.fetchGenders(context),
        _relService.fetchRelations(context),
        _kycService.fetchSizes(context),
        _kycService.fetchOccupations(context),
        fetchInventoryItems(),
      ]);

      if (mounted) {
        setState(() {
          _customers = results[0] as List<Map<String, dynamic>>;
          _products = results[1] as List<Map<String, dynamic>>;
          _genders = results[2] as List<Map<String, dynamic>>;
          _relations = results[3] as List<RelationMasterModel>;
          _sizes = results[4] as List<Map<String, dynamic>>;
          _occupations = results[5] as List<Map<String, dynamic>>;
          _isDropdownDataLoaded = true;
        });

        if (_isEditMode) {
          _loadKYCDetail();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadKYCDetail() {
    if (widget.kycData != null && _isDropdownDataLoaded) {
      setState(() {
        _selectedCustomerId = widget.kycData!['customer_id']?.toString();
        _selectedCustomerName = widget.kycData!['customer_name']?.toString();
        _totalAmount = widget.kycData!['total_amount']?.toString() ?? '0.00';

        if (widget.kycData!['family_members'] != null) {
          var familyMembersData = widget.kycData!['family_members'];
          print('familyMembersData$familyMembersData');
          if (familyMembersData is List) {
            _familyMembersWithProducts = List<Map<String, dynamic>>.from(
              familyMembersData.map((member) {
                // Handle relation - if it's an ID, find the relation name
                String relationValue = member['relation']?.toString() ?? '';
                if (relationValue.isNotEmpty && _relations.isNotEmpty) {
                  // Try to find relation by ID
                  final relation = _relations.firstWhere(
                    (r) => r.id.toString() == relationValue,
                    orElse: () => RelationMasterModel(
                      id: '',
                      companyid: '',
                      relation: relationValue,
                      addedby: '',
                      activestatus: '',
                    ),
                  );
                  // If found by ID, use the relation name
                  if (relation.id.toString() == relationValue &&
                      relation.relation.isNotEmpty) {
                    member['relation'] = relation.relation;
                  }
                }

                // Ensure products is a List
                if (member['products'] != null) {
                  if (member['products'] is String) {
                    try {
                      member['products'] = jsonDecode(member['products']);
                    } catch (e) {
                      member['products'] = [];
                    }
                  }
                  if (member['products'] is! List) {
                    member['products'] = [];
                  }
                } else {
                  member['products'] = [];
                }

                // CRITICAL FIX: Check if products have valid data, if not add empty product
                bool hasValidProduct = false;
                if (member['products'] is List) {
                  for (var product in member['products']) {
                    if (product['product_name']?.toString().isNotEmpty ==
                        true) {
                      hasValidProduct = true;
                      break;
                    }
                  }
                }

                // Only add empty product if no valid products exist
                if (!hasValidProduct) {
                  member['products'] = [_createEmptyProduct()];
                }

                return Map<String, dynamic>.from(member);
              }),
            );

            _buildInventoryCache();
            _autoFillExistingProducts();
          }
        }

        if (_familyMembersWithProducts.isEmpty) {
          _addFamilyMember();
        }
      });
    }
  }

  void _autoFillExistingProducts() {
    for (
      int memberIdx = 0;
      memberIdx < _familyMembersWithProducts.length;
      memberIdx++
    ) {
      var products = _familyMembersWithProducts[memberIdx]['products'];
      print('products$products');
      for (int productIdx = 0; productIdx < products.length; productIdx++) {
        final productId = products[productIdx]['product_id']?.toString() ?? '';
        final inventoryId =
            products[productIdx]['inventoryid']?.toString() ?? '';
        if (inventoryId.isNotEmpty) {
          final InventoryItem inventory = inventoryItems
              .where((inventory) => inventory.id.toString() == inventoryId)
              .first;
          products[productIdx]['selectedInventoryDropdown'] =
              '${inventory.inventoryid} - ${inventory.productName} - ${inventory.modelName} - ${inventory.unitName} - ${inventory.sizeName}';
        }
        if (productId.isNotEmpty) {
          final availableSizes = _getAvailableSizesForProduct(productId);

          if (availableSizes.length == 1 &&
              (products[productIdx]['size'] == null ||
                  products[productIdx]['size'].toString().isEmpty)) {
            products[productIdx]['size'] = availableSizes.first;
            // products[productIdx]['is_autofilled'] = true;
          }
        }
      }
    }
  }

  String _getNameById(List<Map<String, dynamic>> items, String? id) {
    if (id == null || id.isEmpty) return '';
    final item = items.firstWhere(
      (item) => item['id'].toString() == id,
      orElse: () => {},
    );
    return item['name'] ?? '';
  }

  String _getRelById(List<RelationMasterModel> items, String? id) {
    if (id == null || id.isEmpty) return '';

    // First try to find by ID
    final itemById = items.firstWhere(
      (item) => item.id.toString() == id,
      orElse: () => RelationMasterModel(
        id: '',
        companyid: '',
        relation: '',
        addedby: '',
        activestatus: '',
      ),
    );

    // If found by ID, return the relation name
    if (itemById.id.toString() == id) {
      return itemById.relation;
    }

    // If not found by ID, try to find by relation name (case insensitive)
    final itemByName = items.firstWhere(
      (item) => item.relation.toLowerCase() == id.toLowerCase(),
      orElse: () => RelationMasterModel(
        id: '',
        companyid: '',
        relation: '',
        addedby: '',
        activestatus: '',
      ),
    );

    return itemByName.relation;
  }

  void _addFamilyMember() {
    setState(() {
      _familyMembersWithProducts.add(_createEmptyFamilyMember());
    });
  }

  void _removeFamilyMember(int index) {
    setState(() {
      _familyMembersWithProducts.removeAt(index);
    });
    _calculateTotalAmount();
  }

  void _updateFamilyMember(int index, String field, dynamic value) {
    setState(() {
      _familyMembersWithProducts[index][field] = value;
    });
  }

  void _addProductToMember(int memberIndex) {
    setState(() {
      final newProduct = _createEmptyProduct();

      // Safely get the products list
      dynamic productsData =
          _familyMembersWithProducts[memberIndex]['products'];

      if (productsData is List) {
        // Cast to List<Map<String, dynamic>> if needed
        List<Map<String, dynamic>> productsList =
            List<Map<String, dynamic>>.from(productsData);
        productsList.add(newProduct);
        _familyMembersWithProducts[memberIndex]['products'] = productsList;
      } else {
        // If products is not a List, create a new list
        _familyMembersWithProducts[memberIndex]['products'] =
            <Map<String, dynamic>>[newProduct];
      }
    });
  }

  void _removeProductFromMember(int memberIndex, int productIndex) {
    setState(() {
      dynamic productsData =
          _familyMembersWithProducts[memberIndex]['products'];

      if (productsData is List) {
        List<Map<String, dynamic>> productsList =
            List<Map<String, dynamic>>.from(productsData);
        if (productIndex < productsList.length) {
          productsList.removeAt(productIndex);
          _familyMembersWithProducts[memberIndex]['products'] = productsList;
        }
      }

      _calculateMemberTotal(memberIndex);
      _calculateTotalAmount();
    });
  }

  void _updateAvailableSizesFromList(
    List<Map<String, dynamic>> productsList,
    int memberIndex,
    int productIndex,
    String productId,
  ) {
    final availableSizes = _getAvailableSizesForProduct(productId);

    // If only one size exists, auto-select it
    if (availableSizes.length == 1) {
      productsList[productIndex]['size'] = availableSizes.first;
      // productsList[productIndex]['is_autofilled'] = true;
    } else {
      // productsList[productIndex]['is_autofilled'] = false;
      // Clear size if product changed and multiple sizes available
      productsList[productIndex]['size'] = '';
    }
  }

  void _updateProduct(
    int memberIndex,
    int productIndex,
    String field,
    dynamic value,
  ) {
    setState(() {
      dynamic productsData =
          _familyMembersWithProducts[memberIndex]['products'];

      if (productsData is List) {
        List<Map<String, dynamic>> productsList =
            List<Map<String, dynamic>>.from(productsData);

        if (productIndex < productsList.length) {
          productsList[productIndex][field] = value;

          // If product is selected, check inventory and auto-fill size
          if (field == 'product_id' || field == 'product_name') {
            final productId =
                productsList[productIndex]['product_id']?.toString() ?? '';

            // Fix: Ensure we're getting the correct product ID
            if (field == 'product_name' && value != null && value.isNotEmpty) {
              // Find the product by name to get its ID
              final selected = _products.firstWhere(
                (p) => p['name'] == value,
                orElse: () => {},
              );
              if (selected.isNotEmpty) {
                final productIdFromName = selected['id']?.toString() ?? '';
                productsList[productIndex]['product_id'] = productIdFromName;
                // Update available sizes with the new product ID
                _updateAvailableSizesFromList(
                  productsList,
                  memberIndex,
                  productIndex,
                  productIdFromName,
                );
                _familyMembersWithProducts[memberIndex]['products'] =
                    productsList;
                return;
              }
            }

            // Handle product_id field change
            _updateAvailableSizesFromList(
              productsList,
              memberIndex,
              productIndex,
              productId,
            );
          }

          // Recalculate total for this product
          if (field == 'quantity' || field == 'price') {
            double quantity =
                double.tryParse(
                  productsList[productIndex]['quantity']?.toString() ?? '0',
                ) ??
                0;
            double price =
                double.tryParse(
                  productsList[productIndex]['price']?.toString() ?? '0',
                ) ??
                0;
            double total = quantity * price;
            productsList[productIndex]['total'] = total.toStringAsFixed(2);
          }

          _familyMembersWithProducts[memberIndex]['products'] = productsList;
        }
      }

      _calculateMemberTotal(memberIndex);
      _calculateTotalAmount();
    });
  }

  // void _updateAvailableSizes(
  //   int memberIndex,
  //   int productIndex,
  //   String productId,
  // ) {
  //   final availableSizes = _getAvailableSizesForProduct(productId);
  //
  //   // If only one size exists, auto-select it
  //   if (availableSizes.length == 1) {
  //     _familyMembersWithProducts[memberIndex]['products'][productIndex]['size'] =
  //         availableSizes.first;
  //     _familyMembersWithProducts[memberIndex]['products'][productIndex]['is_autofilled'] =
  //         true;
  //   } else {
  //     _familyMembersWithProducts[memberIndex]['products'][productIndex]['is_autofilled'] =
  //         false;
  //     // Clear size if product changed and multiple sizes available
  //     _familyMembersWithProducts[memberIndex]['products'][productIndex]['size'] =
  //         '';
  //   }
  // }

  void _calculateMemberTotal(int memberIndex) {
    double total = 0;
    dynamic productsData = _familyMembersWithProducts[memberIndex]['products'];

    if (productsData is List) {
      List<Map<String, dynamic>> productsList = List<Map<String, dynamic>>.from(
        productsData,
      );
      for (var product in productsList) {
        total += double.tryParse(product['total']?.toString() ?? '0') ?? 0;
      }
    }

    setState(() {
      _familyMembersWithProducts[memberIndex]['member_total'] = total
          .toStringAsFixed(2);
    });
  }

  void _calculateTotalAmount() {
    double total = 0;
    for (var member in _familyMembersWithProducts) {
      total += double.tryParse(member['member_total']?.toString() ?? '0') ?? 0;
    }
    setState(() {
      _totalAmount = total.toStringAsFixed(2);
    });
  }

  Future<void> _submitForm() async {
    if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Filter out empty family members and their empty products
    List<Map<String, dynamic>> validFamilyMembers = [];
    for (var member in _familyMembersWithProducts) {
      if (member['name']?.toString().isNotEmpty == true) {
        List<Map<String, dynamic>> validProducts = [];

        // Get products as a proper list
        dynamic productsData = member['products'];
        if (productsData is List) {
          List<Map<String, dynamic>> productsList =
              List<Map<String, dynamic>>.from(productsData);

          for (var product in productsList) {
            // Check if product has valid data
            bool hasProductName =
                product['product_name']?.toString().isNotEmpty == true;
            bool hasSize = product['size']?.toString().isNotEmpty == true;
            bool hasQuantity =
                double.tryParse(product['quantity']?.toString() ?? '0')! > 0;

            // Only add products that have a product name AND (size OR quantity)
            if (hasProductName && (hasSize || hasQuantity)) {
              // Ensure all fields have proper values
              Map<String, dynamic> validProduct = {
                'product_id': product['product_id']?.toString() ?? '',
                'product_name': product['product_name']?.toString() ?? '',
                'size': product['size']?.toString() ?? '',
                'quantity': product['quantity']?.toString() ?? '0',
                'price': product['price']?.toString() ?? '0.00',
                'total': product['total']?.toString() ?? '0.00',
                // 'is_autofilled': product['is_autofilled'] ?? false,
                'inventoryid': product['inventoryid']?.toString() ?? '',
              };
              validProducts.add(validProduct);
            }
          }
        }

        // Only add member if they have valid products
        if (validProducts.isNotEmpty) {
          // Get relation ID from name
          String relationId = member['relation']?.toString() ?? '';
          if (relationId.isNotEmpty && _relations.isNotEmpty) {
            // Try to find relation by name
            final relation = _relations.firstWhere(
              (r) => r.relation.toLowerCase() == relationId.toLowerCase(),
              orElse: () => RelationMasterModel(
                id: '',
                companyid: '',
                relation: '',
                addedby: '',
                activestatus: '',
              ),
            );
            if (relation.id.isNotEmpty) {
              relationId = relation.id;
            }
          }

          Map<String, dynamic> validMember = {
            'name': member['name']?.toString() ?? '',
            'gender': member['gender']?.toString() ?? '',
            'age': member['age']?.toString() ?? '',
            'relation': relationId,
            'occupation': member['occupation']?.toString() ?? '',
            'occupation_id': member['occupation_id']?.toString() ?? '',
            'products': validProducts,
            'member_total': member['member_total']?.toString() ?? '0.00',
          };
          validFamilyMembers.add(validMember);
        }
      }
    }

    if (validFamilyMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one family member with valid products',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String result;

      if (_isEditMode) {
        result = await _kycService.updateKYC(
          context: context,
          kycId: widget.kycData!['id'].toString(),
          customerId: _selectedCustomerId!,
          customerName: _selectedCustomerName ?? '',
          totalAmount: _totalAmount,
          familyMembers: validFamilyMembers,
          productSections: [],
        );
      } else {
        result = await _kycService.insertKYC(
          context: context,
          customerId: _selectedCustomerId!,
          customerName: _selectedCustomerName ?? '',
          totalAmount: _totalAmount,
          familyMembers: validFamilyMembers,
          productSections: [],
        );
      }

      if (result == "Success") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'KYC updated successfully!'
                    : 'KYC saved successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        // Handle non-success response
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save KYC: $result'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCustomerDropdown() {
    final customerNames = _customers
        .map(
          (c) => {
            'name': c['name'].toString(),
            'mobile': c['mobile1'].toString(),
          },
        )
        .toList();
    String? selectedName = _getNameById(_customers, _selectedCustomerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Source Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: CustomDropdownSearchSource(
            label: "",
            isRequired: true,
            items: customerNames,
            selectedItem: selectedName,
            onChanged: (value) {
              if (value != null && value.isNotEmpty) {
                final selected = _customers.firstWhere(
                  (c) => c['name'] == value,
                  orElse: () => {},
                );
                setState(() {
                  _selectedCustomerId = selected['id']?.toString();
                  _selectedCustomerName = selected['name']?.toString();
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // Helper method to get unique product options
  List<Map<String, dynamic>> _getUniqueProductOptions() {
    final Map<String, Map<String, dynamic>> uniqueProducts = {};
    for (var product in _products) {
      final id = product['id']?.toString();
      final name = product['name']?.toString();
      if (id != null && name != null && !uniqueProducts.containsKey(id)) {
        uniqueProducts[id] = {'id': id, 'name': name};
      }
    }
    return uniqueProducts.values.toList();
  }

  // Helper method to get current product ID
  String? _getCurrentProductId(int memberIdx, int productIdx) {
    final product =
        _familyMembersWithProducts[memberIdx]['products'][productIdx];
    final productId = product['product_id']?.toString();
    if (productId != null && productId.isNotEmpty) {
      // Verify this ID exists in the products list
      final exists = _products.any((p) => p['id']?.toString() == productId);
      if (exists) {
        return productId;
      }
    }
    return null;
  }

  Widget _buildProductRow(
    int memberIdx,
    int productIdx,
    Map<String, dynamic> product,
  ) {
    // List<String> productNames = _products
    //     .map((p) => p['name'] as String)
    //     .toList();

    // Get available sizes based on selected product
    final productId = product['product_id']?.toString() ?? '';
    final availableSizes = _getAvailableSizesForProduct(productId);
    // final isAutofilled = product['is_autofilled'] ?? false;
    final hasInventory = _productHasInventory(productId);

    // Use available sizes if product selected, otherwise show all sizes
    List<String> sizeNames = productId.isNotEmpty && availableSizes.isNotEmpty
        ? availableSizes
        : _sizes.map((s) => s['sizename'] as String).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            // isAutofilled ? Colors.green.shade50 :
            Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              // isAutofilled ? Colors.green.shade200 :
              Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Product Name with Auto-filled indicator
          Row(
            children: [
              Expanded(
                child: CustomDropdownSearch(
                  selectedItem:
                      product['selectedInventoryDropdown']
                              ?.toString()
                              .isNotEmpty ==
                          true
                      ? product['selectedInventoryDropdown'].toString()
                      : null,
                  isRequired: true,
                  label: 'Select Inventory',
                  items: inventoryItems.map((inventory) {
                    return '${inventory.inventoryid} - ${inventory.productName} - ${inventory.modelName} - ${inventory.unitName} - ${inventory.sizeName}';
                  }).toList(),
                  onChanged: (value) {
                    // _selectedInventoryDropdown = value;

                    final selectedInventory = inventoryItems
                        .where(
                          (inventory) =>
                              '${inventory.inventoryid} - ${inventory.productName} - ${inventory.modelName} - ${inventory.unitName} - ${inventory.sizeName}' ==
                              value,
                        )
                        .first;
                    _selectedInventoryId = inventoryItems
                        .where(
                          (inventory) =>
                              '${inventory.inventoryid} - ${inventory.productName} - ${inventory.modelName} - ${inventory.unitName} - ${inventory.sizeName}' ==
                              value,
                        )
                        .first
                        .id;
                    if (_selectedInventoryId != null) {
                      final selected = _products.firstWhere(
                        (p) => p['name'] == selectedInventory.productName,
                        orElse: () => {},
                      );

                      if (selected.isNotEmpty) {
                        final productId = selected['id']?.toString() ?? '';
                        _updateProduct(
                          memberIdx,
                          productIdx,
                          'product_id',
                          productId,
                        );
                        _updateProduct(
                          memberIdx,
                          productIdx,
                          'product_name',
                          selectedInventory.productName,
                        );
                        _updateProduct(
                          memberIdx,
                          productIdx,
                          'size',
                          selectedInventory.sizeName,
                        );
                        _updateProduct(
                          memberIdx,
                          productIdx,
                          'inventoryid',
                          selectedInventory.id.toString(),
                        );
                        _updateProduct(
                          memberIdx,
                          productIdx,
                          'selectedInventoryDropdown',
                          value,
                        );
                      }
                    }
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Product',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        // if (isAutofilled) ...[
                        //   const SizedBox(width: 8),
                        //   Container(
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 6,
                        //       vertical: 2,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: Colors.green.shade100,
                        //       borderRadius: BorderRadius.circular(4),
                        //     ),
                        //     child: Text(
                        //       'Auto-filled',
                        //       style: TextStyle(
                        //         fontSize: 10,
                        //         color: Colors.green.shade700,
                        //         fontWeight: FontWeight.w500,
                        //       ),
                        //     ),
                        //   ),
                        // ],
                        if (!hasInventory && productId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'No inventory',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _getCurrentProductId(
                          memberIdx,
                          productIdx,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        isExpanded: true,
                        hint: const Text('Select Product'),
                        items: _getUniqueProductOptions().map((product) {
                          return DropdownMenuItem<String>(
                            value: product['id'],
                            child: Text(
                              product['name'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && value.isNotEmpty) {
                            final selected = _products.firstWhere(
                              (p) => p['id']?.toString() == value,
                              orElse: () => {},
                            );
                            if (selected.isNotEmpty) {
                              final productId =
                                  selected['id']?.toString() ?? '';
                              final productName =
                                  selected['name']?.toString() ?? '';
                              _updateProduct(
                                memberIdx,
                                productIdx,
                                'product_id',
                                productId,
                              );
                              _updateProduct(
                                memberIdx,
                                productIdx,
                                'product_name',
                                productName,
                              );
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Size and Quantity Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Size',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        // if (isAutofilled) ...[
                        //   const SizedBox(width: 8),
                        //   Container(
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 6,
                        //       vertical: 2,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: Colors.green.shade100,
                        //       borderRadius: BorderRadius.circular(4),
                        //     ),
                        //     child: Text(
                        //       'Auto-filled',
                        //       style: TextStyle(
                        //         fontSize: 10,
                        //         color: Colors.green.shade700,
                        //         fontWeight: FontWeight.w500,
                        //       ),
                        //     ),
                        //   ),
                        // ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              // isAutofilled
                              //     ? Colors.green.shade300
                              //     :
                              Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            product['size']?.toString().isNotEmpty == true
                            ? product['size'].toString()
                            : null,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        isExpanded: true,
                        hint: Text(
                          sizeNames.isEmpty
                              ? 'No sizes available'
                              : 'Select Size',
                        ),
                        items: sizeNames.map((size) {
                          return DropdownMenuItem<String>(
                            value: size,
                            child: Text(size, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged:
                            // isAutofilled || sizeNames.isEmpty
                            //     ? null
                            //     :
                            (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value != 'No sizes available') {
                                _updateProduct(
                                  memberIdx,
                                  productIdx,
                                  'size',
                                  value,
                                );
                              }
                            },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: product['quantity']?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) => _updateProduct(
                        memberIdx,
                        productIdx,
                        'quantity',
                        value,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price and Total Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: product['price']?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) =>
                          _updateProduct(memberIdx, productIdx, 'price', value),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('₹ ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              double.tryParse(
                                    product['total']?.toString() ?? '0',
                                  )?.toStringAsFixed(2) ??
                                  '0.00',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Delete Button
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => _removeProductFromMember(memberIdx, productIdx),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _addProductToMember(memberIdx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Product'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFamilyMemberCard(int memberIdx) {
    var member = _familyMembersWithProducts[memberIdx];
    List<String> genderNames = _genders
        .map((g) => g['name'] as String)
        .toList();
    List<String> relationNames = _relations.map((r) => r.relation).toList();
    List<String> occupationNames = _occupations
        .map((o) => o['name'] as String)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Family Member ${memberIdx + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_familyMembersWithProducts.length > 1)
                      IconButton(
                        onPressed: () => _removeFamilyMember(memberIdx),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addFamilyMember(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Member'),
                  ),
                ),
              ],
            ),
          ),

          // Member Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: member['name'],
                      decoration: const InputDecoration(
                        hintText: 'Enter name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) =>
                          _updateFamilyMember(memberIdx, 'name', value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Gender and Age Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gender',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CustomDropdownSearch(
                            label: "",
                            items: genderNames,
                            selectedItem: _getNameById(
                              _genders,
                              member['gender'],
                            ),
                            onChanged: (value) {
                              final selected = _genders.firstWhere(
                                (g) => g['name'] == value,
                                orElse: () => {},
                              );
                              _updateFamilyMember(
                                memberIdx,
                                'gender',
                                selected['id']?.toString() ?? '',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Age',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: member['age'],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Age',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                _updateFamilyMember(memberIdx, 'age', value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Relation and Occupation Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Relation',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CustomDropdownSearch(
                            label: "",
                            items: relationNames,
                            selectedItem: _getRelById(
                              _relations,
                              member['relation'],
                            ),
                            onChanged: (value) {
                              final selected = _relations.firstWhere(
                                (r) => r.relation == value,
                                // orElse: () => {},
                              );
                              _updateFamilyMember(
                                memberIdx,
                                'relation',
                                selected.id.toString(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Occupation',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CustomDropdownSearch(
                            label: "",
                            items: occupationNames,
                            selectedItem: _getNameById(
                              _occupations,
                              member['occupation_id'],
                            ),
                            onChanged: (value) {
                              final selected = _occupations.firstWhere(
                                (o) => o['name'] == value,
                                orElse: () => {},
                              );
                              _updateFamilyMember(
                                memberIdx,
                                'occupation_id',
                                selected['id']?.toString() ?? '',
                              );
                              _updateFamilyMember(
                                memberIdx,
                                'occupation',
                                selected['name']?.toString() ?? '',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Products Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Products for ${member['name']?.isNotEmpty == true ? member['name'] : 'Member ${memberIdx + 1}'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _addProductToMember(memberIdx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Products List
                ...member['products'].asMap().entries.map((productEntry) {
                  int productIdx = productEntry.key;
                  var product = productEntry.value;
                  return _buildProductRow(memberIdx, productIdx, product);
                }),
              ],
            ),
          ),

          // Member Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Member Total:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '₹ ${member['member_total'] ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersSection() {
    if (_familyMembersWithProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.family_restroom, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No family members added'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addFamilyMember,
              icon: const Icon(Icons.add),
              label: const Text('Add Family Member'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...List.generate(
          _familyMembersWithProducts.length,
          (index) => buildFamilyMemberCard(index),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Family KYC' : 'Family KYC'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularWaveProgress(),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Selection Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFF8FAFC),
                    child: _buildCustomerDropdown(),
                  ),

                  const SizedBox(height: 16),

                  // Family Members with Products Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFamilyMembersSection(),
                  ),

                  const SizedBox(height: 16),

                  // Add Another Family Member Button (if not empty)
                  if (_familyMembersWithProducts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addFamilyMember,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Another Family Member'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Total Amount and Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '₹ $_totalAmount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _isEditMode ? 'Update KYC' : 'Save KYC',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// Future<void> _submitForm() async {
//   if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Please select a customer'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }
//
//   // Filter out empty family members and their empty products
//   List<Map<String, dynamic>> validFamilyMembers = [];
//   for (var member in _familyMembersWithProducts) {
//     if (member['name']?.toString().isNotEmpty == true) {
//       List<Map<String, dynamic>> validProducts = [];
//       for (var product in member['products']) {
//         if (product['product_name']?.toString().isNotEmpty == true) {
//           validProducts.add(product);
//         }
//       }
//       if (validProducts.isNotEmpty) {
//         Map<String, dynamic> validMember = Map.from(member);
//         validMember['products'] = validProducts;
//         validFamilyMembers.add(validMember);
//       }
//     }
//   }
//
//   if (validFamilyMembers.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Please add at least one family member with products'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }
//
//   setState(() => _isLoading = true);
//
//   try {
//     String result;
//
//     if (_isEditMode) {
//       result = await _kycService.updateKYC(
//         context: context,
//         kycId: widget.kycData!['id'].toString(),
//         customerId: _selectedCustomerId!,
//         customerName: _selectedCustomerName ?? '',
//         totalAmount: _totalAmount,
//         familyMembers: validFamilyMembers,
//         productSections: [],
//       );
//     } else {
//       result = await _kycService.insertKYC(
//         context: context,
//         customerId: _selectedCustomerId!,
//         customerName: _selectedCustomerName ?? '',
//         totalAmount: _totalAmount,
//         familyMembers: validFamilyMembers,
//         productSections: [],
//       );
//     }
//
//     if (result == "Success") {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               _isEditMode
//                   ? 'KYC updated successfully!'
//                   : 'KYC saved successfully!',
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//       await Future.delayed(const Duration(seconds: 1));
//       if (mounted) Navigator.of(context).pop(true);
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     }
//   } finally {
//     if (mounted) setState(() => _isLoading = false);
//   }
// }
// void _calculateMemberTotal(int memberIndex) {
//   double total = 0;
//   for (var product in _familyMembersWithProducts[memberIndex]['products']) {
//     total += double.tryParse(product['total']?.toString() ?? '0') ?? 0;
//   }
//   setState(() {
//     _familyMembersWithProducts[memberIndex]['member_total'] = total
//         .toStringAsFixed(2);
//   });
// }
// void _updateProduct(
//   int memberIndex,
//   int productIndex,
//   String field,
//   dynamic value,
// ) {
//   setState(() {
//     _familyMembersWithProducts[memberIndex]['products'][productIndex][field] =
//         value;
//
//     // If product is selected, check inventory and auto-fill size
//     if (field == 'product_id' || field == 'product_name') {
//       final productId =
//           _familyMembersWithProducts[memberIndex]['products'][productIndex]['product_id']
//               ?.toString() ??
//           '';
//
//       // Fix: Ensure we're getting the correct product ID
//       if (field == 'product_name' && value != null && value.isNotEmpty) {
//         // Find the product by name to get its ID
//         final selected = _products.firstWhere(
//           (p) => p['name'] == value,
//           orElse: () => {},
//         );
//         if (selected.isNotEmpty) {
//           final productIdFromName = selected['id']?.toString() ?? '';
//           _familyMembersWithProducts[memberIndex]['products'][productIndex]['product_id'] =
//               productIdFromName;
//           // Update available sizes with the new product ID
//           _updateAvailableSizes(memberIndex, productIndex, productIdFromName);
//           return;
//         }
//       }
//
//       // Handle product_id field change
//       _updateAvailableSizes(memberIndex, productIndex, productId);
//     }
//
//     // Recalculate total for this product
//     if (field == 'quantity' || field == 'price') {
//       double quantity =
//           double.tryParse(
//             _familyMembersWithProducts[memberIndex]['products'][productIndex]['quantity']
//                     ?.toString() ??
//                 '0',
//           ) ??
//           0;
//       double price =
//           double.tryParse(
//             _familyMembersWithProducts[memberIndex]['products'][productIndex]['price']
//                     ?.toString() ??
//                 '0',
//           ) ??
//           0;
//       double total = quantity * price;
//       _familyMembersWithProducts[memberIndex]['products'][productIndex]['total'] =
//           total.toStringAsFixed(2);
//     }
//
//     _calculateMemberTotal(memberIndex);
//     _calculateTotalAmount();
//   });
// }

// void _removeProductFromMember(int memberIndex, int productIndex) {
//   setState(() {
//     _familyMembersWithProducts[memberIndex]['products'].removeAt(
//       productIndex,
//     );
//   });
//   _calculateMemberTotal(memberIndex);
//   _calculateTotalAmount();
// }

// void _addProductToMember(int memberIndex) {
//   setState(() {
//     _familyMembersWithProducts[memberIndex]['products'].add(
//       _createEmptyProduct(),
//     );
//   });
// }

// String _getRelById(List<RelationMasterModel> items, String? id) {
//   if (id == null || id.isEmpty) return '';
//   final item = items.firstWhere(
//     (item) => item.relation.toLowerCase().toString() == id.toLowerCase(),
//     orElse: () => RelationMasterModel(
//       id: '',
//       companyid: '',
//       relation: '',
//       addedby: '',
//       activestatus: '',
//     ),
//   );
//   return item.relation;
// }

// void _loadKYCDetail() {
//   if (widget.kycData != null && _isDropdownDataLoaded) {
//     setState(() {
//       _selectedCustomerId = widget.kycData!['customer_id']?.toString();
//       _selectedCustomerName = widget.kycData!['customer_name']?.toString();
//       _totalAmount = widget.kycData!['total_amount']?.toString() ?? '0.00';
//
//       if (widget.kycData!['family_members'] != null) {
//         _familyMembersWithProducts = List<Map<String, dynamic>>.from(
//           widget.kycData!['family_members'],
//         );
//         _buildInventoryCache();
//         _autoFillExistingProducts();
//       }
//
//       if (_familyMembersWithProducts.isEmpty) {
//         _addFamilyMember();
//       }
//     });
//   }
// }

// Map<String, dynamic> _createEmptyFamilyMember() {
//   return {
//     'name': '',
//     'gender': '',
//     'age': '',
//     'relation': '',
//     'occupation': '',
//     'occupation_id': '',
//     'products': [_createEmptyProduct()],
//     'member_total': '0.00',
//   };
// }

// Map<String, dynamic> _createEmptyProduct() {
//   return {
//     'product_id': '',
//     'product_name': '',
//     'size': '',
//     'quantity': '0',
//     'price': '0.00',
//     'total': '0.00',
//     'is_autofilled': false,
//   };
// }

// import 'package:flutter/material.dart';
// import 'package:dropdown_search/dropdown_search.dart';
//
// import '../services/kyc_apiservice.dart';
// import '../services/customer_apiservice.dart';
// import '../widgets/customdropdownwidget.dart';
//
// class KYCEntryScreen extends StatefulWidget {
//   final Map<String, dynamic>? kycData;
//   const KYCEntryScreen({super.key, this.kycData});
//
//   @override
//   State<KYCEntryScreen> createState() => _KYCEntryScreenState();
// }
//
// class _KYCEntryScreenState extends State<KYCEntryScreen> {
//   final KYCApiService _kycService = KYCApiService();
//   final CustomerApiService _customerService = CustomerApiService();
//
//   bool _isLoading = false;
//   bool _isEditMode = false;
//   bool _isDropdownDataLoaded = false;
//
//   // Dropdown data
//   List<Map<String, dynamic>> _customers = [];
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _genders = [];
//   List<Map<String, dynamic>> _relations = [];
//   List<Map<String, dynamic>> _sizes = [];
//   List<Map<String, dynamic>> _occupations = [];
//
//   // Selected values
//   String? _selectedCustomerId;
//   String? _selectedCustomerName;
//   String _totalAmount = '0.00';
//
//   // Family Members with their own products
//   List<Map<String, dynamic>> _familyMembersWithProducts = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _isEditMode = widget.kycData != null;
//
//     // Initialize with one empty family member
//     _addFamilyMember();
//
//     _loadDropdownData();
//   }
//
//   Map<String, dynamic> _createEmptyProduct() {
//     return {
//       'product_id': '',
//       'product_name': '',
//       'size': '',
//       'quantity': '0',
//       'price': '0.00',
//       'total': '0.00',
//     };
//   }
//
//   Map<String, dynamic> _createEmptyFamilyMember() {
//     return {
//       'name': '',
//       'gender': '',
//       'age': '',
//       'relation': '',
//       'occupation': '',
//       'occupation_id': '',
//       'products': [_createEmptyProduct()],
//       'member_total': '0.00',
//     };
//   }
//
//   Future<void> _loadDropdownData() async {
//     setState(() => _isLoading = true);
//
//     try {
//       final results = await Future.wait([
//         _kycService.fetchCustomers(context),
//         _kycService.fetchProducts(context),
//         _kycService.fetchGenders(context),
//         _kycService.fetchRelations(context),
//         _kycService.fetchSizes(context),
//         _kycService.fetchOccupations(context),
//       ]);
//
//       if (mounted) {
//         setState(() {
//           _customers = results[0];
//           _products = results[1];
//           _genders = results[2];
//           _relations = results[3];
//           _sizes = results[4];
//           _occupations = results[5];
//           _isDropdownDataLoaded = true;
//         });
//
//         if (_isEditMode) {
//           _loadKYCDetail();
//         }
//       }
//     } catch (e) {
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   void _loadKYCDetail() {
//     if (widget.kycData != null && _isDropdownDataLoaded) {
//       setState(() {
//         _selectedCustomerId = widget.kycData!['customer_id']?.toString();
//         _selectedCustomerName = widget.kycData!['customer_name']?.toString();
//         _totalAmount = widget.kycData!['total_amount']?.toString() ?? '0.00';
//
//         if (widget.kycData!['family_members'] != null) {
//           _familyMembersWithProducts = List<Map<String, dynamic>>.from(widget.kycData!['family_members']);
//         }
//
//         if (_familyMembersWithProducts.isEmpty) {
//           _addFamilyMember();
//         }
//       });
//     }
//   }
//
//   String _getNameById(List<Map<String, dynamic>> items, String? id) {
//     if (id == null || id.isEmpty) return '';
//     final item = items.firstWhere(
//           (item) => item['id'].toString() == id,
//       orElse: () => {},
//     );
//     return item['name'] ?? '';
//   }
//
//   void _addFamilyMember() {
//     setState(() {
//       _familyMembersWithProducts.add(_createEmptyFamilyMember());
//     });
//   }
//
//   void _removeFamilyMember(int index) {
//     setState(() {
//       _familyMembersWithProducts.removeAt(index);
//     });
//     _calculateTotalAmount();
//   }
//
//   void _updateFamilyMember(int index, String field, dynamic value) {
//     setState(() {
//       _familyMembersWithProducts[index][field] = value;
//     });
//   }
//
//   void _addProductToMember(int memberIndex) {
//     setState(() {
//       _familyMembersWithProducts[memberIndex]['products'].add(_createEmptyProduct());
//     });
//   }
//
//   void _removeProductFromMember(int memberIndex, int productIndex) {
//     setState(() {
//       _familyMembersWithProducts[memberIndex]['products'].removeAt(productIndex);
//     });
//     _calculateMemberTotal(memberIndex);
//     _calculateTotalAmount();
//   }
//
//   void _updateProduct(int memberIndex, int productIndex, String field, dynamic value) {
//     setState(() {
//       _familyMembersWithProducts[memberIndex]['products'][productIndex][field] = value;
//
//       // Recalculate total for this product
//       if (field == 'quantity' || field == 'price') {
//         double quantity = double.tryParse(_familyMembersWithProducts[memberIndex]['products'][productIndex]['quantity']?.toString() ?? '0') ?? 0;
//         double price = double.tryParse(_familyMembersWithProducts[memberIndex]['products'][productIndex]['price']?.toString() ?? '0') ?? 0;
//         double total = quantity * price;
//         _familyMembersWithProducts[memberIndex]['products'][productIndex]['total'] = total.toStringAsFixed(2);
//       }
//
//       _calculateMemberTotal(memberIndex);
//       _calculateTotalAmount();
//     });
//   }
//
//   void _calculateMemberTotal(int memberIndex) {
//     double total = 0;
//     for (var product in _familyMembersWithProducts[memberIndex]['products']) {
//       total += double.tryParse(product['total']?.toString() ?? '0') ?? 0;
//     }
//     setState(() {
//       _familyMembersWithProducts[memberIndex]['member_total'] = total.toStringAsFixed(2);
//     });
//   }
//
//   void _calculateTotalAmount() {
//     double total = 0;
//     for (var member in _familyMembersWithProducts) {
//       total += double.tryParse(member['member_total']?.toString() ?? '0') ?? 0;
//     }
//     setState(() {
//       _totalAmount = total.toStringAsFixed(2);
//     });
//   }
//
//   Future<void> _submitForm() async {
//     if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a customer'), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     // Filter out empty family members and their empty products
//     List<Map<String, dynamic>> validFamilyMembers = [];
//     for (var member in _familyMembersWithProducts) {
//       if (member['name']?.toString().isNotEmpty == true) {
//         List<Map<String, dynamic>> validProducts = [];
//         for (var product in member['products']) {
//           if (product['product_name']?.toString().isNotEmpty == true) {
//             validProducts.add(product);
//           }
//         }
//         if (validProducts.isNotEmpty) {
//           Map<String, dynamic> validMember = Map.from(member);
//           validMember['products'] = validProducts;
//           validFamilyMembers.add(validMember);
//         }
//       }
//     }
//
//     if (validFamilyMembers.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please add at least one family member with products'), backgroundColor: Colors.red),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       String result;
//
//       if (_isEditMode) {
//         result = await _kycService.updateKYC(
//           context: context,
//           kycId: widget.kycData!['id'].toString(),
//           customerId: _selectedCustomerId!,
//           customerName: _selectedCustomerName ?? '',
//           totalAmount: _totalAmount,
//           familyMembers: validFamilyMembers,
//           productSections: [], // Not used in new structure
//         );
//       } else {
//         result = await _kycService.insertKYC(
//           context: context,
//           customerId: _selectedCustomerId!,
//           customerName: _selectedCustomerName ?? '',
//           totalAmount: _totalAmount,
//           familyMembers: validFamilyMembers,
//           productSections: [], // Not used in new structure
//         );
//       }
//
//       if (result == "Success") {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(_isEditMode ? 'KYC updated successfully!' : 'KYC saved successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         await Future.delayed(const Duration(seconds: 1));
//         if (mounted) Navigator.of(context).pop(true);
//       }
//     } catch (e) {
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   Widget _buildCustomerDropdown() {
//     List<String> customerNames = _customers.map((c) => c['name'] as String).toList();
//     String? selectedName = _getNameById(_customers, _selectedCustomerId);
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Customer Name',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
//         ),
//         const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: const Color(0xFFD1D5DB)),
//           ),
//           child: CustomDropdownSearch(
//             label: "",
//             isRequired: true,
//             items: customerNames,
//             selectedItem: selectedName,
//             onChanged: (value) {
//               if (value != null && value.isNotEmpty) {
//                 final selected = _customers.firstWhere(
//                       (c) => c['name'] == value,
//                   orElse: () => {},
//                 );
//                 setState(() {
//                   _selectedCustomerId = selected['id']?.toString();
//                   _selectedCustomerName = selected['name']?.toString();
//                 });
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFamilyMembersSection() {
//     List<String> genderNames = _genders.map((g) => g['name'] as String).toList();
//     List<String> relationNames = _relations.map((r) => r['name'] as String).toList();
//     List<String> occupationNames = _occupations.map((o) => o['name'] as String).toList();
//     List<String> productNames = _products.map((p) => p['name'] as String).toList();
//     List<String> sizeNames = _sizes.map((s) => s['name'] as String).toList();
//
//     List<Widget> memberWidgets = [];
//
//     for (int memberIdx = 0; memberIdx < _familyMembersWithProducts.length; memberIdx++) {
//       var member = _familyMembersWithProducts[memberIdx];
//
//       memberWidgets.add(
//         Container(
//           margin: const EdgeInsets.only(bottom: 20),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey[300]!),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Member Header
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF8FAFC),
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
//                   border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Family Member ${memberIdx + 1}',
//                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
//                     ),
//                     Row(
//                       children: [
//                         if (_familyMembersWithProducts.length > 1)
//                           IconButton(
//                             onPressed: () => _removeFamilyMember(memberIdx),
//                             icon: const Icon(Icons.delete_outline, color: Colors.red),
//                           ),
//                         const SizedBox(width: 8),
//                         ElevatedButton.icon(
//                           onPressed: () => _addFamilyMember(),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF1E293B),
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
//                           ),
//                           icon: const Icon(Icons.person_add, size: 16),
//                           label: const Text('Add Member'),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Member Details
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     // Member Information Row
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text('Name', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                               const SizedBox(height: 4),
//                               TextFormField(
//                                 initialValue: member['name'],
//                                 decoration: const InputDecoration(
//                                   hintText: 'Enter name',
//                                   border: OutlineInputBorder(),
//                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                                 ),
//                                 onChanged: (value) => _updateFamilyMember(memberIdx, 'name', value),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text('Gender', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                               const SizedBox(height: 4),
//                               CustomDropdownSearch(
//                                 label: "",
//                                 items: genderNames,
//                                 selectedItem: _getNameById(_genders, member['gender']),
//                                 onChanged: (value) {
//                                   final selected = _genders.firstWhere((g) => g['name'] == value, orElse: () => {});
//                                   _updateFamilyMember(memberIdx, 'gender', selected['id']?.toString() ?? '');
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text('Age', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                               const SizedBox(height: 4),
//                               TextFormField(
//                                 initialValue: member['age'],
//                                 keyboardType: TextInputType.number,
//                                 decoration: const InputDecoration(
//                                   hintText: 'Age',
//                                   border: OutlineInputBorder(),
//                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                                 ),
//                                 onChanged: (value) => _updateFamilyMember(memberIdx, 'age', value),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text('Relation', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                               const SizedBox(height: 4),
//                               CustomDropdownSearch(
//                                 label: "",
//                                 items: relationNames,
//                                 selectedItem: _getNameById(_relations, member['relation']),
//                                 onChanged: (value) {
//                                   final selected = _relations.firstWhere((r) => r['name'] == value, orElse: () => {});
//                                   _updateFamilyMember(memberIdx, 'relation', selected['id']?.toString() ?? '');
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text('Occupation', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                               const SizedBox(height: 4),
//                               CustomDropdownSearch(
//                                 label: "",
//                                 items: occupationNames,
//                                 selectedItem: _getNameById(_occupations, member['occupation_id']),
//                                 onChanged: (value) {
//                                   final selected = _occupations.firstWhere((o) => o['name'] == value, orElse: () => {});
//                                   _updateFamilyMember(memberIdx, 'occupation_id', selected['id']?.toString() ?? '');
//                                   _updateFamilyMember(memberIdx, 'occupation', selected['name']?.toString() ?? '');
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Products Section for this Member
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 color: const Color(0xFFF8FAFC),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Products for ${member['name']?.isNotEmpty == true ? member['name'] : 'Member ${memberIdx + 1}'}',
//                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
//                     ),
//                     ElevatedButton.icon(
//                       onPressed: () => _addProductToMember(memberIdx),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1E293B),
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
//                       ),
//                       icon: const Icon(Icons.add, size: 16),
//                       label: const Text('Add Product'),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Product Table Header
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 color: Colors.white,
//                 child: Row(
//                   children: const [
//                     Expanded(flex: 2, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
//                     Expanded(flex: 1, child: Text('Size', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
//                     Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
//                     Expanded(flex: 1, child: Text('Price', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
//                     Expanded(flex: 1, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12), textAlign: TextAlign.right)),
//                     SizedBox(width: 60, child: Text('Action', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
//                   ],
//                 ),
//               ),
//
//               // Products List
//               ...member['products'].asMap().entries.map((productEntry) {
//                 int productIdx = productEntry.key;
//                 var product = productEntry.value;
//                 return Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     border: Border(top: BorderSide(color: Colors.grey[200]!)),
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: CustomDropdownSearch(
//                           label: "",
//                           items: productNames,
//                           selectedItem: product['product_name'],
//                           onChanged: (value) {
//                             final selected = _products.firstWhere((p) => p['name'] == value, orElse: () => {});
//                             _updateProduct(memberIdx, productIdx, 'product_id', selected['id']?.toString() ?? '');
//                             _updateProduct(memberIdx, productIdx, 'product_name', selected['name']?.toString() ?? '');
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         flex: 1,
//                         child: CustomDropdownSearch(
//                           label: "",
//                           items: sizeNames,
//                           selectedItem: product['size'],
//                           onChanged: (value) => _updateProduct(memberIdx, productIdx, 'size', value),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         flex: 1,
//                         child: TextFormField(
//                           initialValue: product['quantity']?.toString(),
//                           keyboardType: TextInputType.number,
//                           decoration: const InputDecoration(
//                             border: OutlineInputBorder(),
//                             contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                           ),
//                           onChanged: (value) => _updateProduct(memberIdx, productIdx, 'quantity', value),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         flex: 1,
//                         child: TextFormField(
//                           initialValue: product['price']?.toString(),
//                           keyboardType: TextInputType.number,
//                           decoration: const InputDecoration(
//                             border: OutlineInputBorder(),
//                             contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                           ),
//                           onChanged: (value) => _updateProduct(memberIdx, productIdx, 'price', value),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         flex: 1,
//                         child: Container(
//                           alignment: Alignment.centerRight,
//                           padding: const EdgeInsets.symmetric(horizontal: 8),
//                           child: Text(
//                             '₹ ${double.tryParse(product['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
//                             style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       SizedBox(
//                         width: 60,
//                         child: IconButton(
//                           onPressed: () => _removeProductFromMember(memberIdx, productIdx),
//                           icon: const Icon(Icons.delete, color: Colors.red, size: 20),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//
//               // Member Total
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF8FAFC),
//                   borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
//                   border: Border(top: BorderSide(color: Colors.grey[300]!)),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     const Text(
//                       'Member Total: ',
//                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
//                     ),
//                     Text(
//                       '₹ ${member['member_total'] ?? '0.00'}',
//                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Column(
//       children: [
//         if (_familyMembersWithProducts.isEmpty)
//           Container(
//             padding: const EdgeInsets.all(32),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey[300]!),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               children: [
//                 const Icon(Icons.family_restroom, size: 48, color: Colors.grey),
//                 const SizedBox(height: 16),
//                 const Text('No family members added'),
//                 const SizedBox(height: 16),
//                 ElevatedButton.icon(
//                   onPressed: _addFamilyMember,
//                   icon: const Icon(Icons.add),
//                   label: const Text('Add Family Member'),
//                 ),
//               ],
//             ),
//           )
//         else
//           ...memberWidgets,
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(_isEditMode ? 'Edit Family KYC' : 'Family KYC'),
//         backgroundColor: const Color(0xFF1E293B),
//         foregroundColor: Colors.white,
//       ),
//       body: _isLoading
//           ? const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularWaveProgress(),
//             SizedBox(height: 16),
//             Text('Loading...', style: TextStyle(fontSize: 16, color: Colors.grey)),
//           ],
//         ),
//       )
//           : SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Customer Selection Section
//             Container(
//               padding: const EdgeInsets.all(16),
//               color: const Color(0xFFF8FAFC),
//               child: _buildCustomerDropdown(),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Family Members with Products Section
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: _buildFamilyMembersSection(),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Add Family Member Button (if empty)
//             if (_familyMembersWithProducts.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: _addFamilyMember,
//                     icon: const Icon(Icons.person_add),
//                     label: const Text('Add Another Family Member'),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                   ),
//                 ),
//               ),
//
//             const SizedBox(height: 20),
//
//             // Total Amount and Buttons
//             Container(
//               padding: const EdgeInsets.all(16),
//               color: const Color(0xFFF8FAFC),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       const Text(
//                         'Grand Total: ',
//                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
//                       ),
//                       Text(
//                         '₹ $_totalAmount',
//                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       OutlinedButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                           side: BorderSide(color: Colors.grey[300]!),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         ),
//                         child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//                       ),
//                       const SizedBox(width: 16),
//                       ElevatedButton(
//                         onPressed: _submitForm,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF1E293B),
//                           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         ),
//                         child: Text(
//                           _isEditMode ? 'Update KYC' : 'Save KYC',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
