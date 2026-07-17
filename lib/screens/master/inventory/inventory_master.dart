import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/services/config.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../indigator/main.dart';
import '../../../services/inventory_api_service.dart';
import '../../../services/invoice_apiservice.dart';
import '../../../widgets/customdropdownwidget.dart';
import '../../navigation_provider.dart';
import 'collapsible_product_group.dart';

class InventoryMaster extends StatefulWidget {
  const InventoryMaster({super.key});

  @override
  State<InventoryMaster> createState() => _InventoryMasterState();
}

class _InventoryMasterState extends State<InventoryMaster> {
  List<InventoryItem> inventoryItems = [];
  List<InventoryItem> filteredInventoryItems = [];

  String? _selectedProduct;

  List<String> _selectedModels = [];
  List<String> _selectedUnits = [];
  List<String> _selectedSizes = [];

  final TextEditingController _openingStockController = TextEditingController();

  List<Product> productList = [];
  List<Model> modelList = [];
  List<ProductSize> sizeList = [];
  List<Unit> unitList = [];

  List<Model> filteredModels = [];
  List<ProductSize> filteredSizes = [];
  List<Unit> filteredUnits = [];

  Set<String> usedModelIds = {};
  Set<String> usedSizeIds = {};
  Set<String> usedUnitIds = {};

