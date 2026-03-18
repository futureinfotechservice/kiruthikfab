import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import '../../../widgets/customappbarwidget.dart';
import '../../../widgets/customdropdownwidget.dart';
import '../../../widgets/customtextfield.dart';
import '../../services/config.dart';
import '../../services/invoice_apiservice.dart';

class InvoiceEntryPage extends StatefulWidget {
  final dynamic invoice;
  final bool isViewMode;

  const InvoiceEntryPage({
    super.key,
    this.invoice,
    this.isViewMode = false,
  });

  @override
  State<InvoiceEntryPage> createState() => _InvoiceEntryPageState();
}

class _InvoiceEntryPageState extends State<InvoiceEntryPage> {
  final _formKey = GlobalKey<FormState>();
  var usertype;

  // Lists for dropdowns
  final List<Map<String, dynamic>> _invoiceItems = [];
  final TextEditingController _remarksController = TextEditingController();
  String _subtotal = '₹0.00';
  String _taxAmount = '₹0.00';
  String _grandTotal = '₹0.00';

  // Tax percentage (can be made configurable)
  double _taxPercentage = 0.0;

  // Dropdown data lists
  List<Customer> customerlist = [];
  List<Product> productlist = [];
  List<Model> modellist = [];
  List<Size> sizelist = [];
  List<Unit> unitlist = [];

  // Controllers
  final _billNoController = TextEditingController();
  final _billDateController = TextEditingController(
    text: DateFormat("dd/MM/yyyy").format(DateTime.now()),
  );

  String? selectedCustomer;
  String? customerId;

  // Selected values for each row
  List<String?> selectedProducts = [];
  List<String?> selectedModels = [];
  List<String?> selectedSizes = [];
  List<String?> selectedUnits = [];

  // Controllers for quantity and rate
  List<TextEditingController> _quantityControllers = [];
  List<TextEditingController> _rateControllers = [];

  // Focus nodes
  List<FocusNode> _quantityFocusNodes = [];

  // Global keys for dropdowns
  final List<GlobalKey<DropdownSearchState<String>>> _productDropdownKeys = [];
  final List<GlobalKey<DropdownSearchState<String>>> _modelDropdownKeys = [];
  final List<GlobalKey<DropdownSearchState<String>>> _sizeDropdownKeys = [];
  final List<GlobalKey<DropdownSearchState<String>>> _unitDropdownKeys = [];

  // Order status
  String? _invoiceStatus;

  // Getters for mode detection
  bool get isEditMode => widget.invoice != null;
  bool get isViewMode {
    if (widget.isViewMode) return true;
    if (widget.invoice is Map) {
      return (widget.invoice as Map)['isViewMode'] == true;
    }
    return false;
  }

  // Helper to get the actual invoice from extra
  InvoiceModel? get actualInvoice {
    if (widget.invoice is InvoiceModel) return widget.invoice;
    if (widget.invoice is Map) return (widget.invoice as Map)['invoice'];
    return null;
  }

