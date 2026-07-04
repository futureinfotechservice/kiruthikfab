import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../widgets/customappbarwidget.dart';
import '../../../../../widgets/customdropdownwidget.dart';
import '../../../../../widgets/customtextfield.dart';
import '../../../models/invoice_print_helper.dart';
import '../../../services/invoice_apiservice.dart';
import '../../../services/kyc_apiservice.dart';

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

      final nextNo = await invoiceApiService().getNextInvoiceNumber(
        context,
        companyid,
      );
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
        }

        _calculateTotals();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load invoice details')));
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
    double tax = subtotal * (_taxPercentage / 100);
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
    });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_productDropdownKeys.isNotEmpty) {
    //     _productDropdownKeys.last.currentState?.openDropDownSearch();
    //   }
    // });
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

    setState(() {
      _invoiceItems[index]['productId'] = selected.id;
      _invoiceItems[index]['productName'] = productName;
      selectedProducts[index] = productName;
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
            )
            .then((result) {
              if (result == "Success") {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invoice updated successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
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
            )
            .then((result) {
              if (result == "Success") {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invoice saved successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
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

  void _printInvoice() {
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
        ),
      ),
    );
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Invoice Items',
              style: TextStyle(
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

        if (isMobile) _buildMobileItemsList() else _buildDesktopItemsTable(),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with fixed height
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

                // All dropdowns with fixed height
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      // height: 45,
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
                    const Text(
                      'Model',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      // height: 45,
                      child: CustomDropdownSearch(
                        label: "",
                        isRequired: false,
                        items: modellist.map((p) => p.modelName).toList(),
                        selectedItem: selectedModels[index],
                        isReadOnly: isViewMode,
                        dropdownKey: _modelDropdownKeys[index],
                        onChanged: (value) {
                          if (value != null && value.isNotEmpty) {
                            _onModelSelected(index, value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Size',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            // height: 45,
                            child: CustomDropdownSearch(
                              label: "",
                              isRequired: false,
                              items: sizelist.map((s) => s.sizeName).toList(),
                              selectedItem: selectedSizes[index],
                              isReadOnly: isViewMode,
                              dropdownKey: _sizeDropdownKeys[index],
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) {
                                  _onSizeSelected(index, value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            // height: 45,
                            child: CustomDropdownSearch(
                              label: "",
                              isRequired: false,
                              items: unitlist.map((u) => u.unitName).toList(),
                              selectedItem: selectedUnits[index],
                              isReadOnly: isViewMode,
                              dropdownKey: _unitDropdownKeys[index],
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) {
                                  _onUnitSelected(index, value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Quantity and Rate row with fixed heights
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
                                // ... existing validation code
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

                // Amount display with fixed height
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
          // Header - Fixed height
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

          // Items - Fixed height rows
          ..._invoiceItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              height: 70, // Fixed height for all rows
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center all items vertically
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
                      alignment: Alignment.centerLeft,
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

                  // Model
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: isViewMode
                          ? Text(item['modelName'] ?? '')
                          : SizedBox(
                              height: 50,
                              child: CustomDropdownSearch(
                                label: "",
                                isRequired: false,
                                items: modellist
                                    .map((m) => m.modelName)
                                    .toList(),
                                selectedItem: selectedModels[index],
                                isReadOnly: isViewMode,
                                dropdownKey: _modelDropdownKeys[index],
                                onChanged: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    _onModelSelected(index, value);
                                  }
                                },
                              ),
                            ),
                    ),
                  ),

                  // Size
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: isViewMode
                          ? Text(item['sizeName'] ?? '')
                          : SizedBox(
                              height: 50,
                              child: CustomDropdownSearch(
                                label: "",
                                isRequired: false,
                                items: sizelist.map((s) => s.sizeName).toList(),
                                selectedItem: selectedSizes[index],
                                isReadOnly: isViewMode,
                                dropdownKey: _sizeDropdownKeys[index],
                                onChanged: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    _onSizeSelected(index, value);
                                  }
                                },
                              ),
                            ),
                    ),
                  ),

                  // Unit
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: isViewMode
                          ? Text(item['unitName'] ?? '')
                          : SizedBox(
                              height: 50,
                              child: CustomDropdownSearch(
                                label: "",
                                isRequired: false,
                                items: unitlist.map((u) => u.unitName).toList(),
                                selectedItem: selectedUnits[index],
                                isReadOnly: isViewMode,
                                dropdownKey: _unitDropdownKeys[index],
                                onChanged: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    _onUnitSelected(index, value);
                                  }
                                },
                              ),
                            ),
                    ),
                  ),

                  // Quantity
                  Expanded(
                    flex: 1,
                    child: Center(
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
                    child: Center(
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
                    child: Center(
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

class InvoicePrintPreview extends StatelessWidget {
  final InvoiceModel invoice;
  final List<Map<String, dynamic>> items;
  final String customerName;
  final String subtotal;
  final String taxAmount;
  final String taxPercentage;
  final String grandTotal;
  final String packingAmount;
  final Company? company;

  const InvoicePrintPreview({
    super.key,
    required this.invoice,
    required this.items,
    required this.customerName,
    required this.subtotal,
    required this.taxAmount,
    required this.taxPercentage,
    required this.grandTotal,
    this.company,
    required this.packingAmount, // Make it optional
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print Invoice - ${invoice.invoiceNo}'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          //   onPressed: () async {
          //     showDialog(
          //       context: context,
          //       barrierDismissible: false,
          //       builder: (context) => const Center(
          //         child: CircularProgressIndicator(),
          //       ),
          //     );
          //
          //     try {
          //       final pdf = await InvoicePrintHelper.generatePDF(
          //         invoice: invoice,
          //         items: items,
          //         customerName: customerName,
          //         subtotal: subtotal,
          //         taxAmount: taxAmount,
          //         taxPercentage: taxPercentage,
          //         grandTotal: grandTotal,
          //         company: company, // Pass company to PDF helper
          //       );
          //
          //       if (context.mounted) {
          //         Navigator.of(context).pop();
          //       }
          //
          //       final bool isWeb = identical(0, 0.0);
          //
          //       if (isWeb) {
          //         await InvoicePrintHelper.downloadPDFWeb(
          //           pdf,
          //           'Invoice_${invoice.invoiceNo}.pdf',
          //         );
          //         if (context.mounted) {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(
          //               content: Text('PDF downloaded successfully'),
          //               backgroundColor: Colors.green,
          //             ),
          //           );
          //         }
          //       } else {
          //         await Printing.layoutPdf(
          //           onLayout: (format) async => pdf,
          //         );
          //       }
          //     } catch (e) {
          //       if (context.mounted) {
          //         Navigator.of(context).pop();
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text('Error: $e'),
          //             backgroundColor: Colors.red,
          //           ),
          //         );
          //       }
          //     }
          //   },
          //   tooltip: 'Download PDF',
          // ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final pdf = await InvoicePrintHelper.generatePDF(
                  invoice: invoice,
                  items: items,
                  customerName: customerName,
                  subtotal: subtotal,
                  taxAmount: taxAmount,
                  taxPercentage: taxPercentage,
                  grandTotal: grandTotal,
                  company: company,
                  packingAmount: packingAmount,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                // Use Printing.layoutPdf directly for non-web platforms
                // For web, you need to handle download differently
                final bool isWeb = identical(0, 0.0);

                if (isWeb) {
                  // Create a download for web using the helper's internal method
                  // Since downloadPDFWeb is private, we'll use printInvoice which handles both
                  await InvoicePrintHelper.printInvoice(
                    context: context,
                    invoice: invoice,
                    items: items,
                    customerName: customerName,
                    subtotal: subtotal,
                    taxAmount: taxAmount,
                    taxPercentage: taxPercentage,
                    grandTotal: grandTotal,
                    company: company,
                    packingAmount: packingAmount,
                  );
                } else {
                  await Printing.layoutPdf(onLayout: (format) async => pdf);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF generated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Download PDF',
          ),
          // IconButton(
          //   icon: const Icon(Icons.print, color: Colors.white),
          //   onPressed: () async {
          //     showDialog(
          //       context: context,
          //       barrierDismissible: false,
          //       builder: (context) => const Center(
          //         child: CircularProgressIndicator(),
          //       ),
          //     );
          //
          //     try {
          //       await InvoicePrintHelper.printInvoice(
          //         context: context,
          //         invoice: invoice,
          //         items: items,
          //         customerName: customerName,
          //         subtotal: subtotal,
          //         taxAmount: taxAmount,
          //         taxPercentage: taxPercentage,
          //         grandTotal: grandTotal,
          //         company: company, // Pass company to print helper
          //       );
          //
          //       if (context.mounted) {
          //         Navigator.of(context).pop();
          //       }
          //     } catch (e) {
          //       if (context.mounted) {
          //         Navigator.of(context).pop();
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text('Error: $e'),
          //             backgroundColor: Colors.red,
          //           ),
          //         );
          //       }
          //     }
          //   },
          //   tooltip: 'Print',
          // ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 800,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Header Section
                _buildCompanyHeader(),

                const SizedBox(height: 24),

                // Invoice Title
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'TAX INVOICE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bill No: ${invoice.invoiceNo}  |  Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(invoice.date))}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bill To Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill To:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Customer Name: $customerName'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Items Table
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Colors.grey.shade100,
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'S.No',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Description',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Qty',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Rate',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Amount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Rows
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        String description = item['formattedDescription'] ?? '';

                        if (description.isEmpty) {
                          final List<String> parts = [];
                          parts.add(
                            item['productName'] ?? item['productname'] ?? '',
                          );

                          final model =
                              item['modelName'] ?? item['modelname'] ?? '';
                          if (model.isNotEmpty) parts.add('Model: $model');

                          final size =
                              item['sizeName'] ?? item['sizename'] ?? '';
                          if (size.isNotEmpty) parts.add('Size: $size');

                          final unit =
                              item['unitName'] ?? item['unitname'] ?? '';
                          if (unit.isNotEmpty) parts.add('Unit: $unit');

                          description = parts.join(' | ');
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 1, child: Text('${index + 1}')),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  description,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  item['quantity']?.toString() ?? '0',
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Rs.${double.tryParse(item['rate']?.toString() ?? '0')?.toStringAsFixed(2)}',
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Rs.${double.tryParse(item['amount']?.toString() ?? '0')?.toStringAsFixed(2)}',
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Totals Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTotalRow('Subtotal:', 'Rs.$subtotal'),
                          const SizedBox(height: 4),
                          _buildTotalRow(
                            'Packing Amount:',
                            'Rs.$packingAmount',
                          ),
                          const SizedBox(height: 4),
                          _buildTotalRow(
                            'Tax ($taxPercentage%):',
                            'Rs.$taxAmount',
                          ),
                          const Divider(color: Colors.grey),
                          _buildTotalRow(
                            'Total Amount:',
                            'Rs.$grandTotal',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Footer with Authorized Sign
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Logo (if available)
          if (company?.logoUrl != null && company!.logoUrl.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 16),
              child: company!.logoUrl.startsWith('http')
                  ? Image.network(company!.logoUrl, fit: BoxFit.contain)
                  : const Icon(Icons.business, size: 50, color: Colors.grey),
            ),

          // Company Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company?.companyName ?? 'Company Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                if (company?.address != null && company!.address.isNotEmpty)
                  Text(
                    company!.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 4),
                if (company?.contactNo != null && company!.contactNo.isNotEmpty)
                  Text(
                    'Contact: ${company!.contactNo}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (company?.emailId != null && company!.emailId.isNotEmpty)
                  Text(
                    'Email: ${company!.emailId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (company?.gstNo != null && company!.gstNo.isNotEmpty)
                  Text(
                    'GST No: ${company!.gstNo}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '1. Goods once sold will not be taken back\n2. Subject to local jurisdiction',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 200,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black)),
              ),
              child: const Text(
                'Authorized Signatory',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
