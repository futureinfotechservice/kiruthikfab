import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../services/kyc_apiservice.dart';
import '../services/customer_apiservice.dart';
import '../widgets/customdropdownwidget.dart';

class KYCEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? kycData;
  const KYCEntryScreen({super.key, this.kycData});

  @override
  State<KYCEntryScreen> createState() => _KYCEntryScreenState();
}

class _KYCEntryScreenState extends State<KYCEntryScreen> {
  final KYCApiService _kycService = KYCApiService();
  final CustomerApiService _customerService = CustomerApiService();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isDropdownDataLoaded = false;

  // Dropdown data
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _genders = [];
  List<Map<String, dynamic>> _relations = [];
  List<Map<String, dynamic>> _sizes = [];
  List<Map<String, dynamic>> _occupations = [];

  // Selected values
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String _totalAmount = '0.00';

  // Family Members with their own products
  List<Map<String, dynamic>> _familyMembersWithProducts = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.kycData != null;

    // Initialize with one empty family member
    _addFamilyMember();

    _loadDropdownData();
  }

  Map<String, dynamic> _createEmptyProduct() {
    return {
      'product_id': '',
      'product_name': '',
      'size': '',
      'quantity': '0',
      'price': '0.00',
      'total': '0.00',
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
      'products': [_createEmptyProduct()],
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
        _kycService.fetchRelations(context),
        _kycService.fetchSizes(context),
        _kycService.fetchOccupations(context),
      ]);

      if (mounted) {
        setState(() {
          _customers = results[0];
          _products = results[1];
          _genders = results[2];
          _relations = results[3];
          _sizes = results[4];
          _occupations = results[5];
          _isDropdownDataLoaded = true;
        });

        if (_isEditMode) {
          _loadKYCDetail();
        }
      }
    } catch (e) {
      print("Error loading dropdown data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
      );
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
          _familyMembersWithProducts = List<Map<String, dynamic>>.from(widget.kycData!['family_members']);
        }

        if (_familyMembersWithProducts.isEmpty) {
          _addFamilyMember();
        }
      });
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
      _familyMembersWithProducts[memberIndex]['products'].add(_createEmptyProduct());
    });
  }

  void _removeProductFromMember(int memberIndex, int productIndex) {
    setState(() {
      _familyMembersWithProducts[memberIndex]['products'].removeAt(productIndex);
    });
    _calculateMemberTotal(memberIndex);
    _calculateTotalAmount();
  }

  void _updateProduct(int memberIndex, int productIndex, String field, dynamic value) {
    setState(() {
      _familyMembersWithProducts[memberIndex]['products'][productIndex][field] = value;

      // Recalculate total for this product
      if (field == 'quantity' || field == 'price') {
        double quantity = double.tryParse(_familyMembersWithProducts[memberIndex]['products'][productIndex]['quantity']?.toString() ?? '0') ?? 0;
        double price = double.tryParse(_familyMembersWithProducts[memberIndex]['products'][productIndex]['price']?.toString() ?? '0') ?? 0;
        double total = quantity * price;
        _familyMembersWithProducts[memberIndex]['products'][productIndex]['total'] = total.toStringAsFixed(2);
      }

      _calculateMemberTotal(memberIndex);
      _calculateTotalAmount();
    });
  }

  void _calculateMemberTotal(int memberIndex) {
    double total = 0;
    for (var product in _familyMembersWithProducts[memberIndex]['products']) {
      total += double.tryParse(product['total']?.toString() ?? '0') ?? 0;
    }
    setState(() {
      _familyMembersWithProducts[memberIndex]['member_total'] = total.toStringAsFixed(2);
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
        const SnackBar(content: Text('Please select a customer'), backgroundColor: Colors.red),
      );
      return;
    }

    // Filter out empty family members and their empty products
    List<Map<String, dynamic>> validFamilyMembers = [];
    for (var member in _familyMembersWithProducts) {
      if (member['name']?.toString().isNotEmpty == true) {
        List<Map<String, dynamic>> validProducts = [];
        for (var product in member['products']) {
          if (product['product_name']?.toString().isNotEmpty == true) {
            validProducts.add(product);
          }
        }
        if (validProducts.isNotEmpty) {
          Map<String, dynamic> validMember = Map.from(member);
          validMember['products'] = validProducts;
          validFamilyMembers.add(validMember);
        }
      }
    }

    if (validFamilyMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one family member with products'), backgroundColor: Colors.red),
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
          productSections: [], // Not used in new structure
        );
      } else {
        result = await _kycService.insertKYC(
          context: context,
          customerId: _selectedCustomerId!,
          customerName: _selectedCustomerName ?? '',
          totalAmount: _totalAmount,
          familyMembers: validFamilyMembers,
          productSections: [], // Not used in new structure
        );
      }

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'KYC updated successfully!' : 'KYC saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      print("Submit Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCustomerDropdown() {
    List<String> customerNames = _customers.map((c) => c['name'] as String).toList();
    String? selectedName = _getNameById(_customers, _selectedCustomerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Customer Name',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
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
          child: CustomDropdownSearch(
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

  // Mobile-optimized product row
  Widget _buildProductRow(int memberIdx, int productIdx, Map<String, dynamic> product) {
    List<String> productNames = _products.map((p) => p['name'] as String).toList();
    List<String> sizeNames = _sizes.map((s) => s['name'] as String).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Product Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
              const SizedBox(height: 4),
              CustomDropdownSearch(
                label: "",
                items: productNames,
                selectedItem: product['product_name'],
                onChanged: (value) {
                  final selected = _products.firstWhere((p) => p['name'] == value, orElse: () => {});
                  _updateProduct(memberIdx, productIdx, 'product_id', selected['id']?.toString() ?? '');
                  _updateProduct(memberIdx, productIdx, 'product_name', selected['name']?.toString() ?? '');
                },
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
                    const Text('Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                    const SizedBox(height: 4),
                    CustomDropdownSearch(
                      label: "",
                      items: sizeNames,
                      selectedItem: product['size'],
                      onChanged: (value) => _updateProduct(memberIdx, productIdx, 'size', value),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: product['quantity']?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) => _updateProduct(memberIdx, productIdx, 'quantity', value),
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
                    const Text('Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: product['price']?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) => _updateProduct(memberIdx, productIdx, 'price', value),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                              double.tryParse(product['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Mobile-optimized family member card
  Widget _buildFamilyMemberCard(int memberIdx) {
    var member = _familyMembersWithProducts[memberIdx];
    List<String> genderNames = _genders.map((g) => g['name'] as String).toList();
    List<String> relationNames = _relations.map((r) => r['name'] as String).toList();
    List<String> occupationNames = _occupations.map((o) => o['name'] as String).toList();

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_familyMembersWithProducts.length > 1)
                      IconButton(
                        onPressed: () => _removeFamilyMember(memberIdx),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    const Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: member['name'],
                      decoration: const InputDecoration(
                        hintText: 'Enter name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (value) => _updateFamilyMember(memberIdx, 'name', value),
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
                          const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          const SizedBox(height: 4),
                          CustomDropdownSearch(
                            label: "",
                            items: genderNames,
                            selectedItem: _getNameById(_genders, member['gender']),
                            onChanged: (value) {
                              final selected = _genders.firstWhere((g) => g['name'] == value, orElse: () => {});
                              _updateFamilyMember(memberIdx, 'gender', selected['id']?.toString() ?? '');
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
                          const Text('Age', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: member['age'],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Age',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            onChanged: (value) => _updateFamilyMember(memberIdx, 'age', value),
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
                          const Text('Relation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          const SizedBox(height: 4),
                          CustomDropdownSearch(
                            label: "",
                            items: relationNames,
                            selectedItem: _getNameById(_relations, member['relation']),
                            onChanged: (value) {
                              final selected = _relations.firstWhere((r) => r['name'] == value, orElse: () => {});
                              _updateFamilyMember(memberIdx, 'relation', selected['id']?.toString() ?? '');
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
                          const Text('Occupation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          const SizedBox(height: 4),
                          CustomDropdownSearch(
                            label: "",
                            items: occupationNames,
                            selectedItem: _getNameById(_occupations, member['occupation_id']),
                            onChanged: (value) {
                              final selected = _occupations.firstWhere((o) => o['name'] == value, orElse: () => {});
                              _updateFamilyMember(memberIdx, 'occupation_id', selected['id']?.toString() ?? '');
                              _updateFamilyMember(memberIdx, 'occupation', selected['name']?.toString() ?? '');
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
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Products for ${member['name']?.isNotEmpty == true ? member['name'] : 'Member ${memberIdx + 1}'}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addProductToMember(memberIdx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ),

          // Products List
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Member Total:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                ),
                Text(
                  '₹ ${member['member_total'] ?? '0.00'}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...List.generate(_familyMembersWithProducts.length, (index) => _buildFamilyMemberCard(index)),
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
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      Flexible(
                        child: Text(
                          '₹ $_totalAmount',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            _isEditMode ? 'Update KYC' : 'Save KYC',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
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
//       print("Error loading dropdown data: $e");
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
//       print("Submit Error: $e");
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
//             CircularProgressIndicator(),
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