  Future<void> loadInvoiceNumber() async {
    if (isViewMode) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      final nextNo = await invoiceApiService().getNextInvoiceNumber(context, companyid);
      setState(() {
        _billNoController.text = nextNo.toString();
      });
    } catch (e) {
      print('Error loading invoice number: $e');
    }
  }

  Future<void> loadCustomers() async {
    customerlist = await invoiceApiService().getCustomers(context);
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await loadCustomers();
    await loadProducts();
    await loadModels();
    await loadSizes();
    await loadUnits();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    usertype = prefs.getString('user_type') ?? '';

    if (isEditMode || isViewMode) {
      _prefillForm();
    } else {
      await loadInvoiceNumber();
      _addItem();
    }

    _calculateTotals();
  }

  void _prefillForm() {
    final invoice = actualInvoice!;

    setState(() {
      _billNoController.text = invoice.invoiceNo;
      _billDateController.text = DateFormat('dd/MM/yyyy')
          .format(DateFormat("yyyy-MM-dd").parse(invoice.date));

      selectedCustomer = invoice.customerName;
      customerId = invoice.customerId;
      _remarksController.text = invoice.remarks;
      _invoiceStatus = invoice.status;

      _loadInvoiceDetails(invoice.id);
    });
  }

  Future<void> _loadInvoiceDetails(String invoiceId) async {
    try {
      final invoiceDetails = await invoiceApiService().getInvoiceDetails(context, invoiceId);

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

          // Add controllers
          _quantityControllers.add(TextEditingController(text: detail['quantity']?.toString() ?? '1'));
          _rateControllers.add(TextEditingController(text: detail['rate']?.toString() ?? '0.00'));

          // Add focus nodes
          _quantityFocusNodes.add(FocusNode());

          // Add dropdown keys
          _productDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
          _modelDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
          _sizeDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
          _unitDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());

          // Add selected values
          selectedProducts.add(detail['productname'] ?? '');
          selectedModels.add(detail['modelname'] ?? '');
          selectedSizes.add(detail['sizename'] ?? '');
          selectedUnits.add(detail['unitname'] ?? '');
        }

        _calculateTotals();
      });
    } catch (e) {
      print('Error loading invoice details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load invoice details')),
      );
    }
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _billDateController.dispose();
    _remarksController.dispose();

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

    double tax = subtotal * (_taxPercentage / 100);
    double grandTotal = subtotal + tax;

    setState(() {
      _subtotal = '₹${subtotal.toStringAsFixed(2)}';
      _taxAmount = '₹${tax.toStringAsFixed(2)}';
      _grandTotal = '₹${grandTotal.toStringAsFixed(2)}';
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

      // Add controllers
      _quantityControllers.add(TextEditingController(text: '1'));
      _rateControllers.add(TextEditingController());

      // Add focus nodes
      _quantityFocusNodes.add(FocusNode());

      // Add dropdown keys
      _productDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
      _modelDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
      _sizeDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());
      _unitDropdownKeys.add(GlobalKey<DropdownSearchState<String>>());

      // Add selected values
      selectedProducts.add('');
      selectedModels.add('');
      selectedSizes.add('');
      selectedUnits.add('');
    });

    // Auto-focus the newly added product dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_productDropdownKeys.isNotEmpty) {
        _productDropdownKeys.last.currentState?.openDropDownSearch();
      }
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

      _calculateTotals();
    });
  }

  void _updateItemAmount(int index) {
    final quantity = double.tryParse(_quantityControllers[index].text) ?? 0;
    final rate = double.tryParse(_rateControllers[index].text) ?? 0;
    final amount = quantity * rate;

    setState(() {
      _invoiceItems[index]['quantity'] = quantity.toString();
      _invoiceItems[index]['rate'] = rate.toString();
      _invoiceItems[index]['amount'] = amount.toStringAsFixed(2);
      _calculateTotals();
    });
  }

  void _onProductSelected(int index, String productName) {
    if (productName.isEmpty) return;

    final selected = productlist.firstWhere(
          (p) => p.productName == productName,
      orElse: () => Product(id: '0', productName: '', addedby: '', activestatus: '1', createdAt: ''),
    );

    setState(() {
      _invoiceItems[index]['productId'] = selected.id;
      _invoiceItems[index]['productName'] = productName;
      selectedProducts[index] = productName;
    });

    // Focus on quantity field after product selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_quantityFocusNodes[index]);
    });
  }

  void _onModelSelected(int index, String modelName) {
    if (modelName.isEmpty) return;

    final selected = modellist.firstWhere(
          (m) => m.modelName == modelName,
      orElse: () => Model(id: '0', modelName: '', addedby: '', activestatus: '1', createdAt: ''),
    );

    setState(() {
      _invoiceItems[index]['modelId'] = selected.id;
      _invoiceItems[index]['modelName'] = modelName;
      selectedModels[index] = modelName;
    });
  }

  void _onSizeSelected(int index, String sizeName) {
    if (sizeName.isEmpty) return;

    final selected = sizelist.firstWhere(
          (s) => s.sizeName == sizeName,
      orElse: () => Size(id: '0', sizeName: '', addedby: '', activestatus: '1', createdAt: ''),
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
      orElse: () => Unit(id: '0', unitName: '', addedby: '', activestatus: '1', createdAt: ''),
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

  void _saveInvoice() {
    String? validationError = _validateInvoice();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (isEditMode) {
        invoiceApiService().updateInvoice(
          context,
          actualInvoice!.id,
          _billNoController.text,
          customerId!,
          DateFormat('yyyy-MM-dd').format(
              DateFormat("dd/MM/yyyy").parse(_billDateController.text)),
          _invoiceItems,
          _remarksController.text,
          _taxPercentage.toString(),
          _subtotal,
          _grandTotal,
        ).then((result) {
          if (result == "Success") {
            Future.delayed(const Duration(seconds: 2), () {
              context.pop(true);
            });
          }
        });
      } else {
        invoiceApiService().saveInvoice(
          context,
          _billNoController.text,
          customerId!,
          DateFormat('yyyy-MM-dd').format(
              DateFormat("dd/MM/yyyy").parse(_billDateController.text)),
          _invoiceItems,
          _remarksController.text,
          _taxPercentage.toString(),
          _subtotal,
          _grandTotal,
        ).then((result) {
          if (result == "Success") {
            Future.delayed(const Duration(seconds: 2), () {
              context.pop(true);
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBarWidget(
        title: isViewMode ? 'View Invoice' : (isEditMode ? 'Edit Invoice' : 'Invoice Entry'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Status Bar (if view mode)
                if (isViewMode && _invoiceStatus != null && _invoiceStatus!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_invoiceStatus!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Status: ${_invoiceStatus!.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Header Section
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Bill No, Date, Customer Row
                      isMobile
                          ? _buildMobileHeader()
                          : _buildDesktopHeader(),

                      const SizedBox(height: 24),

                      // Invoice Items Section
                      _buildItemsSection(isMobile),

                      const SizedBox(height: 24),

                      // Totals Section
                      _buildTotalsSection(isMobile),

                      const SizedBox(height: 24),

                      // Notes Section
                      _buildNotesSection(isMobile),

                      const SizedBox(height: 32),

                      // Action Buttons
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        CustomTextField(
          controller: _billNoController,
          label: "Bill No.",
          hintText: "Enter bill number",
          isReadOnly: isViewMode || !isEditMode,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _billDateController,
          label: "Bill Date",
          hintText: "DD/MM/YYYY",
          fieldType: "date",
          // dateFormat: "dd/MM/yyyy",
          isReadOnly: isViewMode,
        ),
        const SizedBox(height: 16),
        CustomDropdownSearch(
          label: "Customer Name",
          isRequired: true,
          items: customerlist.map((c) => c.customerName).toList(),
          selectedItem: selectedCustomer,
          isReadOnly: isViewMode,
          onChanged: isViewMode ? null : (value) {
            setState(() {
              selectedCustomer = value;
              final selected = customerlist.firstWhere(
                    (c) => c.customerName == value,
                orElse: () => Customer(
                  id: '0',
                  customerName: '',
                  gstNo: '',
                  address: '',
                  area: '',
                  areaId: '',
                  mobile1: '',
                  mobile2: '',
                  whatsapp: '',
                  refer: '',
                  incharge: '',
                  agent: '',
                  salesperson: '',
                  occupation: '',
                  aadharUrl: '',
                  photoUrl: '',
                  addedby: '',
                  activestatus: '1',
                  createdAt: '',
                ),
              );
              customerId = selected.id;
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
            isReadOnly: isViewMode || !isEditMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomTextField(
            controller: _billDateController,
            label: "Bill Date",
            hintText: "DD/MM/YYYY",
            fieldType: "date",
            // dateFormat: "dd/MM/yyyy",
            isReadOnly: isViewMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomDropdownSearch(
            label: "Customer Name",
            isRequired: true,
            items: customerlist.map((c) => c.customerName).toList(),
            selectedItem: selectedCustomer,
            isReadOnly: isViewMode,
            onChanged: isViewMode ? null : (value) {
              setState(() {
                selectedCustomer = value;
                final selected = customerlist.firstWhere(
                      (c) => c.customerName == value,
                  orElse: () => Customer(
                    id: '0',
                    customerName: '',
                    gstNo: '',
                    address: '',
                    area: '',
                    areaId: '',
                    mobile1: '',
                    mobile2: '',
                    whatsapp: '',
                    refer: '',
                    incharge: '',
                    agent: '',
                    salesperson: '',
                    occupation: '',
                    aadharUrl: '',
                    photoUrl: '',
                    addedby: '',
                    activestatus: '1',
                    createdAt: '',
                  ),
                );
                customerId = selected.id;
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invoice Items',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (!isViewMode)
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

        if (isMobile)
          _buildMobileItemsList()
        else
          _buildDesktopItemsTable(),
      ],
    );
  }

  Widget _buildMobileItemsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _invoiceItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // S.No and Remove button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _removeItem(index),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Product dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    CustomDropdownSearch(
                      label: "",
                      isRequired: true,
                      items: productlist.map((p) => p.productName).toList(),
                      selectedItem: selectedProducts[index],
                      isReadOnly: isViewMode,
                      dropdownKey: _productDropdownKeys[index],
                      onChanged: isViewMode ? null : (value) {
                        if (value != null && value.isNotEmpty) {
                          _onProductSelected(index, value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Model dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Model', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    CustomDropdownSearch(
                      label: "",
                      isRequired: false,
                      items: modellist.map((m) => m.modelName).toList(),
                      selectedItem: selectedModels[index],
                      isReadOnly: isViewMode,
                      dropdownKey: _modelDropdownKeys[index],
                      onChanged: isViewMode ? null : (value) {
                        if (value != null && value.isNotEmpty) {
                          _onModelSelected(index, value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Size dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Size', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    CustomDropdownSearch(
                      label: "",
                      isRequired: false,
                      items: sizelist.map((s) => s.sizeName).toList(),
                      selectedItem: selectedSizes[index],
                      isReadOnly: isViewMode,
                      dropdownKey: _sizeDropdownKeys[index],
                      onChanged: isViewMode ? null : (value) {
                        if (value != null && value.isNotEmpty) {
                          _onSizeSelected(index, value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Unit dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unit', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    CustomDropdownSearch(
                      label: "",
                      isRequired: false,
                      items: unitlist.map((u) => u.unitName).toList(),
                      selectedItem: selectedUnits[index],
                      isReadOnly: isViewMode,
                      dropdownKey: _unitDropdownKeys[index],
                      onChanged: isViewMode ? null : (value) {
                        if (value != null && value.isNotEmpty) {
                          _onUnitSelected(index, value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quantity and Rate row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Qty', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          const SizedBox(height: 4),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextFormField(
                              controller: _quantityControllers[index],
                              focusNode: _quantityFocusNodes[index],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              readOnly: isViewMode,
                              onChanged: isViewMode ? null : (_) => _updateItemAmount(index),
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
                          const Text('Rate', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          const SizedBox(height: 4),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextFormField(
                              controller: _rateControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              readOnly: isViewMode,
                              onChanged: isViewMode ? null : (_) => _updateItemAmount(index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${double.tryParse(_invoiceItems[index]['amount'])?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 2, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 2, child: Text('Model', style: TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 1, child: Text('Size', style: TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 1, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 1, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w500))),
                SizedBox(width: 50), // For action
              ],
            ),
          ),

          // Items
          ..._invoiceItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text('${index + 1}')),

                  // Product dropdown
                  Expanded(
                    flex: 2,
                    child: CustomDropdownSearch(
                      label: "",
                      isRequired: true,
                      items: productlist.map((p) => p.productName).toList(),
                      selectedItem: selectedProducts[index],
                      isReadOnly: isViewMode,
                      dropdownKey: _productDropdownKeys[index],
                      onChanged: isViewMode ? null : (value) {
                        if (value != null && value.isNotEmpty) {
                          _onProductSelected(index, value);
                        }
                      },
                    ),
                  ),

                  // Model dropdown
                  Expanded(
                    flex: 2,
                    child: CustomDropdownSearch(
                      label: "",
                      isRequired: false,
                      items: modellist.map((m) => m.modelName).toList(),
                      selectedItem: selectedModels[index],
                      isReadOnly: isViewMode,
                      dropdownKey: _modelDropdownKeys[index],
                      onChanged: isViewMode ? null : (value) {
                        if (value != null && value.isNotEmpty) {
                          _onModelSelected(index, value);
                        }
                      },
                    ),
                  ),

                  // Size dropdown
                  Expanded(
                    flex: 1,
                    child: CustomDropdownSearch(
                      label: "",
                      isRequired: false,
                      items: sizelist.map((s) => s.sizeName).toList(),
                      selectedItem: selectedSizes[index],
                      isReadOnly: isViewMode,
                      dropdownKey: _sizeDropdownKeys[index],
                      onChanged: isViewMode ? null : (value) {
                        if (value != null && value.isNotEmpty) {
                          _onSizeSelected(index, value);
                        }
                      },
                    ),
                  ),

                  // Unit dropdown
                  Expanded(
                    flex: 1,
                    child: CustomDropdownSearch(
                      label: "",
                      isRequired: false,
                      items: unitlist.map((u) => u.unitName).toList(),
                      selectedItem: selectedUnits[index],
                      isReadOnly: isViewMode,
                      dropdownKey: _unitDropdownKeys[index],
                      onChanged: isViewMode ? null : (value) {
                        if (value != null && value.isNotEmpty) {
                          _onUnitSelected(index, value);
                        }
                      },
                    ),
                  ),

                  // Quantity
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextFormField(
                        controller: _quantityControllers[index],
                        focusNode: _quantityFocusNodes[index],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        readOnly: isViewMode,
                        onChanged: isViewMode ? null : (_) => _updateItemAmount(index),
                      ),
                    ),
                  ),

                  // Rate
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextFormField(
                        controller: _rateControllers[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        readOnly: isViewMode,
                        onChanged: isViewMode ? null : (_) => _updateItemAmount(index),
                      ),
                    ),
                  ),

                  // Amount
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.centerRight,
                      child: Text(
                        '₹${double.tryParse(item['amount'])?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  // Remove button
                  if (!isViewMode)
                    SizedBox(
                      width: 50,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _removeItem(index),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
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
          _buildTotalRow('Subtotal:', _subtotal),
          const SizedBox(height: 8),
          _buildTotalRow('Tax (0%):', _taxAmount),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 4),
          _buildTotalRow('Grand Total:', _grandTotal, isBold: true),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTotalRow('Subtotal:', _subtotal),
                const SizedBox(height: 4),
                _buildTotalRow('Tax (0%):', _taxAmount),
                const Divider(color: Color(0xFFE2E8F0), height: 20),
                _buildTotalRow('Grand Total:', _grandTotal, isBold: true),
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
        Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _remarksController,
            maxLines: 4,
            readOnly: isViewMode,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              hintText: 'Enter notes...',
              hintStyle: TextStyle(color: Color(0xFF999999)),
            ),
          ),
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
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              // minimumSize: Size(isMobile ? 120 : 100, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => context.pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            // minimumSize: Size(isMobile ? 120 : 100, 45),
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
            // minimumSize: Size(isMobile ? 150 : 160, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Invoice'),
        ),
      ],
    );
  }
}