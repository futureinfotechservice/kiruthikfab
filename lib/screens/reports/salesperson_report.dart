import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiruthikfab/screens/reports/sales_report_table.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/SalespersonData.dart';
import '../../../services/salesperson_report_apiservice.dart';
import '../../indigator/main.dart';
import '../navigation_provider.dart';

class SalespersonReport extends StatefulWidget {
  const SalespersonReport({super.key});

  @override
  State<SalespersonReport> createState() => _SalespersonReportState();
}

class _SalespersonReportState extends State<SalespersonReport> {
  final List<SalespersonData> allSalespersons = [];

  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  List<SalespersonData> _filteredData = [];
  bool _isFiltered = false;
  bool _isLoading = false;

  int _totalCalls = 0;
  int _totalApproach = 0;
  int _totalKycFilled = 0;
  int _totalValue = 0;
  String companyid = "";
  String? selectedSalesPerson;

  DateTime? _fromDate;
  DateTime? _toDate;
  String? userType;

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(allSalespersons);
    _updateTotals();
    init();
  }

  Future<void> fetchBetweenDate({
    required String fromDate,
    required String toDate,
  }) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await SalespersonReportApiService()
          .fetchAllSalesPersonBetweenDates(
            companyId: companyid,
            fromDate: fromDate,
            toDate: toDate,
          );

      if (res.isNotEmpty) {
        setState(() {
          allSalespersons.clear();
          for (var item in res) {
            allSalespersons.add(
              SalespersonData(
                id: item['id']?.toString() ?? '',
                name: item['name']?.toString() ?? '',
                totalCalls:
                    int.tryParse(item['totalCalls']?.toString() ?? '0') ?? 0,
                approach:
                    int.tryParse(item['approach']?.toString() ?? '0') ?? 0,
                kycFilled:
                    int.tryParse(item['kycFilled']?.toString() ?? '0') ?? 0,
                totalTime: '${item['totalTime']?.toString()} m',
                efficiency: double.parse(
                  double.tryParse(
                    item['efficiency']?.toString() ?? '0',
                  )!.toStringAsFixed(2),
                ),
                hours:
                    '${double.parse(item['hours']!.toString()).toStringAsFixed(2)} h',
                totalProductSales:
                    int.tryParse(
                      item['totalProductSales']?.toString() ?? '0',
                    ) ??
                    0,
                salesPerMin:
                    double.tryParse(item['salesPerMin']?.toString() ?? '0') ??
                    0.0,
                avgPerCustomer:
                    double.tryParse(
                      item['avgPerCustomer']?.toString() ?? '0',
                    ) ??
                    0.0,
                value: int.tryParse(item['value']?.toString() ?? '0') ?? 0,
              ),
            );
          }
          _filteredData = List.from(allSalespersons);
          _updateTotals();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // final id = prefs.getString('id');
    final username = prefs.getString('username');
    final userTypes = prefs.getString('user_type');

    setState(() {
      userType = userTypes;
      if (userTypes == 'USER') {
        selectedSalesPerson = username;
      }
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      companyid = prefs.getString('companyid') ?? '';
      final res = await SalespersonReportApiService().fetchAllSalesPerson(
        companyId: companyid,
      );

      if (res.isNotEmpty) {
        setState(() {
          allSalespersons.clear();
          for (var item in res) {
            allSalespersons.add(
              SalespersonData(
                id: item['id']?.toString() ?? '',
                name: item['name']?.toString() ?? '',
                totalCalls:
                    int.tryParse(item['totalCalls']?.toString() ?? '0') ?? 0,
                approach:
                    int.tryParse(item['approach']?.toString() ?? '0') ?? 0,
                kycFilled:
                    int.tryParse(item['kycFilled']?.toString() ?? '0') ?? 0,
                totalTime: '${item['totalTime']?.toString()} m',
                efficiency: double.parse(
                  double.tryParse(
                    item['efficiency']?.toString() ?? '0',
                  )!.toStringAsFixed(2),
                ),
                hours:
                    '${double.parse(item['hours']!.toString()).toStringAsFixed(2)} h',
                totalProductSales:
                    int.tryParse(
                      item['totalProductSales']?.toString() ?? '0',
                    ) ??
                    0,
                salesPerMin:
                    double.tryParse(item['salesPerMin']?.toString() ?? '0') ??
                    0.0,
                avgPerCustomer:
                    double.tryParse(
                      item['avgPerCustomer']?.toString() ?? '0',
                    ) ??
                    0.0,
                value: int.tryParse(item['value']?.toString() ?? '0') ?? 0,
              ),
            );
          }
          _filteredData = List.from(allSalespersons);
          _updateTotals();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (userType == "USER") _applyFilters();
    }
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = userType == "USER";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 16),
                if (!isUser) _buildFilterRow(),

                const SizedBox(height: 12),

                _buildSummaryCards(),
                const SizedBox(height: 16),
                _header1(),
                const SizedBox(height: 10),

                _isLoading
                    ? const Center(child: CircularWaveProgress())
                    : SalesReportTable(data: _filteredData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatIndianAmount(num amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 700;
          bool isMobile = constraints.maxWidth < 500;

          if (isMobile) {
            return Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedSalesPerson,
                  hint: const Text("Select Sales Person"),
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  ),
                  items: allSalespersons.map<DropdownMenuItem<String>>((
                    salesPerson,
                  ) {
                    return DropdownMenuItem<String>(
                      value: salesPerson.name,
                      child: Text(
                        salesPerson.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        selectedSalesPerson = value;
                      });

                      _applyFilters();
                    }
                  },
                ),
                // _buildFilterTextField(
                //   controller: _salespersonController,
                //   label: 'SALESPERSON',
                //   icon: Icons.person,
                // ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterTextField(
                        controller: _fromDateController,
                        label: 'FROM DATE',
                        icon: Icons.calendar_today,
                        isDate: true,
                        onDateTap: () => _selectDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterTextField(
                        controller: _toDateController,
                        label: 'TO DATE',
                        icon: Icons.calendar_today,
                        isDate: true,
                        onDateTap: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.black,
                          size: 18,
                        ),
                        onPressed: _clearFilters,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: const Text('Load Report'),
                      ),
                    ),
                  ],
                ),
                if (_isFiltered)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Showing ${_filteredData.length} of ${allSalespersons.length} salespersons',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            );
          }

          if (isSmallScreen) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSalesPerson,
                        hint: const Text("Select Sales Person"),
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.blue,
                          ),
                        ),
                        items: allSalespersons.map<DropdownMenuItem<String>>((
                          salesPerson,
                        ) {
                          return DropdownMenuItem<String>(
                            value: salesPerson.name,
                            child: Text(
                              salesPerson.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              selectedSalesPerson = value;
                            });

                            _applyFilters();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterTextField(
                        controller: _fromDateController,
                        label: 'FROM DATE',
                        icon: Icons.calendar_today,
                        isDate: true,
                        onDateTap: () => _selectDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterTextField(
                        controller: _toDateController,
                        label: 'TO DATE',
                        icon: Icons.calendar_today,
                        isDate: true,
                        onDateTap: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.clear, color: Colors.black),
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      label: const Text('Load Report'),
                    ),
                    if (_isFiltered)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          '(${_filteredData.length} of ${allSalespersons.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSalesPerson,
                  hint: const Text("Select Sales Person"),
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  ),
                  items: allSalespersons.map<DropdownMenuItem<String>>((
                    salesPerson,
                  ) {
                    return DropdownMenuItem<String>(
                      value: salesPerson.name,
                      child: Text(
                        salesPerson.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        selectedSalesPerson = value;
                      });

                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildFilterTextField(
                  controller: _fromDateController,
                  label: 'FROM DATE',
                  icon: Icons.calendar_today,
                  isDate: true,
                  onDateTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildFilterTextField(
                  controller: _toDateController,
                  label: 'TO DATE',
                  icon: Icons.calendar_today,
                  isDate: true,
                  onDateTap: () => _selectDate(context, false),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear, color: Colors.black),
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                label: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                label: const Text('Load Report'),
              ),
              if (_isFiltered)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '(${_filteredData.length} of ${allSalespersons.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _updateTotals() {
    setState(() {
      _totalCalls = _filteredData.fold(0, (sum, item) => sum + item.totalCalls);
      _totalApproach = _filteredData.fold(
        0,
        (sum, item) => sum + item.approach,
      );
      _totalKycFilled = _filteredData.fold(
        0,
        (sum, item) => sum + item.kycFilled,
      );
      _totalValue = _filteredData.fold(0, (sum, item) => sum + item.value);
    });
  }

  void _applyFilters() {
    setState(() {
      String searchQuery = selectedSalesPerson!.toLowerCase().trim().toString();

      // Start with all salespersons
      List<SalespersonData> filtered = List.from(allSalespersons);

      // Filter by salesperson name
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((item) {
          return item.name.toLowerCase().contains(searchQuery);
        }).toList();
      }

      if (_fromDate != null && _toDate == null) {
        fetchBetweenDate(
          fromDate: DateFormat('yyyy-MM-dd').format(_fromDate!),
          toDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
      }
      if (_fromDate != null && _toDate != null) {
        fetchBetweenDate(
          fromDate: DateFormat('yyyy-MM-dd').format(_fromDate!),
          toDate: DateFormat('yyyy-MM-dd').format(_toDate!),
        );
      }

      _filteredData = filtered;
      _isFiltered = _filteredData.length != allSalespersons.length;
      _updateTotals();
    });
  }

  void _clearFilters() {
    setState(() {
      selectedSalesPerson = null;
      _fromDateController.clear();
      _toDateController.clear();
      _fromDate = null;
      _toDate = null;
      _filteredData = List.from(allSalespersons);
      _isFiltered = false;
      _updateTotals();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: isFromDate ? 'Select FROM Date' : 'Select TO Date',
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
      });
    }
  }

  Widget _buildFilterTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDate = false,
    VoidCallback? onDateTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: isDate,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.indigo),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        suffixIcon: isDate
            ? IconButton(
                icon: const Icon(Icons.calendar_month, size: 18),
                onPressed: onDateTap,
              )
            : null,
      ),
      onSubmitted: (value) {
        if (!isDate) _applyFilters();
      },
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 500;

        if (isSmallScreen) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryCard(
                'TOTAL CALLS',
                _totalCalls.toString(),
                Colors.blue,
                (Icons.call),
              ),
              _buildSummaryCard(
                'TOTAL APPROACH',
                _totalApproach.toString(),
                Colors.green,
                (Icons.person_2_outlined),
              ),
              _buildSummaryCard(
                'KYC FILLED',
                _totalKycFilled.toString(),
                Colors.purple,
                (Icons.receipt_long),
              ),
              _buildSummaryCard(
                'TOTAL VALUE',
                '₹${formatIndianAmount(_totalValue as num)}',
                Colors.orange,
                Icons.star_border_outlined,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'TOTAL CALLS',
                _totalCalls.toString(),
                Colors.blue,
                (Icons.call),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'TOTAL\nAPPROACH',
                _totalApproach.toString(),
                Colors.green,
                (Icons.person_2_outlined),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'KYC FILLED',
                _totalKycFilled.toString(),
                Colors.purple,
                (Icons.receipt_long),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'TOTAL VALUE',
                '₹${formatIndianAmount(_totalValue as num)}',
                Colors.orange,
                (Icons.star_border_outlined),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overflow: TextOverflow.ellipsis,
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final navProvider = context.read<NavigationProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 800;

          if (isSmallScreen) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salesperson Performance Report',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Salesperson-wise performance metrics',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Analytics',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: init,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              IconButton(
                onPressed: () {
                  navProvider.updateIndex(
                    selectedIndex: 0,
                    reportSubIndex: 0,
                    masterSubIndex: 0,
                    entrySubIndex: 0,
                  );
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salesperson Performance Report',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Salesperson-wise performance metrics in a unified table view',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Text(
                      'Performance Analytics',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: init,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header1() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;

          if (isSmallScreen) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Records',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_filteredData.length} salesperson(s) loaded',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Salesperson Report',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Records',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredData.length} salesperson(s) loaded',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Text(
                      'Salesperson Report',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