  Set<String> existingCombinations = {};

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isFetchingInventories = false;
  String inventoryNo = '';
  int _currentSequenceNumber = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Future<void> fetchInventoryNo() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final companyId = prefs.getString('companyid') ?? '';
  //   inventoryNo = await InventoryApiService().getNextInventoryNumber(
  //     context,
  //     companyId,
  //   );
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }
  Future<void> fetchInventoryNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyid') ?? '';

    try {
      inventoryNo = await InventoryApiService().getNextInventoryNumber(
        context,
        companyId,
      );

      if (inventoryNo.isNotEmpty) {
        final parts = inventoryNo.split('-');
        if (parts.length == 3) {
          _currentSequenceNumber = int.tryParse(parts[2]) ?? 0;
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error fetching inventory number: $e');
      final year = DateTime.now().year;
      inventoryNo = 'KI-$year-0001';
      _currentSequenceNumber = 1;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _buildExistingCombinations() {
    existingCombinations.clear();
    usedModelIds.clear();
    usedSizeIds.clear();
    usedUnitIds.clear();

    for (var item in inventoryItems) {
      final key =
          '${item.productId}_${item.modelId}_${item.sizeId}_${item.unitId}';
      existingCombinations.add(key);

      // Track used IDs for this product
      usedModelIds.add(item.modelId);
      usedSizeIds.add(item.sizeId);
      usedUnitIds.add(item.unitId);
    }
  }

  void _filterDropdowns() {
    if (_selectedProduct == null) {
      setState(() {
        filteredModels = [];
        filteredSizes = [];
        filteredUnits = [];
        _selectedModels = [];
        _selectedUnits = [];
        _selectedSizes = [];
        usedModelIds.clear();
        usedSizeIds.clear();
        usedUnitIds.clear();
      });
      return;
    }

    final selectedProductId = productList
        .firstWhere((item) => item.productName == _selectedProduct)
        .id;

    // Get existing combinations for this product
    final existingForProduct = inventoryItems
        .where((item) => item.productId == selectedProductId)
        .toList();

    // Build a set of all existing combinations for this product
    final existingCombosForProduct = <String>{};
    for (var item in existingForProduct) {
      final comboKey = '${item.modelId}_${item.sizeId}_${item.unitId}';
      existingCombosForProduct.add(comboKey);
    }

    // For each model, check which combinations are missing
    final modelsWithAvailableCombos = <Model>[];
    final sizesWithAvailableCombos = <ProductSize>[];
    final unitsWithAvailableCombos = <Unit>[];

    // Check each model
    for (var model in modelList) {
      bool hasAvailableCombo = false;
      // Check if this model has any missing combination with any size and unit
      for (var size in sizeList) {
        for (var unit in unitList) {
          final comboKey = '${model.id}_${size.id}_${unit.id}';
          if (!existingCombosForProduct.contains(comboKey)) {
            hasAvailableCombo = true;
            break;
          }
        }
        if (hasAvailableCombo) break;
      }
      if (hasAvailableCombo) {
        modelsWithAvailableCombos.add(model);
      }
    }

    // Check each size
    for (var size in sizeList) {
      bool hasAvailableCombo = false;
      for (var model in modelList) {
        for (var unit in unitList) {
          final comboKey = '${model.id}_${size.id}_${unit.id}';
          if (!existingCombosForProduct.contains(comboKey)) {
            hasAvailableCombo = true;
            break;
          }
        }
        if (hasAvailableCombo) break;
      }
      if (hasAvailableCombo) {
        sizesWithAvailableCombos.add(size);
      }
    }

    // Check each unit
    for (var unit in unitList) {
      bool hasAvailableCombo = false;
      for (var model in modelList) {
        for (var size in sizeList) {
          final comboKey = '${model.id}_${size.id}_${unit.id}';
          if (!existingCombosForProduct.contains(comboKey)) {
            hasAvailableCombo = true;
            break;
          }
        }
        if (hasAvailableCombo) break;
      }
      if (hasAvailableCombo) {
        unitsWithAvailableCombos.add(unit);
      }
    }

    setState(() {
      // Show only models that have available combinations
      filteredModels = modelsWithAvailableCombos;

      // Show only sizes that have available combinations
      filteredSizes = sizesWithAvailableCombos;

      // Show only units that have available combinations
      filteredUnits = unitsWithAvailableCombos;

      // Clear selections
      _selectedModels = [];
      _selectedUnits = [];
      _selectedSizes = [];
    });
  }

  List<Map<String, String>> _getAvailableCombinations() {
    if (_selectedProduct == null ||
        _selectedModels.isEmpty ||
        _selectedUnits.isEmpty ||
        _selectedSizes.isEmpty) {
      return [];
    }

    final selectedProductId = productList
        .firstWhere((item) => item.productName == _selectedProduct)
        .id;

    // Get existing combinations for this product
    final existingForProduct = inventoryItems
        .where((item) => item.productId == selectedProductId)
        .toList();

    // Build set of existing combinations
    final existingCombosForProduct = <String>{};
    for (var item in existingForProduct) {
      final comboKey = '${item.modelId}_${item.sizeId}_${item.unitId}';
      existingCombosForProduct.add(comboKey);
    }

    final availableCombinations = <Map<String, String>>[];

    // Check all combinations of selected models, units, and sizes
    for (var modelName in _selectedModels) {
      final modelId = modelList
          .firstWhere((item) => item.modelName == modelName)
          .id;

      for (var unitName in _selectedUnits) {
        final unitId = unitList
            .firstWhere((item) => item.unitName == unitName)
            .id;

        for (var sizeName in _selectedSizes) {
          final sizeId = sizeList
              .firstWhere((item) => item.sizeName == sizeName)
              .id;

          final comboKey = '${modelId}_${sizeId}_$unitId';

          if (!existingCombosForProduct.contains(comboKey)) {
            availableCombinations.add({
              'model': modelName,
              'unit': unitName,
              'size': sizeName,
            });
          }
        }
      }
    }

    return availableCombinations;
  }

  void _addAllCombinationsToList() {
    if (_selectedProduct == null) {
      _showSnackBar('Please select a product', Colors.orange);
      return;
    }

    if (_selectedModels.isEmpty) {
      _showSnackBar('Please select at least one model', Colors.orange);
      return;
    }

    if (_selectedUnits.isEmpty) {
      _showSnackBar('Please select at least one unit', Colors.orange);
      return;
    }

    if (_selectedSizes.isEmpty) {
      _showSnackBar('Please select at least one size', Colors.orange);
      return;
    }

    if (_openingStockController.text.isEmpty) {
      _showSnackBar('Please enter opening stock', Colors.orange);
      return;
    }

    final stock = int.tryParse(_openingStockController.text);
    if (stock == null || stock < 0) {
      _showSnackBar('Please enter a valid stock number', Colors.orange);
      return;
    }

    // Get only available combinations (not existing)
    final availableCombinations = _getAvailableCombinations();

    if (availableCombinations.isEmpty) {
      _showSnackBar(
        'All selected combinations already exist in inventory!\nTry selecting different options.',
        Colors.orange,
      );
      return;
    }

    final productId = productList
        .firstWhere((item) => item.productName == _selectedProduct)
        .id;

    int addedCount = 0;

    // Get the current sequence number
    // The current inventoryNo already has the next available number
    // Extract the base part and the current sequence
    final parts = inventoryNo.split('-');
    final baseInventoryNo = '${parts[0]}-${parts[1]}-'; // "KI-2026-"
    int currentSequence = int.parse(parts[2]); // e.g., 1

    for (var combo in availableCombinations) {
      final modelName = combo['model']!;
      final unitName = combo['unit']!;
      final sizeName = combo['size']!;

      final modelId = modelList
          .firstWhere((item) => item.modelName == modelName)
          .id;
      final unitId = unitList
          .firstWhere((item) => item.unitName == unitName)
          .id;
      final sizeId = sizeList
          .firstWhere((item) => item.sizeName == sizeName)
          .id;

      // Use currentSequence + addedCount for each item
      // For first item: currentSequence (e.g., 1)
      // For second item: currentSequence + 1 (e.g., 2)
      final inventoryNumber = (currentSequence + addedCount).toString().padLeft(
        4,
        '0',
      );
      final inventoryId = '$baseInventoryNo$inventoryNumber';

      setState(() {
        final newItem = InventoryItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}_$addedCount',
          productId: productId,
          productName: _selectedProduct!,
          modelId: modelId,
          modelName: modelName,
          unitId: unitId,
          unitName: unitName,
          sizeId: sizeId,
          sizeName: sizeName,
          openingStock: stock,
          companyid: '',
          addedby: '',
          updatedby: '',
          createdAt: DateTime.now().toString(),
          updatedAt: DateTime.now().toString(),
          activestatus: '1',
          inventoryid: inventoryId, // Set inventory ID
        );

        inventoryItems.add(newItem);
        filteredInventoryItems.add(newItem);
        addedCount++;
      });
    }

    // Update the sequence number for next time
    setState(() {
      _currentSequenceNumber = currentSequence + addedCount;
      // Update the displayed inventory number for next batch
      final year = DateTime.now().year;
      inventoryNo =
          'KI-$year-${_currentSequenceNumber.toString().padLeft(4, '0')}';
    });

    // Rebuild existing combinations after adding
    _buildExistingCombinations();

    // Show summary message with inventory ID range
    final firstInventoryId =
        '$baseInventoryNo${currentSequence.toString().padLeft(4, '0')}';
    final lastInventoryId =
        '$baseInventoryNo${(currentSequence + addedCount - 1).toString().padLeft(4, '0')}';

    _showSnackBar(
      'Successfully added $addedCount new combinations!\nInventory IDs: $firstInventoryId - $lastInventoryId',
      Colors.green,
    );

    // Reset selections after adding
    setState(() {
      _selectedModels = [];
      _selectedUnits = [];
      _selectedSizes = [];
      _openingStockController.clear();
      // Refresh filtered lists
      _filterDropdowns();
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = filteredInventoryItems[index];
      filteredInventoryItems.removeAt(index);
      inventoryItems.removeWhere((i) => i.id == item.id);
      _buildExistingCombinations();
    });
  }

  // Future<void> _submitInventoryItems() async {
  //   if (filteredInventoryItems.isEmpty) {
  //     _showSnackBar('Please add at least one inventory item', Colors.orange);
  //     return;
  //   }
  //
  //   // Get only new items (with temp IDs)
  //   final newItems = filteredInventoryItems
  //       .where((item) => item.id.startsWith('temp_'))
  //       .toList();
  //
  //   if (newItems.isEmpty) {
  //     _showSnackBar('No new items to submit', Colors.orange);
  //     return;
  //   }
  //
  //   setState(() => _isSubmitting = true);
  //
  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final companyid = prefs.getString('companyid') ?? '';
  //     final userid = prefs.getString('id') ?? '';
  //
  //     if (companyid.isEmpty || userid.isEmpty) {
  //       _showSnackBar('Company ID or User ID not found', Colors.red);
  //       setState(() => _isSubmitting = false);
  //       return;
  //     }
  //
  //     final itemsData = newItems
  //         .map(
  //           (item) => {
  //             'companyid': companyid,
  //             'productid': item.productId,
  //             'modelid': item.modelId,
  //             'unitid': item.unitId,
  //             'sizeid': item.sizeId,
  //             'addedby': userid,
  //             'opening_stock': item.openingStock.toString(),
  //           },
  //         )
  //         .toList();
  //
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/inventory_insert_multiple.php'),
  //       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  //       body: {'items': jsonEncode(itemsData)},
  //     );
  //
  //     if (response.statusCode == 200) {
  //       try {
  //         final data = jsonDecode(response.body);
  //         if (data['status'] == 'success') {
  //           _showSnackBar(
  //             '${data['message'] ?? "Inventory items added successfully!"}',
  //             Colors.green,
  //           );
  //           await fetchInventoryItems(); // Refresh inventory
  //           _clearNewItems();
  //         } else {
  //           _showSnackBar('Error: ${data['message']}', Colors.red);
  //         }
  //       } catch (e) {
  //         _showSnackBar('Invalid response from server', Colors.red);
  //       }
  //     } else {
  //       _showSnackBar('Server error. Please try again.', Colors.red);
  //     }
  //   } catch (e) {
  //     _showSnackBar('Error: $e', Colors.red);
  //   } finally {
  //     setState(() => _isSubmitting = false);
  //   }
  // }
  Future<void> _submitInventoryItems() async {
    if (filteredInventoryItems.isEmpty) {
      _showSnackBar('Please add at least one inventory item', Colors.orange);
      return;
    }

    // Get only new items (with temp IDs)
    final newItems = filteredInventoryItems
        .where((item) => item.id.startsWith('temp_'))
        .toList();

    if (newItems.isEmpty) {
      _showSnackBar('No new items to submit', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';
      final userid = prefs.getString('id') ?? '';

      if (companyid.isEmpty || userid.isEmpty) {
        _showSnackBar('Company ID or User ID not found', Colors.red);
        setState(() => _isSubmitting = false);
        return;
      }

      // Prepare data with existing inventory IDs
      final itemsData = newItems.map((item) {
        return {
          'companyid': companyid,
          'productid': item.productId,
          'modelid': item.modelId,
          'unitid': item.unitId,
          'sizeid': item.sizeId,
          'addedby': userid,
          'opening_stock': item.openingStock.toString(),
          'inventoryid': item.inventoryid, // Use the pre-generated inventory ID
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/inventory_insert_multiple.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'items': jsonEncode(itemsData)},
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            _showSnackBar(
              '${data['message'] ?? "Inventory items added successfully!"}',
              Colors.green,
            );

            await fetchInventoryItems(); // Refresh inventory
            _clearNewItems();
          } else {
            _showSnackBar('Error: ${data['message']}', Colors.red);
          }
        } catch (e) {
          _showSnackBar('Invalid response from server', Colors.red);
        }
      } else {
        _showSnackBar('Server error. Please try again.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearNewItems() {
    setState(() {
      filteredInventoryItems.removeWhere((item) => item.id.startsWith('temp_'));
      inventoryItems.removeWhere((item) => item.id.startsWith('temp_'));
      _buildExistingCombinations();
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 4, overflow: TextOverflow.ellipsis),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text(
          'Inventory Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularWaveProgress())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddItemCard(),
                  const SizedBox(height: 20),
                  _buildInventoryList(),
                ],
              ),
            ),
    );
  }

  List<Map<String, String>> _generateAllCombinations() {
    if (_selectedProduct == null ||
        _selectedModels.isEmpty ||
        _selectedUnits.isEmpty ||
        _selectedSizes.isEmpty) {
      return [];
    }

    final allCombinations = <Map<String, String>>[];
    for (var model in _selectedModels) {
      for (var unit in _selectedUnits) {
        for (var size in _selectedSizes) {
          allCombinations.add({'model': model, 'unit': unit, 'size': size});
        }
      }
    }
    return allCombinations;
  }

  Widget _buildAddItemCard() {
    // Get ONLY available combinations (not existing ones)
    final availableCombinations = _getAvailableCombinations();
    final previewCount = availableCombinations.length;

    // Check if any combinations exist but all are already in inventory
    bool allCombinationsExist = false;
    if (_selectedProduct != null &&
        _selectedModels.isNotEmpty &&
        _selectedUnits.isNotEmpty &&
        _selectedSizes.isNotEmpty) {
      final allCombinations = _generateAllCombinations();
      if (allCombinations.isNotEmpty && previewCount == 0) {
        allCombinationsExist = true;
      }
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Inventory Combinations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (filteredInventoryItems
                          .where((item) => item.id.startsWith('temp_'))
                          .isNotEmpty)
                        Text(
                          '${filteredInventoryItems.where((item) => item.id.startsWith('temp_')).length} items pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredInventoryItems.where((item) => item.id.startsWith('temp_')).length} new',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Form Fields - Responsive Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final isTablet =
                    constraints.maxWidth >= 600 && constraints.maxWidth < 900;
                final columns = isMobile ? 1 : (isTablet ? 2 : 3);
                final spacing = isMobile ? 12.0 : 16.0;

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'Starting Inventory Number',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 45,
                              width: 150,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: Text(inventoryNo)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(bottom: spacing),
                            child: _buildResponsiveWidget(
                              constraints,
                              CustomDropdownSearch(
                                items: productList
                                    .map((item) => item.productName)
                                    .toList(),
                                label: 'Select Product ',
                                isRequired: true,
                                selectedItem: _selectedProduct,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProduct = value;
                                    _filterDropdowns();
                                  });
                                },
                              ),
                              fullWidth: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Model, Unit, Size - Grid
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _buildResponsiveWidget(
                          constraints,
                          _buildMultiSelectDropdown(
                            items: filteredModels
                                .map((m) => m.modelName)
                                .toList(),
                            selectedItems: _selectedModels,
                            label: 'Select Models ',
                            hint: 'Select one or more models',
                            onChanged: (value) {
                              setState(() {
                                if (_selectedModels.contains(value)) {
                                  _selectedModels.remove(value);
                                } else {
                                  _selectedModels.add(value);
                                }
                              });
                            },
                            isEnabled:
                                _selectedProduct != null &&
                                filteredModels.isNotEmpty,
                          ),
                          flex: columns,
                        ),
                        _buildResponsiveWidget(
                          constraints,
                          _buildMultiSelectDropdown(
                            items: filteredUnits
                                .map((u) => u.unitName)
                                .toList(),
                            selectedItems: _selectedUnits,
                            label: 'Select Units ',
                            hint: 'Select one or more units',
                            onChanged: (value) {
                              setState(() {
                                if (_selectedUnits.contains(value)) {
                                  _selectedUnits.remove(value);
                                } else {
                                  _selectedUnits.add(value);
                                }
                              });
                            },
                            isEnabled:
                                _selectedProduct != null &&
                                filteredUnits.isNotEmpty,
                          ),
                          flex: columns,
                        ),
                        _buildResponsiveWidget(
                          constraints,
                          _buildMultiSelectDropdown(
                            items: filteredSizes
                                .map((s) => s.sizeName)
                                .toList(),
                            selectedItems: _selectedSizes,
                            label: 'Select Sizes ',
                            hint: 'Select one or more sizes',
                            onChanged: (value) {
                              setState(() {
                                if (_selectedSizes.contains(value)) {
                                  _selectedSizes.remove(value);
                                } else {
                                  _selectedSizes.add(value);
                                }
                              });
                            },
                            isEnabled:
                                _selectedProduct != null &&
                                filteredSizes.isNotEmpty,
                          ),
                          flex: columns,
                        ),
                      ],
                    ),

                    SizedBox(height: spacing),

                    // Stock and Action Buttons
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stock Input - 30% width
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _openingStockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Opening Stock ',
                              hintText: 'Enter quantity',
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Action Buttons - 70% width
                        Expanded(
                          flex: 7,
                          child: _buildActionButtons(
                            previewCount,
                            allCombinationsExist,
                            isMobile,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    int previewCount,
    bool allCombinationsExist,
    bool isMobile,
  ) {
    if (previewCount > 0) {
      return Column(
        children: [
          // Preview badge with animation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$previewCount new combination${previewCount > 1 ? 's' : ''} available',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addAllCombinationsToList,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                isMobile ? 'Add All' : 'Add All ($previewCount) Combinations',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      );
    } else if (_selectedProduct != null &&
        _selectedModels.isNotEmpty &&
        _selectedUnits.isNotEmpty &&
        _selectedSizes.isNotEmpty) {
      // All combinations exist
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'All combinations already exist!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.block, size: 18),
              label: const Text('No New Combinations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // No selection
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.info, size: 18),
          label: const Text('Select options to continue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildResponsiveWidget(
    BoxConstraints constraints,
    Widget child, {
    int flex = 1,
    bool fullWidth = false,
  }) {
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: child);
    }

    final isMobile = constraints.maxWidth < 600;
    final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

    double width;
    if (isMobile) {
      width = constraints.maxWidth - 32;
    } else if (isTablet) {
      width = (constraints.maxWidth - 48) / 2;
    } else {
      width = (constraints.maxWidth - 64) / 3;
    }

    return SizedBox(width: width, child: child);
  }

  Widget _buildMultiSelectDropdown({
    required List<String> items,
    required List<String> selectedItems,
    required String label,
    required String hint,
    required Function(String) onChanged,
    required bool isEnabled,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled ? Colors.blue.shade200 : Colors.grey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: isEnabled
                      ? Colors.blue.shade700
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                ' ',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              if (!isEnabled) ...[
                const SizedBox(width: 8),
                Text(
                  '(No available)',
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          if (selectedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isEnabled && items.isNotEmpty ? hint : 'No options available',
                style: TextStyle(
                  color: isEnabled && items.isNotEmpty
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            )
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: selectedItems.map((item) {
                return Chip(
                  label: Text(
                    item,
                    style: TextStyle(fontSize: isMobile ? 11 : 12),
                  ),
                  deleteIcon: Icon(Icons.close, size: isMobile ? 14 : 16),
                  onDeleted: isEnabled ? () => onChanged(item) : null,
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.blue.shade700,
                  ),
                  side: BorderSide(color: Colors.blue.shade200),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          if (isEnabled && items.isNotEmpty)
            InkWell(
              onTap: () {
                _showMultiSelectDialog(
                  items: items,
                  selectedItems: selectedItems,
                  onChanged: onChanged,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: isMobile ? 14 : 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add/Remove',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: isMobile ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMultiSelectDialog({
    required List<String> items,
    required List<String> selectedItems,
    required Function(String) onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedItems);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                'Select ${items.isNotEmpty ? items[0].runtimeType.toString() : 'Items'}',
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = tempSelected.contains(item);
                    return CheckboxListTile(
                      title: Text(item),
                      value: isSelected,
                      onChanged: (selected) {
                        setStateDialog(() {
                          if (selected!) {
                            tempSelected.add(item);
                          } else {
                            tempSelected.remove(item);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setStateDialog(() {
                      tempSelected.clear();
                    });
                  },
                  child: const Text('Clear All'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply selections
                    final toRemove = selectedItems
                        .where((item) => !tempSelected.contains(item))
                        .toList();
                    for (var item in toRemove) {
                      onChanged(item);
                    }
                    final toAdd = tempSelected
                        .where((item) => !selectedItems.contains(item))
                        .toList();
                    for (var item in toAdd) {
                      onChanged(item);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryList() {
    if (_isFetchingInventories) {
      return const Center(child: CircularWaveProgress());
    }

    if (filteredInventoryItems.isEmpty) {
      return Center(
        child: Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.inventory, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No Inventory Items Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add inventory items using the form above',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Separate new and existing items
    final newItems = filteredInventoryItems
        .where((item) => item.id.startsWith('temp_'))
        .toList();
    final existingItems = filteredInventoryItems
        .where((item) => !item.id.startsWith('temp_'))
        .toList();

    return Card(
      color: Colors.blue.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Inventory Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredInventoryItems.length} total',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                if (newItems.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${newItems.length} new',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                    ),
                    label: Text('Submit new items'),
                    icon: Icon(
                      Icons.cloud_upload,
                      color: Colors.green.shade700,
                    ),
                    onPressed: _isSubmitting ? null : _submitInventoryItems,
                    // tooltip: 'Submit new items',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            if (existingItems.isNotEmpty) ...[
              const Text(
                'Existing Items',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildCollapsibleItemList(existingItems, isNew: false),
              const SizedBox(height: 16),
            ],

            if (newItems.isNotEmpty) ...[
              const Text(
                'New Items (Pending Submission)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildCollapsibleItemList(newItems, isNew: true),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCollapsibleItemList(
    List<InventoryItem> items, {
    required bool isNew,
  }) {
    // Group items by product
    final Map<String, List<InventoryItem>> groupedItems = {};
    for (var item in items) {
      final key = item.productName;
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = [];
      }
      groupedItems[key]!.add(item);
    }

    List<Widget> widgets = [];
    groupedItems.forEach((product, productItems) {
      widgets.add(
        CollapsibleProductGroup(
          key: ValueKey('${product}_${isNew ? 'new' : 'existing'}'),
          productName: product,
          items: productItems,
          isNew: isNew,
          onRemoveItem: (item) {
            _removeItem(filteredInventoryItems.indexOf(item));
          },
          init: _loadInitialData,
        ),
      );
    });

    return widgets;
  }

  @override
  void dispose() {
    _openingStockController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        loadProducts(),
        loadModels(),
        loadSizes(),
        loadUnits(),
        fetchInventoryItems(),
        fetchInventoryNo(),
      ]);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading data: $e', Colors.red);
      }
    }
  }

  Future<void> loadProducts() async {
    try {
      productList = await invoiceApiService().getProducts(context);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showSnackBar('Error loading products: $e', Colors.red);
    }
  }

  Future<void> loadModels() async {
    try {
      modelList = await invoiceApiService().getModels(context);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showSnackBar('Error loading models: $e', Colors.red);
    }
  }

  Future<void> loadSizes() async {
    try {
      sizeList = await invoiceApiService().getSizes(context);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showSnackBar('Error loading sizes: $e', Colors.red);
    }
  }

  Future<void> loadUnits() async {
    try {
      unitList = await invoiceApiService().getUnits(context);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showSnackBar('Error loading units: $e', Colors.red);
    }
  }

  Future<void> fetchInventoryItems() async {
    if (mounted) {
      setState(() => _isFetchingInventories = true);
    }
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      if (companyid.isEmpty) {
        _showSnackBar('Company ID not found', Colors.orange);
        if (mounted) {
          setState(() => _isFetchingInventories = false);
        }
        return;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/inventory_fetch_all.php'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'companyid': companyid},
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
                _buildExistingCombinations();
              });
            }
          } else if (data is Map && data['error'] != null) {
            _showSnackBar('Error: ${data['error']}', Colors.red);
          }
        } catch (e) {
          _showSnackBar('Error parsing inventory data', Colors.red);
        }
      } else {
        _showSnackBar('Failed to fetch inventory items', Colors.red);
      }
    } catch (e) {
      print(e);
      _showSnackBar('Error fetching inventory: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isFetchingInventories = false);
      }
    }
  }
}

class InventoryItem {
  final String id;
  final String companyid;
  final String inventoryid;
  final String productId;
  final String productName;
  final String modelId;
  final String modelName;
  final String unitId;
  final String unitName;
  final String sizeId;
  final String sizeName;
  final int openingStock;
  final String addedby;
  final String updatedby;
  final String createdAt;
  final String updatedAt;
  final String activestatus;

  InventoryItem({
    required this.id,
    required this.companyid,
    required this.productId,
    required this.productName,
    required this.modelId,
    required this.modelName,
    required this.unitId,
    required this.unitName,
    required this.sizeId,
    required this.sizeName,
    required this.openingStock,
    required this.addedby,
    required this.updatedby,
    required this.createdAt,
    required this.updatedAt,
    required this.activestatus,
    required this.inventoryid,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid'] ?? '',
      inventoryid: json['inventoryid'] ?? '',
      productId: json['productid']?.toString() ?? '',
      productName: json['productname'] ?? '',
      modelId: json['modelid']?.toString() ?? '',
      modelName: json['modelname'] ?? '',
      unitId: json['unitid']?.toString() ?? '',
      unitName: json['unitname'] ?? '',
      sizeId: json['sizeid']?.toString() ?? '',
      sizeName: json['sizename'] ?? '',
      openingStock: int.tryParse(json['opening_stock']?.toString() ?? '0') ?? 0,
      addedby: json['addedby'] ?? '',
      updatedby: json['updatedby'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toString(),
      updatedAt: json['updated_at'] ?? DateTime.now().toString(),
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }
}
