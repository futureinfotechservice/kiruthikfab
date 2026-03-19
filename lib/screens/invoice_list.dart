import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/customappbarwidget.dart';
import '../../services/invoice_apiservice.dart';
import '../models/InvoicePrintPreview.dart';
import 'InvoiceEntryPage.dart';


class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> _filteredInvoices = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedCustomer = '';

  List<String> _customers = [];

  late String userType;
  bool _showFilterSection = false;
  bool get isMobile => MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _searchController.addListener(_filterInvoices);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInvoices();
      }
    });
  }

  Future<void> _loadInvoices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userType = prefs.getString('user_type') ?? '';

    _invoices = await invoiceApiService().getInvoiceList(context);
    _extractUniqueValues();
    _filterInvoices();
    setState(() {});
  }

  void _extractUniqueValues() {
    _customers = _invoices.map((inv) => inv.customerName).toSet().toList();
    _customers.insert(0, '');
  }

  void _filterInvoices() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredInvoices = _invoices.where((invoice) {
        final matchesSearch = query.isEmpty ||
            invoice.invoiceNo.toLowerCase().contains(query) ||
            invoice.customerName.toLowerCase().contains(query);

        final invoiceDate = DateFormat("yyyy-MM-dd").parse(invoice.date);
        final matchesDate = (_fromDate == null || invoiceDate.isAfter(_fromDate!)) &&
            (_toDate == null || invoiceDate.isBefore(_toDate!.add(const Duration(days: 1))));

        final matchesCustomer = _selectedCustomer.isEmpty ||
            invoice.customerName == _selectedCustomer;

        return matchesSearch && matchesDate && matchesCustomer;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _toDate = picked;
          _toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
        _filterInvoices();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedCustomer = '';
      _fromDateController.clear();
      _toDateController.clear();
      _filterInvoices();
    });
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await invoiceApiService().deleteInvoice(context, invoiceId);
      if (result == "Success") {
        _loadInvoices();
      }
    }
  }

  void _viewInvoice(InvoiceModel invoice) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceEntryPage(
          invoice: {'invoice': invoice, 'isViewMode': true},
        ),
      ),
    );

    if (result == true) {
      _loadInvoices();
    }
  }

  void _editInvoice(InvoiceModel invoice) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceEntryPage(
          invoice: invoice,
        ),
      ),
    );

    if (result == true) {
      _loadInvoices();
    }
  }

  void _printInvoice(InvoiceModel invoice) async {
    // Load full invoice details for printing
    final details = await invoiceApiService().getInvoiceDetails(context, invoice.id);

    if (details.isNotEmpty) {
      // Calculate tax amount from invoice data
      double subtotal = double.tryParse(invoice.subtotal) ?? 0;
      double grandTotal = double.tryParse(invoice.grandTotal) ?? 0;
      double taxPercentage = double.tryParse(invoice.taxPercentage) ?? 5.0;

      // Calculate tax amount (grandTotal = subtotal + tax)
      double taxAmount = grandTotal - subtotal;

      // Format the items with proper description
      final formattedItems = details.map((item) {
        // Build description with all available details
        final List<String> descriptionParts = [];

        // Add product name (always present)
        descriptionParts.add(item['productname'] ?? item['productName'] ?? '');

        // Add model if available
        final modelName = item['modelname'] ?? item['modelName'] ?? '';
        if (modelName.isNotEmpty) {
          descriptionParts.add('Model: $modelName');
        }

        // Add size if available
        final sizeName = item['sizename'] ?? item['sizeName'] ?? '';
        if (sizeName.isNotEmpty) {
          descriptionParts.add('Size: $sizeName');
        }

        // Add unit if available
        final unitName = item['unitname'] ?? item['unitName'] ?? '';
        if (unitName.isNotEmpty) {
          descriptionParts.add('Unit: $unitName');
        }

        return {
          ...item,
          'formattedDescription': descriptionParts.join(' | '),
        };
      }).toList();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InvoicePrintPreview(
            invoice: invoice,
            items: formattedItems,
            customerName: invoice.customerName,
            subtotal: invoice.subtotal,
            taxAmount: taxAmount.toStringAsFixed(2),
            taxPercentage: invoice.taxPercentage,
            grandTotal: invoice.grandTotal,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items found for this invoice'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'Invoices',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: isMobile
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Invoice List',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() => _showFilterSection = !_showFilterSection);
                            },
                            icon: Icon(
                              _showFilterSection ? Icons.filter_alt_off : Icons.filter_alt,
                              color: _showFilterSection ? const Color(0xFF4F46E5) : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const InvoiceEntryPage(),
                                ),
                              );
                              if (result == true) {
                                _loadInvoices();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Add Invoice',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Invoice List',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _showFilterSection = !_showFilterSection);
                        },
                        icon: Icon(
                          _showFilterSection ? Icons.filter_alt_off : Icons.filter_alt,
                          size: 16,
                        ),
                        label: Text(_showFilterSection ? 'Hide Filters' : 'Show Filters'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _showFilterSection ? const Color(0xFF4F46E5) : Colors.grey,
                          side: BorderSide(
                            color: _showFilterSection ? const Color(0xFF4F46E5) : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const InvoiceEntryPage(),
                            ),
                          );
                          if (result == true) {
                            _loadInvoices();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Add Invoice',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Filter Section
            if (_showFilterSection)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    if (isMobile) _buildMobileFilters() else _buildDesktopFilters(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear All'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _filterInvoices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                          ),
                          child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Search and List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.search, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search Invoice...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => _searchController.clear(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // List/Table
                    Expanded(
                      child: isMobile
                          ? _buildMobileList()
                          : _buildDesktopTable(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fromDateController,
                decoration: InputDecoration(
                  labelText: 'From Date',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, true),
                  ),
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _toDateController,
                decoration: InputDecoration(
                  labelText: 'To Date',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, false),
                  ),
                ),
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedCustomer.isEmpty ? null : _selectedCustomer,
          decoration: const InputDecoration(labelText: 'Customer'),
          items: [
            const DropdownMenuItem(value: '', child: Text('All Customers')),
            ..._customers.where((c) => c.isNotEmpty).map((customer) {
              return DropdownMenuItem(value: customer, child: Text(customer));
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCustomer = value ?? '';
              _filterInvoices();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _fromDateController,
            decoration: InputDecoration(
              labelText: 'From Date',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, true),
              ),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _toDateController,
            decoration: InputDecoration(
              labelText: 'To Date',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, false),
              ),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCustomer.isEmpty ? null : _selectedCustomer,
            decoration: const InputDecoration(labelText: 'Customer'),
            items: [
              const DropdownMenuItem(value: '', child: Text('All Customers')),
              ..._customers.where((c) => c.isNotEmpty).map((customer) {
                return DropdownMenuItem(value: customer, child: Text(customer));
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCustomer = value ?? '';
                _filterInvoices();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredInvoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final invoice = _filteredInvoices[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Items: ${invoice.totalItems ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.customerName,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(invoice.date))}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount: ₹${invoice.grandTotal}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.green, size: 20),
                    onPressed: () => _viewInvoice(invoice),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.blue, size: 20),
                    onPressed: () => _printInvoice(invoice),
                    tooltip: 'Print',
                  ),
                  if (userType == 'Admin') ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                      onPressed: () => _editInvoice(invoice),
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteInvoice(invoice.id),
                      tooltip: 'Delete',
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return Column(
      children: [
        // Header
        Container(
          height: 50,
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Invoice No', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 1, child: Text('Items', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 3, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            itemCount: _filteredInvoices.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
            itemBuilder: (context, index) {
              final invoice = _filteredInvoices[index];
              return Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(invoice.invoiceNo)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(invoice.date)),
                      ),
                    ),
                    Expanded(flex: 3, child: Text(invoice.customerName)),
                    Expanded(flex: 1, child: Text('${invoice.totalItems ?? 0}')),
                    Expanded(flex: 2, child: Text('₹${invoice.grandTotal}')),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.green, size: 18),
                            onPressed: () => _viewInvoice(invoice),
                            tooltip: 'View',
                          ),
                          IconButton(
                            icon: const Icon(Icons.print, color: Colors.blue, size: 18),
                            onPressed: () => _printInvoice(invoice),
                            tooltip: 'Print',
                          ),
                          if (userType == 'Admin') ...[
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                              onPressed: () => _editInvoice(invoice),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                              onPressed: () => _deleteInvoice(invoice.id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}