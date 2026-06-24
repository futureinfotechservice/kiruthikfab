import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/ProductBasedSalesReportModel.dart';
import '../../services/productBasedReportApiService.dart';
import 'generate_sales_pdf.dart';

class ProductBasedSalesReport extends StatefulWidget {
  const ProductBasedSalesReport({super.key});

  @override
  State<ProductBasedSalesReport> createState() =>
      _ProductBasedSalesReportState();
}

class _ProductBasedSalesReportState extends State<ProductBasedSalesReport> {
  List<ProductBasedSalesReportModel>? _salesData;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isReportGenerated = false;
  List<ProductBasedSalesReportModel> _filteredData = [];
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    final data = await ProductBasedReportApiService().fetchCall();
    setState(() {
      _salesData = data;
      _filteredData = data;
    });
  }

  // Reset/Cancel
  void _cancel() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      // _filteredData = [];
      _isReportGenerated = false;
      _searchController.clear();
    });
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
    setState(() {
      if (_fromDate != null && _toDate != null) {
        _filteredData = _filteredData.where((item) {
          final date = DateTime.parse(item.salesDate);
          return date.isAfter(_fromDate!.subtract(const Duration(days: 1))) &&
              date.isBefore(_toDate!.add(const Duration(days: 1)));
        }).toList();
        _isReportGenerated = true;
      } else {
        _filteredData = List.from(_filteredData);
        _isReportGenerated = true;
      }
    });
  }

  void _filterData(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredData = List.from(_salesData ?? []);
      });
      return;
    }

    final search = query.toLowerCase();

    setState(() {
      _filteredData = (_salesData ?? []).where((item) {
        return item.products.toLowerCase().contains(search) ||
            item.salesPerson.toLowerCase().contains(search) ||
            item.sourceName.toLowerCase().contains(search);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // automaticallyImplyActions: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: init,
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
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Action buttons row
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    List<ProductBasedSalesReportModel> exportData;

                    if (_fromDate != null && _toDate != null) {
                      exportData = _filteredData.where((item) {
                        final date = DateTime.parse(item.salesDate);

                        return date.isAfter(
                              _fromDate!.subtract(const Duration(days: 1)),
                            ) &&
                            date.isBefore(
                              _toDate!.add(const Duration(days: 1)),
                            );
                      }).toList();
                    } else {
                      exportData = List.from(_filteredData);
                    }

                    await generatePdf(exportData, context);
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
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await generatePdf(List.from(_salesData!), context);
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
                const SizedBox(width: 12),
                Text(
                  "Total: ${_filteredData.length}",
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                    // Report header
                    Container(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 5,
                        bottom: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Product Report:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Table / List
                    Expanded(
                      child: _isReportGenerated && _filteredData.isNotEmpty
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
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: DataTable(
            columnSpacing: isSmallScreen ? 8 : 16,
            headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
            columns: const [
              DataColumn(
                label: Text(
                  'S.No',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Sales Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Source Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Products',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Sales person',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Qty',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: _filteredData.map((item) {
              return DataRow(
                cells: [
                  //show index+1  for sno
                  DataCell(Text((_filteredData.indexOf(item) + 1).toString())),
                  DataCell(
                    Text(_dateFormat.format(DateTime.parse(item.salesDate))),
                  ),
                  DataCell(Text(item.sourceName)),
                  DataCell(Text(item.products)),
                  DataCell(Text(item.salesPerson)),
                  DataCell(Text(item.qty.toString())),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.report, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _isReportGenerated
                ? 'No records found'
                : 'Select date range and generate report',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
