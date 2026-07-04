import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiruthikfab/models/ProductBasedSalesReportModel.dart';
import 'package:kiruthikfab/services/productBasedReportApiService.dart';
import 'package:kiruthikfab/widgets/customdropdownwidget.dart';

import 'generate_sales_pdf.dart';

class ProductBasedSalesReport extends StatefulWidget {
  const ProductBasedSalesReport({super.key});

  @override
  State<ProductBasedSalesReport> createState() =>
      _ProductBasedSalesReportState();
}

class _ProductBasedSalesReportState extends State<ProductBasedSalesReport> {
  List<ProductBasedSalesReportModel> _salesData = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isReportGenerated = false;
  List<ProductBasedSalesReportModel> _filteredData = [];
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // Pagination variables
  int _currentPage = 1;
  int _totalItems = 0;
  int _limit = 50;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  final ScrollController _scrollController = ScrollController();

  final ScrollController _horizontalScrollController = ScrollController();

  // Debounce for search
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _isInitialLoad = true;
      _salesData.clear();
      _filteredData.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final response = await ProductBasedSalesReportService().fetchCall(
        page: _currentPage,
        limit: _limit,
        search: _searchController.text.trim(),
        fromDate: _fromDate != null
            ? DateFormat('yyyy-MM-dd').format(_fromDate!)
            : null,
        toDate: _toDate != null
            ? DateFormat('yyyy-MM-dd').format(_toDate!)
            : null,
      );

