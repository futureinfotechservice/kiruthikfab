import 'package:flutter/material.dart';
import 'package:kiruthikfab/models/inward_entry_model.dart';
import 'package:kiruthikfab/screens/entry/widgets.dart';
import 'package:kiruthikfab/services/inventory_api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../indigator/main.dart';
import '../../widgets/customdropdownwidget.dart';
import '../navigation_provider.dart';
import 'inward_entry_list_page.dart';

class InwardEntryPage extends StatefulWidget {
  const InwardEntryPage({super.key});

  @override
  State<InwardEntryPage> createState() => _InwardEntryPageState();
}

class _InwardEntryPageState extends State<InwardEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _inwardService = InventoryApiService();

  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();

  bool _isSubmitting = false;
  String _companyId = '';
  String _userId = '';
  List<InventoriesNo> _inventoriesNumbers = [];
  InventoriesNo? _selectedInventory;
  List<InwardEntry> _inwards = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> _loadInventoriesNumbers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyid') ?? '';
    if (companyId.isNotEmpty) {
      final numbers = await _inwardService.fetchInventoriesNumbers(companyId);
      if (mounted) {
        setState(() {
          _inventoriesNumbers = numbers;
        });
      }
    }
  }

  Future<void> fetchInventoryId(String id) async {
    if (_companyId.isNotEmpty && id.isNotEmpty) {
      try {
        final entries = await _inwardService.fetchInventoryById(_companyId, id);
        setState(() {
          _inwards = entries;
        });
      } catch (e) {
        setState(() {
          _inwards = [];
        });
      }
    }
  }

  Future<void> initData() async {
    await Future.wait([_loadUserData(), _loadInventoriesNumbers()]);
  }

  @override
  void dispose() {
    _stockController.dispose();
    _amountController.dispose();
    _manufacturerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getString('companyid') ?? '';
      _userId = prefs.getString('id') ?? '';
    });
  }

  Future<void> _submitInwardEntry() async {
    if (!_formKey.currentState!.validate()) return;

    if (_companyId.isEmpty) {
      _showSnackBar('Company ID not found. Please login again.', Colors.red);
      return;
    }

    if (_selectedInventory == null) {
      _showSnackBar('Please select an inventory item', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final entry = InwardEntry(
        companyId: _companyId,
        inventoryId: _selectedInventory!.id,

        stock: _stockController.text.trim(),
        amount: _amountController.text.trim(),
        addedBy: _userId,
        manufacturer: _manufacturerController.text.trim(),
        productName: '',
        modelName: '',
        sizeName: '',
        unitName: '',
        inventoryNumber: '',
      );

      final response = await _inwardService.createInwardEntry(entry);

      if (response['status'] == 'success') {
        _showSnackBar(
          response['message'] ?? 'Inward entry added successfully!',
          Colors.green,
        );

        // Refresh the inward entries list
        await fetchInventoryId(_selectedInventory!.id);
        _clearForm();
      } else {
        _showSnackBar(
          response['message'] ?? 'Failed to add inward entry',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedInventory = null;
      _inwards = [];
      _stockController.clear();
      _amountController.clear();
      _manufacturerController.clear();
    });
    _formKey.currentState?.reset();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        leading: IconButton(
          onPressed: () {
            navProvider.updateIndex(
              selectedIndex: 0,
              reportSubIndex: 0,
              masterSubIndex: 0,
              entrySubIndex: 0,
            );
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Add Inward Entry',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 2,

        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              // Navigate to inward entries list
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InwardEntriesListPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'New Inward Entry',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Add stock inward to inventory',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      CustomDropdownSearch(
                        items: _inventoriesNumbers
                            .map(
                              (item) =>
                                  '${item.inventoryId} • ${item.productName} • ${item.modelName} • ${item.unitName} • ${item.sizeName}',
                            )
                            .toList(),
                        label: 'Select Inventory ',
                        isRequired: true,
                        selectedItem: _selectedInventory?.inventoryId ?? '',
                        onChanged: (value) {
                          setState(() {
                            _selectedInventory = _inventoriesNumbers.firstWhere(
                              (item) =>
                                  '${item.inventoryId} • ${item.productName} • ${item.modelName} • ${item.unitName} • ${item.sizeName}' ==
                                  value,
                            );
                          });
                          fetchInventoryId(_selectedInventory?.id ?? "");
                        },
                      ),
                      const SizedBox(height: 16),

                      // Manufacturer Field
                      buildTextField(
                        controller: _manufacturerController,
                        label: 'Manufacturer',
                        hint: 'Enter manufacturer name',
                        icon: Icons.factory,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter manufacturer name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Stock Field
                      buildTextField(
                        controller: _stockController,
                        label: 'Stock Quantity',
                        hint: 'Enter stock quantity',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter stock quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Amount Field
                      buildTextField(
                        controller: _amountController,
                        label: 'Amount',
                        hint: 'Enter amount',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitInwardEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const CircularWaveProgress()
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Inward Entry',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Clear Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _clearForm,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Clear All'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedInventory != null && _inwards.isNotEmpty)
              InwardListView(inward: _inwards, isFull: false),
          ],
        ),
      ),
    );
  }
}
