import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiruthikfab/models/stock_ledger_model.dart';
import 'package:kiruthikfab/screens/reports/stock_ledger/widgets.dart';
import 'package:kiruthikfab/services/stock_api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../indigator/main.dart';
import '../../../widgets/customdropdownwidget.dart';
import '../../navigation_provider.dart';
import 'generates.dart';

class StockLedgerPage extends StatefulWidget {
  const StockLedgerPage({super.key});

  @override
  State<StockLedgerPage> createState() => _StockLedgerPageState();
}

class _StockLedgerPageState extends State<StockLedgerPage> {
  StockLedgerData? _ledgerData;
  List<StockLedgerTransaction> _transactions = [];
  List<InventoryListItem> _inventories = [];

  bool _isLoading = false;

  // bool _isLoadingMore = false;
  bool _isGridView = false;

  String? _selectedInventoryId;
  String? _selectedInventoryDropdown;
  DateTime? _fromDate;
  DateTime? _toDate;

  int _currentPage = 1;
  final int _itemsPerPage = 20;

  // bool _hasMoreData = false;

  String _sortBy = 'date';
  bool _sortAscending = false;

  final ScrollController _scrollController = ScrollController();

  String? userType;
  String companyId = '';

  // static const int _lowStockThreshold = 10;

  @override
  void initState() {
    final navProvider = context.read<NavigationProvider>();
    super.initState();
    _selectedInventoryId = navProvider.inventoryNo.toString();
    _fetchInventories();
    if (_selectedInventoryId!.isNotEmpty) _fetchLedgerData();
    // _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // void _onScroll() {
  //   if (_scrollController.position.pixels >=
  //       _scrollController.position.maxScrollExtent - 200) {
  //     if (!_isLoadingMore && _hasMoreData) {
  //       _loadMoreData();
  //     }
  //   }
  // }

  Future<void> _fetchInventories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      companyId = prefs.getString('companyid') ?? '';
      userType = prefs.getString('user_type');

      if (companyId.isEmpty) {
        throw Exception('Company ID not found');
      }

      final response = await StockApiService().post('inventory-list', {
        'companyid': companyId,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _inventories = data
                .map((item) => InventoryListItem.fromJson(item))
                .toList();
          });
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar('Failed to load inventory list', context);
    }
  }

  Future<void> _fetchLedgerData({bool loadMore = false}) async {
    if (_selectedInventoryId == null || _selectedInventoryId!.isEmpty) return;
    if (loadMore) {
      // setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
      _currentPage = 1;
      _transactions = [];
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyid') ?? '';

      if (companyId.isEmpty) {
        throw Exception('Company ID not found');
      }

      final response = await StockApiService().post('stock-ledger', {
        'companyid': companyId,
        'inventoryid': _selectedInventoryId ?? '',
        'from_date': _fromDate != null
            ? DateFormat('yyyy-MM-dd').format(_fromDate!)
            : '',
        'to_date': _toDate != null
            ? DateFormat('yyyy-MM-dd').format(_toDate!)
            : '',
        'limit': _itemsPerPage.toString(),
        'offset': loadMore ? (_currentPage * _itemsPerPage).toString() : '0',
        'sort_by': _sortBy,
        'sort_order': _sortAscending ? 'asc' : 'desc',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map) {
          // Parse inventory info
          final Map<String, dynamic> inventoryInfo =
              data['inventory_info'] ?? {};
          final transactions = data['transactions'] as List? ?? [];
          final pagination = data['pagination'] ?? {};
          final summary = data['summary'] ?? {};

          setState(() {
            _ledgerData = StockLedgerData(
              inventoryInfo: InventoryInfo.fromJson(inventoryInfo),
              transactions: transactions
                  .map((item) => StockLedgerTransaction.fromJson(item))
                  .toList(),
              pagination: pagination != null
                  ? PaginationInfo.fromJson(pagination)
                  : null,
              summary: summary != null ? SummaryInfo.fromJson(summary) : null,
            );

            if (loadMore) {
              _transactions.addAll(_ledgerData!.transactions);
            } else {
              _transactions = _ledgerData!.transactions;
            }

            // _hasMoreData = _ledgerData?.pagination?.hasMore ?? false;
            _currentPage =
                (_ledgerData?.pagination?.offset ?? 0) ~/ _itemsPerPage + 1;
          });
        } else if (data is List) {
          // Fallback for old format
          final transactions = data
              .map((item) => StockLedgerTransaction.fromJson(item))
              .toList();
          setState(() {
            if (loadMore) {
              _transactions.addAll(transactions);
            } else {
              _transactions = transactions;
            }
            // _hasMoreData = transactions.length >= _itemsPerPage;
          });
        }
      } else {
        throw Exception('Failed to load ledger data');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          'Failed to load ledger data. Please try again.',
          context,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        // _isLoadingMore = false;
      });
    }
  }

  // Future<void> _loadMoreData() async {
  //   if (!_isLoadingMore && _hasMoreData) {
  //     await _fetchLedgerData(loadMore: true);
  //   }
  // }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
      _transactions = [];
    });
    _fetchLedgerData();
  }

  void _resetFilters() {
    final navProvider = context.read<NavigationProvider>();
    setState(() {
      _selectedInventoryId = navProvider.inventoryNo.toString();
      _selectedInventoryDropdown = null;
      _fromDate = null;
      _toDate = null;
      _currentPage = 1;
      _sortBy = 'date';
      _sortAscending = false;
    });
    _fetchLedgerData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularWaveProgress())
                : _transactions.isEmpty
                ? buildEmptyState(
                    fetchLedgerData: _fetchLedgerData,
                    selectedInventoryDropdown: _selectedInventoryDropdown ?? '',
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      if (_ledgerData?.inventoryInfo != null)
                        SliverToBoxAdapter(child: _buildInventoryInfoCard()),
                      if (_transactions.isNotEmpty)
                        SliverToBoxAdapter(child: _buildLedgerSummary()),
                      _buildTransactionList(),
                    ],
                  ),
          ),
          const SizedBox(height: 60),
        ],
      ),
      floatingActionButton: _transactions.isNotEmpty
          ? _buildFloatingActionButton()
          : null,
    );
  }

  AppBar _buildAppBar() {
    final navProvider = context.watch<NavigationProvider>();

    return AppBar(
      title: const Text(
        'Stock Ledger',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      leading: IconButton(
        onPressed: () {
          if (userType?.toUpperCase() == "ADMIN") {
            navProvider.updateIndex(
              selectedIndex: 3,
              reportSubIndex: 0,
              masterSubIndex: 0,
              entrySubIndex: 0,
            );
          } else {
            navProvider.updateIndex(
              selectedIndex: 2,
              reportSubIndex: 0,
              masterSubIndex: 0,
              entrySubIndex: 0,
            );
          }
        },
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      backgroundColor: const Color(0xff1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchLedgerData,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () {
            setState(() => _isGridView = !_isGridView);
          },
          tooltip: 'Toggle View',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'sort_date':
                setState(() {
                  _sortBy = 'date';
                  _sortAscending = !_sortAscending;
                });
                _fetchLedgerData();
                break;
              case 'sort_type':
                setState(() {
                  _sortBy = 'type';
                  _sortAscending = !_sortAscending;
                });
                _fetchLedgerData();
                break;
              case 'sort_amount':
                setState(() {
                  _sortBy = 'amount';
                  _sortAscending = !_sortAscending;
                });
                _fetchLedgerData();
                break;
              case 'export_pdf':
                exportLedger(
                  'pdf',
                  context: context,
                  companyId: companyId,
                  inventoryId: _selectedInventoryId ?? '',
                  fromDate: _fromDate != null
                      ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                      : '',
                  toDate: _toDate != null
                      ? DateFormat('yyyy-MM-dd').format(_toDate!)
                      : '',
                );
                break;
              case 'export_excel':
                exportLedger(
                  'excel',
                  context: context,
                  companyId: companyId,
                  inventoryId: _selectedInventoryId ?? '',
                  fromDate: _fromDate != null
                      ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                      : '',
                  toDate: _toDate != null
                      ? DateFormat('yyyy-MM-dd').format(_toDate!)
                      : '',
                );
                break;
              case 'print':
                printLedger(
                  context: context,
                  companyId: companyId,
                  inventoryId: _selectedInventoryId ?? '',
                  fromDate: _fromDate != null
                      ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                      : '',
                  toDate: _toDate != null
                      ? DateFormat('yyyy-MM-dd').format(_toDate!)
                      : '',
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sort_date',
              child: Row(
                children: [
                  Icon(Icons.sort),
                  SizedBox(width: 8),
                  Text('Sort by Date'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort_type',
              child: Row(
                children: [
                  Icon(Icons.sort),
                  SizedBox(width: 8),
                  Text('Sort by Type'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort_amount',
              child: Row(
                children: [
                  Icon(Icons.sort),
                  SizedBox(width: 8),
                  Text('Sort by Amount'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'export_pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Export as PDF'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export_excel',
              child: Row(
                children: [
                  Icon(Icons.table_chart, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Export as Excel'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Print'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomDropdownSearch(
            selectedItem: _selectedInventoryDropdown,
            isRequired: true,
            label: 'Select Inventory',
            items: _inventories.map((inventory) {
              return '${inventory.inventoryNumber} - ${inventory.productName} - ${inventory.modelName} - ${inventory.unitName} - ${inventory.sizeName}';
            }).toList(),

            onChanged: (value) {
              _selectedInventoryDropdown = value;

              _selectedInventoryId = _inventories
                  .where(
                    (inventory) =>
                        '${inventory.inventoryNumber} - ${inventory.productName} - ${inventory.modelName} - ${inventory.unitName} - ${inventory.sizeName}' ==
                        value,
                  )
                  .first
                  .id;

              setState(() {});
              _applyFilters();
            },
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'From Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      _fromDate != null
                          ? DateFormat('dd-MM-yyyy').format(_fromDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: _fromDate != null ? Colors.black : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'To Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      _toDate != null
                          ? DateFormat('dd-MM-yyyy').format(_toDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: _toDate != null ? Colors.black : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    fixedSize: const Size.fromHeight(50),
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size.fromHeight(50),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryInfoCard() {
    final info = _ledgerData!.inventoryInfo!;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.inventoryNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      info.productName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: getStockColor(info.calculatedStock),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Stock: ${info.calculatedStock}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              buildInfoChip('Model', info.modelName, Icons.factory),
              const SizedBox(width: 8),
              buildInfoChip('Size', info.sizeName, Icons.aspect_ratio),
              const SizedBox(width: 8),
              buildInfoChip('Unit', info.unitName, Icons.category),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerSummary() {
    final summary = _ledgerData?.summary;
    if (summary == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          buildSummaryItem(
            'Opening Qty',
            _ledgerData?.inventoryInfo?.openingStock.toString() ?? '',
            Icons.open_in_browser,
            Colors.green.shade300,
          ),
          buildSummaryItem(
            'Inward Qty',
            summary.totalInwardQuantity.toString(),
            Icons.arrow_downward,
            Colors.green.shade300,
          ),
          buildSummaryItem(
            'Outward Qty',
            summary.totalOutwardQuantity.toString(),
            Icons.arrow_upward,
            Colors.red.shade300,
          ),

          buildSummaryItem(
            'Inward Amt',
            '₹${summary.totalInwardAmount.toStringAsFixed(0)}',
            Icons.payments,
            Colors.green.shade300,
          ),
          buildSummaryItem(
            'Outward Amt',
            '₹${summary.totalOutwardAmount.toStringAsFixed(0)}',
            Icons.payments,
            Colors.red.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_isGridView) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              buildTransactionGridCard(_transactions[index], context),
          childCount: _transactions.length,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => buildTransactionCard(_transactions[index], index),
        childCount: _transactions.length,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      icon: const Icon(Icons.arrow_upward),
      label: Text('Top (${_transactions.length})'),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
          if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
            _fromDate = null;
          }
        }
      });
    }
  }
}
