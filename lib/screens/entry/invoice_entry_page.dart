import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../widgets/customappbarwidget.dart';
import '../../../../../widgets/customdropdownwidget.dart';
import '../../../../../widgets/customtextfield.dart';
import '../../../services/invoice_apiservice.dart';
import '../../../services/kyc_apiservice.dart';
import '../../models/delivery_partner_master_model.dart';
import '../../services/config.dart';
import '../../services/delivery_partner_api_service.dart';
import '../master/inventory/inventory_master.dart';
import 'invoice_print_view.dart';

class InvoiceEntryPage extends StatefulWidget {
  final dynamic invoice;
  final bool isViewMode;

  const InvoiceEntryPage({super.key, this.invoice, this.isViewMode = false});

  @override
  State<InvoiceEntryPage> createState() => _InvoiceEntryPageState();
}

class _InvoiceEntryPageState extends State<InvoiceEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _invoiceItems = [];
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _packingAmountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _gstNoController = TextEditingController();

  String _subtotal = '0.00';
  String _taxAmount = '0.00';
  String _grandTotal = '0.00';

  double _taxPercentage = 5.0;

  List<Map<String, dynamic>> customerList = [];
  List<Product> productlist = [];
  List<Model> modellist = [];
  List<ProductSize> sizelist = [];
  List<Unit> unitlist = [];

  final _billNoController = TextEditingController();
  final _billDateController = TextEditingController(
    text: DateFormat("dd/MM/yyyy").format(DateTime.now()),
  );

  String? selectedCustomer;
  String? customerId;

  List<String?> selectedProducts = [];
  List<String?> selectedModels = [];
  List<String?> selectedSizes = [];
  List<String?> selectedUnits = [];

  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _rateControllers = [];

  final List<FocusNode> _quantityFocusNodes = [];

  final FocusNode _customerFocusNode = FocusNode();

  final List<GlobalKey<DropdownSearchState<String>>> _productDropdownKeys = [];
  final List<GlobalKey<DropdownSearchState<String>>> _modelDropdownKeys = [];
  final List<GlobalKey<DropdownSearchState<String>>> _sizeDropdownKeys = [];
  final List<GlobalKey<DropdownSearchState<String>>> _unitDropdownKeys = [];
  List<DeliveryPartnerMasterModel> deliveryPartners = [];
  DeliveryPartnerMasterModel? selectedDeliveryPartner;
  List<InventoryItem> inventoryItems = [];
  List<InventoryItem> filteredInventoryItems = [];

  final Map<int, List<InventoryItem>> _cachedInventoryCombinations = {};

  bool get isEditMode => widget.invoice != null && !widget.isViewMode;

  bool get isViewMode {
    if (widget.isViewMode) return true;
    if (widget.invoice is Map) {
      return (widget.invoice as Map)['isViewMode'] == true;
    }
    return false;
  }

  InvoiceModel? get actualInvoice {
    if (widget.invoice is InvoiceModel) return widget.invoice;
    if (widget.invoice is Map) return (widget.invoice as Map)['invoice'];
    return null;
  }

  Future<void> loadInvoiceNumber() async {
    if (isViewMode || isEditMode) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      String nextNo = '';
      if (mounted) {
        nextNo = await invoiceApiService().getNextInvoiceNumber(
          context,
          companyid,
        );
      }
      setState(() {
        _billNoController.text = nextNo.toString();
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> loadCustomers() async {
    customerList = await KYCApiService().fetchCustomers(context);
    setState(() {});
  }

  Future<void> loadProducts() async {
    productlist = await invoiceApiService().getProducts(context);
    setState(() {});
  }

  Future<void> loadModels() async {
    modellist = await invoiceApiService().getModels(context);
    setState(() {});
  }

  Future<void> loadSizes() async {
    sizelist = await invoiceApiService().getSizes(context);
    setState(() {});
  }

  Future<void> loadUnits() async {
    unitlist = await invoiceApiService().getUnits(context);
    setState(() {});
  }

  Future<void> loadDeliveryPartners() async {
    deliveryPartners = await DeliveryPartnerApiService().fetchDeliveryPartners(
      context,
    );
    setState(() {});
  }

  Future<void> fetchInventoryItems() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      if (companyid.isEmpty) {
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await Future.wait([
      loadCustomers(),
      loadProducts(),
      loadModels(),
      loadSizes(),
      loadUnits(),
      loadDeliveryPartners(),
      fetchInventoryItems(),
    ]);
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // usertype = prefs.getString('user_type') ?? '';

    if (isEditMode || isViewMode) {
      _prefillForm();
    } else {
      await loadInvoiceNumber();
      _addItem();

      // Request focus on customer dropdown after data is loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_customerFocusNode.canRequestFocus) {
          _customerFocusNode.requestFocus();
        }
      });
    }

    _calculateTotals();
  }

  List<InventoryItem> _getAvailableInventoryForProduct(String productId) {
    if (productId.isEmpty) return [];

    // Check cache first
    if (_cachedInventoryCombinations.containsKey(
      int.tryParse(productId) ?? 0,
    )) {
      return _cachedInventoryCombinations[int.tryParse(productId) ?? 0] ?? [];
    }

    final available = inventoryItems
        .where((item) => item.productId == productId)
        .toList();

    _cachedInventoryCombinations[int.tryParse(productId) ?? 0] = available;
    return available;
  }

  void _prefillForm() {
    final invoice = actualInvoice!;

    setState(() {
      _billNoController.text = invoice.invoiceNo;
      _billDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(DateFormat("yyyy-MM-dd").parse(invoice.date));

      selectedCustomer = invoice.customerName;
      customerId = invoice.customerId;

      _remarksController.text = invoice.remarks;
      _taxPercentage = double.tryParse(invoice.taxPercentage) ?? 5.0;
      _subtotal = invoice.subtotal;
      _grandTotal = invoice.grandTotal;
      _packingAmountController.text = invoice.packingAmount.toString();
      _gstNoController.text = invoice.gstNo.toString();
      if (invoice.deliveryPartner.isNotEmpty &&
          invoice.deliveryPartner != 'null') {
        selectedDeliveryPartner = deliveryPartners.firstWhere(
          (element) => element.id == invoice.deliveryPartner,
          orElse: () => DeliveryPartnerMasterModel(
            id: '',
            companyid: '',
            name: '',
            addedby: '',
            activestatus: '',
          ),
        );
      }
      _loadInvoiceDetails(invoice.id);
    });
  }

  Future<void> _loadInvoiceDetails(String invoiceId) async {
    try {
      final invoiceDetails = await invoiceApiService().getInvoiceDetails(
        context,
        invoiceId,
      );

      setState(() {
        _invoiceItems.clear();
        _quantityControllers.clear();
        _rateControllers.clear();
        _quantityFocusNodes.clear();
        _productDropdownKeys.clear();
        _modelDropdownKeys.clear();
        _sizeDropdownKeys.clear();
        _unitDropdownKeys.clear();
        selectedProducts.clear();
        selectedModels.clear();
        selectedSizes.clear();
        selectedUnits.clear();
        _filteredModelsForRow.clear();
        _filteredSizesForRow.clear();
        _filteredUnitsForRow.clear();

        for (var detail in invoiceDetails) {
          _invoiceItems.add({
            'productId': detail['productid']?.toString() ?? '0',
            'productName': detail['productname'] ?? '',
            'modelId': detail['modelid']?.toString() ?? '0',
            'modelName': detail['modelname'] ?? '',
            'sizeId': detail['sizeid']?.toString() ?? '0',
            'sizeName': detail['sizename'] ?? '',
            'unitId': detail['unitid']?.toString() ?? '0',
            'unitName': detail['unitname'] ?? '',
            'quantity': detail['quantity']?.toString() ?? '1',
            'rate': detail['rate']?.toString() ?? '0.00',
            'amount': detail['amount']?.toString() ?? '0.00',
          });

          _quantityControllers.add(
            TextEditingController(text: detail['quantity']?.toString() ?? '1'),
          );
          _rateControllers.add(
            TextEditingController(text: detail['rate']?.toString() ?? '0.00'),
          );

          _quantityFocusNodes.add(FocusNode());

          _productDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
          _modelDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
          _sizeDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
          _unitDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());

          selectedProducts.add(detail['productname'] ?? '');
          selectedModels.add(detail['modelname'] ?? '');
          selectedSizes.add(detail['sizename'] ?? '');
          selectedUnits.add(detail['unitname'] ?? '');

          // Initialize filtered lists
          _filteredModelsForRow.add([]);
          _filteredSizesForRow.add([]);
          _filteredUnitsForRow.add([]);
        }

        _calculateTotals();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load invoice details')),
        );
      }
    }
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _billDateController.dispose();
    _remarksController.dispose();
    _customerFocusNode.dispose();

    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _rateControllers) {
      controller.dispose();
    }
    for (var node in _quantityFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _calculateTotals() {
    double subtotal = 0;
    for (var item in _invoiceItems) {
      subtotal += double.tryParse(item['amount']) ?? 0;
    }

    // Calculate tax on subtotal (no discount)
    double tax =
        (subtotal * (_taxPercentage / 100)) +
        ((double.parse(_packingAmountController.text) * 5) / 100);
    int packagingAmount = int.parse(_packingAmountController.text.toString());
    double grandTotal = subtotal + tax + packagingAmount;

    setState(() {
      _subtotal = subtotal.toStringAsFixed(2);
      _taxAmount = tax.toStringAsFixed(2);
      _grandTotal = grandTotal.toStringAsFixed(2);
    });
  }

  void _addItem() {
    setState(() {
      _invoiceItems.add({
        'productId': '0',
        'productName': '',
        'modelId': '0',
        'modelName': '',
        'sizeId': '0',
        'sizeName': '',
        'unitId': '0',
        'unitName': '',
        'quantity': '1',
        'rate': '',
        'amount': '0.00',
      });

      _quantityControllers.add(TextEditingController(text: '1'));
      _rateControllers.add(TextEditingController());

      _quantityFocusNodes.add(FocusNode());

      _productDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
      _modelDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
      _sizeDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
      _unitDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());

      selectedProducts.add('');
      selectedModels.add('');
      selectedSizes.add('');
      selectedUnits.add('');

      // Initialize filtered lists
      _filteredModelsForRow.add([]);
      _filteredSizesForRow.add([]);
      _filteredUnitsForRow.add([]);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _quantityControllers[index].dispose();
      _rateControllers[index].dispose();
      _quantityFocusNodes[index].dispose();

      _invoiceItems.removeAt(index);
      _quantityControllers.removeAt(index);
      _rateControllers.removeAt(index);
      _quantityFocusNodes.removeAt(index);
      _productDropdownKeys.removeAt(index);
      _modelDropdownKeys.removeAt(index);
      _sizeDropdownKeys.removeAt(index);
      _unitDropdownKeys.removeAt(index);
      selectedProducts.removeAt(index);
      selectedModels.removeAt(index);
      selectedSizes.removeAt(index);
      selectedUnits.removeAt(index);

      // Remove filtered lists
      _filteredModelsForRow.removeAt(index);
      _filteredSizesForRow.removeAt(index);
      _filteredUnitsForRow.removeAt(index);

      _calculateTotals();
    });
  }

  void _updateItemAmount(int index) {
    // Get raw values without any formatting
    final quantityText = _quantityControllers[index].text.replaceAll(
      RegExp(r'[^\d.]'),
      '',
    );
    final rateText = _rateControllers[index].text.replaceAll(
      RegExp(r'[^\d.]'),
      '',
    );

    // Parse to double, default to 0 if empty or invalid
    final quantity = double.tryParse(quantityText) ?? 0;
    final rate = double.tryParse(rateText) ?? 0;

    // Calculate amount
    final amount = quantity * rate;

    // Update the item in the list
    setState(() {
      _invoiceItems[index]['quantity'] = quantity.toString();
      _invoiceItems[index]['rate'] = rate.toStringAsFixed(2);
      _invoiceItems[index]['amount'] = amount.toStringAsFixed(2);

      // Recalculate all totals
      _calculateTotals();
    });
  }

  void _onProductSelected(int index, String productName) {
    if (productName.isEmpty) return;

    final selected = productlist.firstWhere(
      (p) => p.productName == productName,
      orElse: () => Product(
        id: '0',
        productName: '',
        addedby: '',
        activestatus: '1',
        createdAt: '',
      ),
    );

    // Get available inventory combinations for this product
    final availableInventory = _getAvailableInventoryForProduct(selected.id);

    // Extract unique values
    final availableModels = availableInventory
        .map((item) => item.modelName)
        .toSet()
        .toList();
    final availableSizes = availableInventory
        .map((item) => item.sizeName)
        .toSet()
        .toList();
    final availableUnits = availableInventory
        .map((item) => item.unitName)
        .toSet()
        .toList();

    setState(() {
      _invoiceItems[index]['productId'] = selected.id;
      _invoiceItems[index]['productName'] = productName;
      selectedProducts[index] = productName;

      _invoiceItems[index]['modelId'] = '0';
      _invoiceItems[index]['modelName'] = '';
      _invoiceItems[index]['sizeId'] = '0';
      _invoiceItems[index]['sizeName'] = '';
      _invoiceItems[index]['unitId'] = '0';
      _invoiceItems[index]['unitName'] = '';
      selectedModels[index] = '';
      selectedSizes[index] = '';
      selectedUnits[index] = '';

      // Store filtered lists
      _filteredModelsForRow[index] = availableModels;
      _filteredSizesForRow[index] = availableSizes;
      _filteredUnitsForRow[index] = availableUnits;

      // AUTOFILL: If only one model exists, select it automatically
      if (availableModels.length == 1) {
        final modelName = availableModels.first;
        final model = modellist.firstWhere(
          (m) => m.modelName == modelName,
          orElse: () => Model(
            id: '0',
            modelName: '',
            addedby: '',
            activestatus: '1',
            createdAt: '',
          ),
        );
        _invoiceItems[index]['modelId'] = model.id;
        _invoiceItems[index]['modelName'] = modelName;
        selectedModels[index] = modelName;

        // If only one size exists after model selection, autofill
        if (availableSizes.length == 1) {
          final sizeName = availableSizes.first;
          final size = sizelist.firstWhere(
            (s) => s.sizeName == sizeName,
            orElse: () => ProductSize(
              id: '0',
              sizeName: '',
              addedby: '',
              activestatus: '1',
              createdAt: '',
            ),
          );
          _invoiceItems[index]['sizeId'] = size.id;
          _invoiceItems[index]['sizeName'] = sizeName;
          selectedSizes[index] = sizeName;
        }

        // If only one unit exists after model selection, autofill
        if (availableUnits.length == 1) {
          final unitName = availableUnits.first;
          final unit = unitlist.firstWhere(
            (u) => u.unitName == unitName,
            orElse: () => Unit(
              id: '0',
              unitName: '',
              addedby: '',
              activestatus: '1',
              createdAt: '',
            ),
          );
          _invoiceItems[index]['unitId'] = unit.id;
          _invoiceItems[index]['unitName'] = unitName;
          selectedUnits[index] = unitName;
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_quantityFocusNodes[index]);
    });
  }

  void _onModelSelected(int index, String modelName) {
    if (modelName.isEmpty) return;

    final selected = modellist.firstWhere(
      (m) => m.modelName == modelName,
      orElse: () => Model(
        id: '0',
        modelName: '',
        addedby: '',
        activestatus: '1',
        createdAt: '',
      ),
    );

    // Get available inventory for this product and model
    final productId = _invoiceItems[index]['productId'];
    final availableInventory = _getAvailableInventoryForProduct(productId);

    // Filter by selected model
    final filteredByModel = availableInventory
        .where((item) => item.modelId == selected.id)
        .toList();

    // Extract unique sizes and units for this model
    final availableSizesForModel = filteredByModel
        .map((item) => item.sizeName)
        .toSet()
        .toList();
    final availableUnitsForModel = filteredByModel
        .map((item) => item.unitName)
        .toSet()
        .toList();

    setState(() {
      _invoiceItems[index]['modelId'] = selected.id;
      _invoiceItems[index]['modelName'] = modelName;
      selectedModels[index] = modelName;

      // Clear previous size and unit selections
      _invoiceItems[index]['sizeId'] = '0';
      _invoiceItems[index]['sizeName'] = '';
      _invoiceItems[index]['unitId'] = '0';
      _invoiceItems[index]['unitName'] = '';
      selectedSizes[index] = '';
      selectedUnits[index] = '';

      // Store filtered lists for this model
      _filteredSizesForRow[index] = availableSizesForModel;
      _filteredUnitsForRow[index] = availableUnitsForModel;

      // AUTOFILL: If only one size exists, select it automatically
      if (availableSizesForModel.length == 1) {
        final sizeName = availableSizesForModel.first;
        final size = sizelist.firstWhere(
          (s) => s.sizeName == sizeName,
          orElse: () => ProductSize(
            id: '0',
            sizeName: '',
            addedby: '',
            activestatus: '1',
            createdAt: '',
          ),
        );
        _invoiceItems[index]['sizeId'] = size.id;
        _invoiceItems[index]['sizeName'] = sizeName;
        selectedSizes[index] = sizeName;
      }

      // AUTOFILL: If only one unit exists, select it automatically
      if (availableUnitsForModel.length == 1) {
        final unitName = availableUnitsForModel.first;
        final unit = unitlist.firstWhere(
          (u) => u.unitName == unitName,
          orElse: () => Unit(
            id: '0',
            unitName: '',
            addedby: '',
            activestatus: '1',
            createdAt: '',
          ),
        );
        _invoiceItems[index]['unitId'] = unit.id;
        _invoiceItems[index]['unitName'] = unitName;
        selectedUnits[index] = unitName;
      }
    });
  }

  final List<List<String>> _filteredModelsForRow = [];
  final List<List<String>> _filteredSizesForRow = [];
  final List<List<String>> _filteredUnitsForRow = [];

  void _onSizeSelected(int index, String sizeName) {
    if (sizeName.isEmpty) return;

    final selected = sizelist.firstWhere(
      (s) => s.sizeName == sizeName,
      orElse: () => ProductSize(
        id: '0',
        sizeName: '',
        addedby: '',
        activestatus: '1',
        createdAt: '',
      ),
    );

    setState(() {
      _invoiceItems[index]['sizeId'] = selected.id;
      _invoiceItems[index]['sizeName'] = sizeName;
      selectedSizes[index] = sizeName;
    });
  }

  void _onUnitSelected(int index, String unitName) {
    if (unitName.isEmpty) return;

    final selected = unitlist.firstWhere(
      (u) => u.unitName == unitName,
      orElse: () => Unit(
        id: '0',
        unitName: '',
        addedby: '',
        activestatus: '1',
        createdAt: '',
      ),
    );

    setState(() {
      _invoiceItems[index]['unitId'] = selected.id;
      _invoiceItems[index]['unitName'] = unitName;
      selectedUnits[index] = unitName;
    });
  }

  String? _validateInvoice() {
    if (_billNoController.text.trim().isEmpty) {
      return 'Bill Number is required';
    }

    if (customerId == null || customerId == '0') {
      return 'Customer is required';
    }

    if (_invoiceItems.isEmpty) {
      return 'At least one item is required';
    }

    for (var i = 0; i < _invoiceItems.length; i++) {
      final item = _invoiceItems[i];

      if (item['productId'] == '0') {
        return 'Product is required for item ${i + 1}';
      }

      final quantity = double.tryParse(item['quantity']) ?? 0;
      if (quantity <= 0) {
        return 'Quantity must be greater than 0 for item ${i + 1}';
      }

      final rate = double.tryParse(item['rate']) ?? 0;
      if (rate <= 0) {
        return 'Rate must be greater than 0 for item ${i + 1}';
      }
    }

    return null;
  }

  bool _isAutoFilled(int index, String field) {
    if (index >= _filteredModelsForRow.length ||
        index >= _filteredSizesForRow.length ||
        index >= _filteredUnitsForRow.length) {
      return false;
    }

    if (field == 'model') {
      return _filteredModelsForRow[index].length == 1 &&
          selectedModels[index] != null &&
          selectedModels[index]!.isNotEmpty;
    } else if (field == 'size') {
      return _filteredSizesForRow[index].length == 1 &&
          selectedSizes[index] != null &&
          selectedSizes[index]!.isNotEmpty;
    } else if (field == 'unit') {
      return _filteredUnitsForRow[index].length == 1 &&
          selectedUnits[index] != null &&
          selectedUnits[index]!.isNotEmpty;
    }
    return false;
  }

  void _saveInvoice() {
    String? validationError = _validateInvoice();
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (isEditMode) {
        invoiceApiService()
            .updateInvoice(
              context,
              actualInvoice!.id,
              _billNoController.text,
              customerId!,
              DateFormat('yyyy-MM-dd').format(
                DateFormat("dd/MM/yyyy").parse(_billDateController.text),
              ),
              _invoiceItems,
              _remarksController.text,
              _taxPercentage.toString(),
              _subtotal,
              _grandTotal,
              int.parse(_packingAmountController.text),
              _gstNoController.text,
              selectedDeliveryPartner?.id ?? "",
            )
            .then((result) {
              if (result == "Success") {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invoice updated successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
                Future.delayed(Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                });
              }
            });
      } else {
        invoiceApiService()
            .saveInvoice(
              context,
              _billNoController.text,
              customerId!,
              DateFormat('yyyy-MM-dd').format(
                DateFormat("dd/MM/yyyy").parse(_billDateController.text),
              ),
              _invoiceItems,
              _remarksController.text,
              _taxPercentage.toString(),
              _subtotal,
              _grandTotal,
              int.parse(_packingAmountController.text),
              _gstNoController.text,
              selectedDeliveryPartner?.id ?? '',
            )
            .then((result) {
              if (result == "Success") {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invoice saved successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
                Future.delayed(Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                });
              }
            });
      }
    }
  }

  Future<void> _printInvoice() async {
    Company? company;
    if (mounted) company = await invoiceApiService().getCompanyDetails(context);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InvoicePrintPreview(
            invoice: actualInvoice!,
            items: _invoiceItems,
            customerName: selectedCustomer ?? '',
            subtotal: _subtotal,
            taxAmount: _taxAmount,
            taxPercentage: _taxPercentage.toString(),
            grandTotal: _grandTotal,
            packingAmount: _packingAmountController.text,
            company: company,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBarWidget(
        title: isViewMode
            ? 'View Invoice'
            : (isEditMode ? 'Edit Invoice' : 'Invoice Entry'),
        showBackButton: true,
        actions: isViewMode
            ? [
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.black),
                  onPressed: _printInvoice,
                  tooltip: 'Print Invoice',
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      isMobile ? _buildMobileHeader() : _buildDesktopHeader(),

                      const SizedBox(height: 24),

                      _buildItemsSection(isMobile),

                      const SizedBox(height: 24),

                      _buildTotalsSection(isMobile),

                      const SizedBox(height: 24),

                      _buildNotesSection(isMobile),

                      const SizedBox(height: 32),

                      _buildActionButtons(isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        CustomTextField(
          controller: _billNoController,
          label: "Bill No.",
          hintText: "Enter bill number",
          isRequired: true,
          fieldType: "text",
          isReadOnly: isViewMode || isEditMode,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _billDateController,
          label: "Bill Date",
          hintText: "DD/MM/YYYY",
          isRequired: true,
          fieldType: "date",
          isReadOnly: isViewMode,
        ),
        const SizedBox(height: 16),
        CustomDropdownSearch(
          label: "Customer Name",
          isRequired: true,
          items: customerList.map((c) => c['name'].toString()).toList(),
          selectedItem: selectedCustomer,
          isReadOnly: isViewMode,
          // focusNode: _customerFocusNode,
          onChanged: isViewMode
              ? null
              : (value) {
                  setState(() {
                    selectedCustomer = value;
                    final selected = customerList.firstWhere(
                      (c) => c['name'] == value,
                      orElse: () => {},
                    );
                    customerId = selected['id'];
                  });
                },
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: _billNoController,
            label: "Bill No.",
            hintText: "Enter bill number",
            isRequired: true,
            fieldType: "text",
            isReadOnly: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomTextField(
            controller: _billDateController,
            label: "Bill Date",
            hintText: "DD/MM/YYYY",
            isRequired: true,
            fieldType: "date",
            isReadOnly: isViewMode,
          ),
        ),
        const SizedBox(width: 16),

        Expanded(
          child: CustomDropdownSearch(
            label: "Customer Name",
            isRequired: true,
            items: customerList.map((c) => c['name'].toString()).toList(),
            selectedItem: selectedCustomer,
            isReadOnly: isViewMode,
            onChanged: isViewMode
                ? null
                : (value) {
                    setState(() {
                      selectedCustomer = value;
                      final selected = customerList.firstWhere(
                        (c) => c['name'] == value,
                        orElse: () => {},
                      );
                      customerId = selected['id'];
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Invoice Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            if (!isViewMode && !isMobile)
              ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  '+ Add Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (isMobile) _buildMobileItemsList() else _buildDesktopItemsTable(),
      ],
    );
  }

  Widget _buildMobileItemsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _invoiceItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // Get available inventory for this product
        final productId = _invoiceItems[index]['productId'];
        final availableInventory = _getAvailableInventoryForProduct(productId);

        // Get unique values for dropdowns
        final availableModels = availableInventory
            .map((item) => item.modelName)
            .toSet()
            .toList();
        final availableSizes = availableInventory
            .map((item) => item.sizeName)
            .toSet()
            .toList();
        final availableUnits = availableInventory
            .map((item) => item.unitName)
            .toSet()
            .toList();

        return Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Item ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      if (!isViewMode)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _removeItem(index),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Product dropdown (always shows all products)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      child: CustomDropdownSearch(
                        label: "",
                        isRequired: true,
                        items: productlist.map((p) => p.productName).toList(),
                        selectedItem: selectedProducts[index],
                        isReadOnly: isViewMode,
                        dropdownKey: _productDropdownKeys[index],
                        onChanged: isViewMode
                            ? null
                            : (value) {
                                if (value != null && value.isNotEmpty) {
                                  _onProductSelected(index, value);
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Model',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (_isAutoFilled(index, 'model')) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Auto-filled',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      child: CustomDropdownSearch(
                        label: "",
                        isRequired: false,
                        items: availableModels.isNotEmpty
                            ? availableModels
                            : ['No models available'],
                        selectedItem: selectedModels[index],
                        isReadOnly:
                            isViewMode ||
                            availableModels.isEmpty ||
                            _isAutoFilled(index, 'model'),
                        dropdownKey: _modelDropdownKeys[index],
                        onChanged: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value != 'No models available') {
                            _onModelSelected(index, value);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Size dropdown with autofill indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Size',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (_isAutoFilled(index, 'size')) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Auto-filled',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      child: CustomDropdownSearch(
                        label: "",
                        isRequired: false,
                        items: availableSizes.isNotEmpty
                            ? availableSizes
                            : ['No sizes available'],
                        selectedItem: selectedSizes[index],
                        isReadOnly:
                            isViewMode ||
                            availableSizes.isEmpty ||
                            _isAutoFilled(index, 'size'),
                        dropdownKey: _sizeDropdownKeys[index],
                        onChanged: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value != 'No sizes available') {
                            _onSizeSelected(index, value);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Unit dropdown with autofill indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (_isAutoFilled(index, 'unit')) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Auto-filled',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      child: CustomDropdownSearch(
                        label: "",
                        isRequired: false,
                        items: availableUnits.isNotEmpty
                            ? availableUnits
                            : ['No units available'],
                        selectedItem: selectedUnits[index],
                        isReadOnly:
                            isViewMode ||
                            availableUnits.isEmpty ||
                            _isAutoFilled(index, 'unit'),
                        dropdownKey: _unitDropdownKeys[index],
                        onChanged: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value != 'No units available') {
                            _onUnitSelected(index, value);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Quantity and Rate row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Qty',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 40,
                            child: TextFormField(
                              controller: _quantityControllers[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                hintText: '1',
                              ),
                              readOnly: isViewMode,
                              onChanged: (value) {
                                String newValue = value.replaceAll(
                                  RegExp(r'[^\d]'),
                                  '',
                                );
                                if (newValue != value) {
                                  _quantityControllers[index].value =
                                      TextEditingValue(
                                        text: newValue,
                                        selection: TextSelection.collapsed(
                                          offset: newValue.length,
                                        ),
                                      );
                                }
                                _updateItemAmount(index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 40,
                            child: TextFormField(
                              controller: _rateControllers[index],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                hintText: '0.00',
                              ),
                              readOnly: isViewMode,
                              onChanged: (value) {
                                _updateItemAmount(index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Amount display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Rs.${double.tryParse(_invoiceItems[index]['amount'])?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (!isViewMode)
                  Align(
                    alignment: AlignmentGeometry.bottomRight,
                    child: ElevatedButton(
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        '+ Add Item',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopItemsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 50,
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'S.No',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Product',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Model',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Size',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Unit',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qty',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Rate',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Amount',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(width: 50),
              ],
            ),
          ),

          // Items
          ..._invoiceItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            // Get available inventory for this product
            final productId = item['productId'];
            final availableInventory = _getAvailableInventoryForProduct(
              productId,
            );

            // Get unique values for dropdowns
            final availableModels = availableInventory
                .map((i) => i.modelName)
                .toSet()
                .toList();
            final availableSizes = availableInventory
                .map((i) => i.sizeName)
                .toSet()
                .toList();
            final availableUnits = availableInventory
                .map((i) => i.unitName)
                .toSet()
                .toList();

            return Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  // S.No
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${index + 1}'),
                    ),
                  ),

                  // Product
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: isViewMode
                          ? Text(item['productName'] ?? '')
                          : SizedBox(
                              height: 50,
                              child: CustomDropdownSearch(
                                label: "",
                                isRequired: true,
                                items: productlist
                                    .map((p) => p.productName)
                                    .toList(),
                                selectedItem: selectedProducts[index],
                                isReadOnly: isViewMode,
                                dropdownKey: _productDropdownKeys[index],
                                onChanged: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    _onProductSelected(index, value);
                                  }
                                },
                              ),
                            ),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: isViewMode
                          ? Text(item['modelName'] ?? '')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isAutoFilled(index, 'model'))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'Auto-filled',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  height: 50,
                                  child: CustomDropdownSearch(
                                    label: "",
                                    isRequired: false,
                                    items: availableModels.isNotEmpty
                                        ? availableModels
                                        : ['No models available'],
                                    selectedItem: selectedModels[index],
                                    isReadOnly:
                                        isViewMode ||
                                        availableModels.isEmpty ||
                                        _isAutoFilled(index, 'model'),
                                    dropdownKey: _modelDropdownKeys[index],
                                    onChanged: (value) {
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          value != 'No models available') {
                                        _onModelSelected(index, value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Size - Filtered with autofill
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: isViewMode
                          ? Text(item['sizeName'] ?? '')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isAutoFilled(index, 'size'))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'Auto-filled',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  height: 50,
                                  child: CustomDropdownSearch(
                                    label: "",
                                    isRequired: false,
                                    items: availableSizes.isNotEmpty
                                        ? availableSizes
                                        : ['No sizes available'],
                                    selectedItem: selectedSizes[index],
                                    isReadOnly:
                                        isViewMode ||
                                        availableSizes.isEmpty ||
                                        _isAutoFilled(index, 'size'),
                                    dropdownKey: _sizeDropdownKeys[index],
                                    onChanged: (value) {
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          value != 'No sizes available') {
                                        _onSizeSelected(index, value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Unit - Filtered with autofill
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: isViewMode
                          ? Text(item['unitName'] ?? '')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isAutoFilled(index, 'unit'))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'Auto-filled',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  height: 50,
                                  child: CustomDropdownSearch(
                                    label: "",
                                    isRequired: false,
                                    items: availableUnits.isNotEmpty
                                        ? availableUnits
                                        : ['No units available'],
                                    selectedItem: selectedUnits[index],
                                    isReadOnly:
                                        isViewMode ||
                                        availableUnits.isEmpty ||
                                        _isAutoFilled(index, 'unit'),
                                    dropdownKey: _unitDropdownKeys[index],
                                    onChanged: (value) {
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          value != 'No units available') {
                                        _onUnitSelected(index, value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Quantity
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: isViewMode
                          ? Text(item['quantity'] ?? '')
                          : SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: TextFormField(
                                controller: _quantityControllers[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  hintText: '1',
                                ),
                                readOnly: isViewMode,
                                onChanged: (value) {
                                  String newValue = value.replaceAll(
                                    RegExp(r'[^\d]'),
                                    '',
                                  );
                                  if (newValue != value) {
                                    _quantityControllers[index].value =
                                        TextEditingValue(
                                          text: newValue,
                                          selection: TextSelection.collapsed(
                                            offset: newValue.length,
                                          ),
                                        );
                                  }
                                  _updateItemAmount(index);
                                },
                              ),
                            ),
                    ),
                  ),

                  // Rate
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: isViewMode
                          ? Text('Rs.${item['rate'] ?? ''}')
                          : SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: TextFormField(
                                controller: _rateControllers[index],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  hintText: '0.00',
                                ),
                                readOnly: isViewMode,
                                onChanged: (value) {
                                  String newValue = value.replaceAll(
                                    RegExp(r'[^\d.]'),
                                    '',
                                  );
                                  if (newValue.split('.').length > 2) {
                                    newValue = newValue.substring(
                                      0,
                                      newValue.lastIndexOf('.'),
                                    );
                                  }
                                  if (newValue.contains('.')) {
                                    final parts = newValue.split('.');
                                    if (parts[1].length > 2) {
                                      newValue =
                                          '${parts[0]}.${parts[1].substring(0, 2)}';
                                    }
                                  }
                                  if (newValue != value) {
                                    _rateControllers[index].value =
                                        TextEditingValue(
                                          text: newValue,
                                          selection: TextSelection.collapsed(
                                            offset: newValue.length,
                                          ),
                                        );
                                  }
                                  _updateItemAmount(index);
                                },
                              ),
                            ),
                    ),
                  ),

                  // Amount
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Rs.${double.tryParse(item['amount'])?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),

                  // Remove button
                  if (!isViewMode)
                    SizedBox(
                      width: 50,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _removeItem(index),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isMobile
          ? Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GST No:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      enabled: !isViewMode,
                      controller: _gstNoController,
                      keyboardType: TextInputType.emailAddress,

                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomDropdownSearch(
                  isReadOnly: !isViewMode,
                  selectedItem: selectedDeliveryPartner?.name,
                  label: 'Delivery Partners',
                  items: deliveryPartners.map<String>((invoice) {
                    return invoice.name;
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedDeliveryPartner =
                          deliveryPartners.firstWhere(
                                (element) =>
                                    element.name.toLowerCase() ==
                                    value.toString().toLowerCase(),
                              )
                              as DeliveryPartnerMasterModel?;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Packing Amount:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      enabled: !isViewMode,
                      onChanged: (val) {
                        _calculateTotals();
                      },
                      controller: _packingAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _buildTotalRow('Subtotal:', 'Rs.$_subtotal'),
                const SizedBox(height: 8),
                _buildTotalRow(
                  'Packing Amount:',
                  'Rs.${_packingAmountController.text}',
                ),
                const SizedBox(height: 8),
                _buildTotalRow('Tax ($_taxPercentage%):', 'Rs.$_taxAmount'),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 4),
                _buildTotalRow(
                  'Total Amount:',
                  'Rs.$_grandTotal',
                  isBold: true,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GST No:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            enabled: !isViewMode,
                            controller: _gstNoController,
                            keyboardType: TextInputType.emailAddress,

                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CustomDropdownSearch(
                        isReadOnly: !isViewMode,
                        selectedItem: selectedDeliveryPartner?.name,
                        label: 'Delivery Partners',
                        items: deliveryPartners.map<String>((invoice) {
                          return invoice.name;
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedDeliveryPartner =
                                deliveryPartners.firstWhere(
                                      (element) =>
                                          element.name.toLowerCase() ==
                                          value.toString().toLowerCase(),
                                    )
                                    as DeliveryPartnerMasterModel?;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Packing Amount:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            enabled: !isViewMode,
                            onChanged: (val) {
                              _calculateTotals();
                            },
                            controller: _packingAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTotalRow('Subtotal:', 'Rs.$_subtotal'),
                      const SizedBox(height: 4),
                      _buildTotalRow(
                        'Packing Amount:',
                        'Rs.${_packingAmountController.text}',
                      ),
                      const SizedBox(height: 4),
                      _buildTotalRow(
                        'Tax ($_taxPercentage%):',
                        'Rs.$_taxAmount',
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 20),
                      _buildTotalRow(
                        'Total Amount:',
                        'Rs.$_grandTotal',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold ? const Color(0xFF1E293B) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: isBold ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _remarksController,
          label: "",
          hintText: "Enter notes...",
          fieldType: "multiline",
          isReadOnly: isViewMode,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    if (isViewMode) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              minimumSize: Size(isMobile ? 120 : 100, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _printInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              minimumSize: Size(isMobile ? 120 : 100, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Print'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            minimumSize: Size(isMobile ? 120 : 100, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _saveInvoice,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            minimumSize: Size(isMobile ? 150 : 160, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(isEditMode ? 'Update Invoice' : 'Save Invoice'),
        ),
      ],
    );
  }
}
