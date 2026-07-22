import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/models/stock_statement_model.dart';
import 'package:kiruthikfab/screens/navigation_provider.dart';
import 'package:kiruthikfab/services/stock_api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../indigator/main.dart';
import 'generates.dart';
import 'widgets.dart';

class StockStatementPage extends StatefulWidget {
  const StockStatementPage({super.key});

  @override
  State<StockStatementPage> createState() => _StockStatementPageState();
}

class _StockStatementPageState extends State<StockStatementPage> {
  List<StockStatementItem> _stockItems = [];
  List<StockStatementItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _companyId = '';
  bool _isGridView = false;

  final ScrollController _scrollController = ScrollController();

  final List<String> _filterOptions = [
    'All',
    'Low Stock',
    'In Stock',
    'Out of Stock',
  ];
  String? userType;

  // static const int _lowStockThreshold = 10;

  @override
  void initState() {
    super.initState();
    _fetchStockStatement();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more if needed
    }
  }

  Future<void> _fetchStockStatement() async {
    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _companyId = prefs.getString('companyid') ?? '';
      userType = prefs.getString('user_type');
      if (_companyId.isEmpty) {
        throw Exception('Company ID not found');
      }

      final response = await _callStockStatementApi(_companyId);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            _stockItems = data
                .map((item) => StockStatementItem.fromJson(item))
                .toList();
            _applyFilters();
          });
        } else if (data is Map && data.containsKey('error')) {
          if (mounted) showErrorSnackBar(data['error'], context);
        }
      } else {
        throw Exception('Failed to load stock data');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          'Failed to load stock data. Please try again.',
          context,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<http.Response> _callStockStatementApi(String companyId) async {
    return await StockApiService().post('stock-statement', {
      'companyid': companyId,
      'stock_status': _selectedFilter == 'All'
          ? 'all'
          : _selectedFilter == 'Low Stock'
          ? 'low'
          : _selectedFilter == 'In Stock'
          ? 'instock'
          : 'out',
      'search': _searchQuery,
    });
  }

  void _applyFilters() {
    var items = List<StockStatementItem>.from(_stockItems);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items
          .where(
            (item) =>
                item.inventoryNumber.toLowerCase().contains(query) ||
                item.productName.toLowerCase().contains(query) ||
                item.modelName.toLowerCase().contains(query) ||
                (item.manufacturer?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    // Apply stock status filter
    if (_selectedFilter != 'All') {
      items = items.where((item) {
        switch (_selectedFilter) {
          case 'Low Stock':
            return item.calculatedStock > 0 && item.calculatedStock <= 10;
          case 'In Stock':
            return item.calculatedStock > 10;
          case 'Out of Stock':
            return item.calculatedStock == 0;
          default:
            return true;
        }
      }).toList();
    }

    items.sort((a, b) => a.inventoryNumber.compareTo(b.inventoryNumber));

    setState(() {
      _filteredItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildStockSummary(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularWaveProgress())
                : _filteredItems.isEmpty
                ? buildEmptyState(_fetchStockStatement)
                : _isGridView
                ? _buildGridView()
                : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    final navProvider = context.watch<NavigationProvider>();
    return AppBar(
      title: const Text(
        'Stock Statement',
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
        icon: Icon(Icons.arrow_back, color: const Color(0xFFFFFFFF)),
      ),
      backgroundColor: const Color(0xff1E293B),
      foregroundColor: const Color(0xFFFFFFFF),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchStockStatement,
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
              case 'export_pdf':
                exportPDF(
                  companyId: _companyId,
                  stockStatus: _selectedFilter.toLowerCase() == 'all'
                      ? ''
                      : _selectedFilter.toLowerCase() == 'low stock'
                      ? 'low'
                      : _selectedFilter.toLowerCase() == 'in stock'
                      ? 'instock'
                      : 'out',
                  search: _searchQuery,
                  context: context,
                );
                break;
              case 'export_excel':
                exportExcel(
                  companyId: _companyId,
                  stockStatus: _selectedFilter.toLowerCase() == 'all'
                      ? ''
                      : _selectedFilter.toLowerCase() == 'low stock'
                      ? 'low'
                      : _selectedFilter.toLowerCase() == 'in stock'
                      ? 'instock'
                      : 'out',
                  search: _searchQuery,
                  context: context,
                );
                break;
              case 'print':
                printStatement(
                  companyId: _companyId,
                  stockStatus: _selectedFilter.toLowerCase() == 'all'
                      ? ''
                      : _selectedFilter.toLowerCase() == 'low stock'
                      ? 'low'
                      : _selectedFilter.toLowerCase() == 'in stock'
                      ? 'instock'
                      : 'out',
                  search: _searchQuery,
                  context: context,
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export_pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Color(0xFFF44336)),
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search inventory, product, model...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${_filteredItems.length} items',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                'Showing ${_filteredItems.isNotEmpty ? 1 : 0} - ${_filteredItems.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummary() {
    final totalItems = _stockItems.length;
    final totalStock = _stockItems.fold<int>(
      0,
      (sum, item) => sum + item.calculatedStock,
    );
    final lowStockItems = _stockItems
        .where((item) => item.calculatedStock <= 10 && item.calculatedStock > 0)
        .length;
    final outOfStock = _stockItems
        .where((item) => item.calculatedStock == 0)
        .length;

    return Row(
      children: [
        buildSummaryCard(
          'Total Items',
          totalItems.toString(),
          Icons.inventory,
          Colors.white,
        ),
        buildSummaryCard(
          'Total Stock',
          totalStock.toString(),
          Icons.shopping_bag,
          Colors.white,
        ),
        buildSummaryCard(
          'Low Stock',
          lowStockItems.toString(),
          Icons.warning,
          Colors.orange,
        ),
        buildSummaryCard(
          'Out of Stock',
          outOfStock.toString(),
          Icons.error,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isLastItem = index == _filteredItems.length - 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: isLastItem ? 0 : 12),
          child: buildStockItemCard(item, index, userType ?? ''),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 200,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return buildGridItemCard(item, index, userType ?? "");
      },
    );
  }

  Widget _buildFloatingActionButton() {
    if (_filteredItems.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      icon: const Icon(Icons.arrow_upward),
      label: Text('Top (${_filteredItems.length})'),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
    );
  }
}