      setState(() {
        if (response.status) {
          _salesData = response.data;
          _filteredData = response.data;
          _totalItems = response.total;
          _hasMore = response.hasMore;
          _currentPage = response.page;
          _isReportGenerated = true;
        } else {
          _showErrorSnackBar(response.message);
        }
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProductBasedSalesReportService().fetchCall(
        page: _currentPage + 1,
        limit: _limit,
        search: _searchController.text.trim(),
        fromDate: _fromDate != null
            ? DateFormat('yyyy-MM-dd').format(_fromDate!)
            : null,
        toDate: _toDate != null
            ? DateFormat('yyyy-MM-dd').format(_toDate!)
            : null,
      );

      setState(() {
        if (response.status) {
          _salesData.addAll(response.data);
          _filteredData = _salesData; // Update filtered data
          _totalItems = response.total;
          _hasMore = response.hasMore;
          _currentPage = response.page;
        } else {
          _showErrorSnackBar(response.message);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load more data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _refreshData() {
    _searchController.clear();
    _fromDate = null;
    _toDate = null;
    _isReportGenerated = false;
    _loadInitialData();
  }

  // Reset/Cancel
  void _cancel() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _searchController.clear();
      _isReportGenerated = false;
    });
    _loadInitialData();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _generateReport() {
    if (_fromDate != null && _toDate != null) {
      // Reload with date filter
      _loadInitialData();
    } else {
      _loadInitialData();
    }
  }

  void _filterData(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyActions: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        title: const Text('Product Based Sales Report', style: TextStyle()),
        backgroundColor: const Color(0xff1E293B),
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range row
            isSmallScreen
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              context,
                              label: 'From Date',
                              date: _fromDate,
                              onTap: () => _selectDate(context, true),
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              context,
                              label: 'To Date',
                              date: _toDate,
                              onTap: () => _selectDate(context, false),
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              onChanged: (val) {
                                _filterData(val);
                              },
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by name and products',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _loadInitialData();
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CustomDropdownSearch(
                              label: "Source",
                              isRequired: false,
                              items: [],
                              selectedItem: null,
                              // hint: hint,
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final selectedItem = [].firstWhere(
                                    (item) => item['name'] == value,
                                    orElse: () => {},
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomDropdownSearch(
                              label: "Products",
                              isRequired: false,
                              items: [],
                              selectedItem: null,
                              // hint: hint,
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final selectedItem = [].firstWhere(
                                    (item) => item['name'] == value,
                                    orElse: () => {},
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomDropdownSearch(
                              label: "Sales Person",
                              isRequired: false,
                              items: [],
                              selectedItem: null,
                              // hint: hint,
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final selectedItem = [].firstWhere(
                                    (item) => item['name'] == value,
                                    orElse: () => {},
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          context,
                          label: 'From Date',
                          date: _fromDate,
                          onTap: () => _selectDate(context, true),
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          context,
                          label: 'To Date',
                          date: _toDate,
                          onTap: () => _selectDate(context, false),
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          onChanged: (val) {
                            _filterData(val);
                          },
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name and products',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadInitialData();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomDropdownSearch(
                          label: "Source",
                          isRequired: false,
                          items: [],
                          selectedItem: null,
                          // hint: hint,
                          onChanged: (value) {
                            if (value != null && value.isNotEmpty) {
                              final selectedItem = [].firstWhere(
                                (item) => item['name'] == value,
                                orElse: () => {},
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomDropdownSearch(
                          label: "Products",
                          isRequired: false,
                          items: [],
                          selectedItem: null,
                          // hint: hint,
                          onChanged: (value) {
                            if (value != null && value.isNotEmpty) {
                              final selectedItem = [].firstWhere(
                                (item) => item['name'] == value,
                                orElse: () => {},
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomDropdownSearch(
                          label: "Sales Person",
                          isRequired: false,
                          items: [],
                          selectedItem: null,
                          // hint: hint,
                          onChanged: (value) {
                            if (value != null && value.isNotEmpty) {
                              final selectedItem = [].firstWhere(
                                (item) => item['name'] == value,
                                orElse: () => {},
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 10),

            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _filteredData.isEmpty
                        ? null
                        : () async {
                            await generatePdf(
                              _filteredData,
                              context,
                              title: 'Product Based Sales Report',
                            );
                          },
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Selected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _salesData.isEmpty
                        ? null
                        : () async {
                            await generatePdf(
                              _salesData,
                              context,
                              title: 'Product Based Sales Report',
                            );
                          },
                    icon: const Icon(Icons.print),
                    label: const Text('Print Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Total: ${_totalItems}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Report section
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report header with pagination info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Report:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Showing ${_filteredData.length} of $_totalItems',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table / List
                    Expanded(
                      child: _isLoading && _isInitialLoad
                          ? const Center(child: CircularProgressIndicator())
                          : _isReportGenerated && _filteredData.isNotEmpty
                          ? _buildReportTable(isSmallScreen)
                          : _buildEmptyState(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel / Generate buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[700]!),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _generateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Generate Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: isSmallScreen ? 16 : 20,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? _dateFormat.format(date) : label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  color: date != null ? Colors.black87 : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTable(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  controller: _scrollController,
                  child: Scrollbar(
                    controller: _horizontalScrollController,
                    scrollbarOrientation: ScrollbarOrientation.top,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Table Header
                            Container(
                              color: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  _buildHeaderCell('S.No', 60),
                                  _buildHeaderCell('Invoice.No', 100),
                                  _buildHeaderCell('Sales Date', 110),
                                  _buildHeaderCell(
                                    'Source Name',
                                    isSmallScreen ? 120 : 200,
                                  ),
                                  _buildHeaderCell(
                                    'Products',
                                    isSmallScreen ? 120 : 200,
                                  ),
                                  _buildHeaderCell(
                                    'Sales Person',
                                    isSmallScreen ? 120 : 200,
                                  ),
                                  _buildHeaderCell('Qty', 80),
                                ],
                              ),
                            ),

                            // Table Rows
                            ...List.generate(_filteredData.length, (index) {
                              final item = _filteredData[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: index == _filteredData.length - 1
                                          ? Colors.transparent
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildCell('${index + 1}', 60),
                                    _buildCell(item.invoiceNo, 100),
                                    _buildCell(
                                      _dateFormat.format(
                                        DateTime.parse(item.salesDate),
                                      ),
                                      110,
                                    ),
                                    _buildCell(
                                      item.sourceName,
                                      isSmallScreen ? 120 : 200,
                                    ),
                                    _buildCell(
                                      item.products,
                                      isSmallScreen ? 120 : 200,
                                    ),
                                    _buildCell(
                                      item.salesPerson,
                                      isSmallScreen ? 120 : 200,
                                    ),
                                    _buildCell(
                                      item.qty.toString(),
                                      80,
                                      isRightAligned: true,
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // Loading indicator at bottom
                            if (_isLoading && !_isInitialLoad)
                              Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),

                            // Show 'No more data' message
                            if (!_hasMore &&
                                _filteredData.isNotEmpty &&
                                !_isLoading)
                              Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: Text(
                                  'No more data to load',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCell(String text, double width, {bool isRightAligned = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
        textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isReportGenerated ? Icons.search_off : Icons.report,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _isReportGenerated
                ? 'No records found'
                : 'Select date range and generate report',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          if (_isReportGenerated && _filteredData.isEmpty)
            TextButton(
              onPressed: _refreshData,
              child: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }
}
