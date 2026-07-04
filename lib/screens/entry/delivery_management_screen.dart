import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/delivery_model.dart';
import '../../services/delivery_management_apiservice.dart';
import '../entry/delivery_management.dart';

class DeliveryManagementListScreen extends StatefulWidget {
  const DeliveryManagementListScreen({super.key});

  @override
  State<DeliveryManagementListScreen> createState() =>
      _DeliveryManagementListScreenState();
}

class _DeliveryManagementListScreenState
    extends State<DeliveryManagementListScreen> {
  List<DeliveryRecord> allRecords = [];
  List<DeliveryRecordGroup> filteredGroups = [];
  List<DeliveryRecordGroup> allGroups = [];

  DateTime? fromDate;
  DateTime? toDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  String selectedStatus = "All";

  final searchController = TextEditingController();
  bool loading = true;
  String companyid = "";
  String? userType;
  String? loginUsername;
  String? loginId;
  int currentPage = 1;
  bool hasMore = true;
  bool loadingMore = false;
  final ScrollController scrollController = ScrollController();
  String total = '0';

  @override
  void initState() {
    super.initState();
    loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.addListener(_scrollListener);
    });
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;

    loadingMore = true;
    currentPage++;
    try {
      final data = await DeliveryManagementApiService().getAllProductsLimit(
        companyId: companyid,
        page: 1,
        limit: 100,
        fromDate: fromDate != null ? _dateFormat.format(fromDate!) : '',
        toDate: toDate != null ? _dateFormat.format(toDate!) : '',
        selectedStatus: selectedStatus,
        search: searchController.text,
      );

      setState(() {
        allRecords.addAll(data.data);
        allGroups.addAll(DeliveryRecord.groupRecords(allRecords));
        filteredGroups = List.from(allGroups);
        loading = false;
        hasMore = data.hasMore;
        loadingMore = false;
        total = data.total.toString();
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      _showSnackBar("Error loading more data: ${e.toString()}", isError: true);
    }
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });
    currentPage = 1;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      companyid = prefs.getString('companyid') ?? '';

      if (companyid.isEmpty) {
        throw Exception("Company ID not found");
      }

      final data = await DeliveryManagementApiService().getAllProductsLimit(
        companyId: companyid,
        page: 1,
        limit: 100,
        fromDate: fromDate != null ? _dateFormat.format(fromDate!) : '',
        toDate: toDate != null ? _dateFormat.format(toDate!) : '',
        selectedStatus: selectedStatus,
        search: searchController.text,
      );

      setState(() {
        allRecords = data.data;
        allGroups = DeliveryRecord.groupRecords(allRecords);
        filteredGroups = List.from(allGroups);
        loading = false;
        hasMore = data.hasMore;
        loadingMore = false;
        total = data.total.toString();
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      _showSnackBar("Error loading data: ${e.toString()}", isError: true);
    }
  }

  void applyFilters() {
    loadData();
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      fromDate = null;
      toDate = null;
      selectedStatus = "All";
      filteredGroups = List.from(allGroups);
    });
  }

  Future<void> pickDate(bool isFrom) async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    setState(() {
      if (isFrom) {
        fromDate = date;
      } else {
        toDate = date;
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool mobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    _filters(),
                    const SizedBox(height: 20),
                    filteredGroups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No records found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  "Try adjusting your filters",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : mobile
                        ? _mobileList()
                        : _desktopTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Delivery Records",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "View, filter and manage delivery records",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      alignment: WrapAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: _dateField("From Date", fromDate, () => pickDate(true)),
        ),
        SizedBox(
          width: 160,
          child: _dateField("To Date", toDate, () => pickDate(false)),
        ),
        SizedBox(
          width: 200,
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: "Search ...",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            items: const [
              DropdownMenuItem(value: "All", child: Text("All Status")),
              DropdownMenuItem(value: "Delivered", child: Text("Delivered")),
              DropdownMenuItem(value: "Pending", child: Text("Pending")),
              // DropdownMenuItem(value: "Draft", child: Text("Draft")),
              // DropdownMenuItem(value: "Failed", child: Text("Failed")),
            ],
            onChanged: (v) {
              if (v != null) {
                selectedStatus = v;
              }
            },
          ),
        ),
        ElevatedButton.icon(
          onPressed: clearFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            // foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.clear),
          label: const Text("Clear"),
        ),
        ElevatedButton(
          onPressed: applyFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Text(
            "Apply Filters",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DeliveryManagement(billNO: '0'),
              ),
            ).then((_) => loadData());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.add),
          label: const Text("Add\nRecord"),
        ),
      ],
    );
  }

  Widget _dateField(String title, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      if (title.contains("From")) {
                        fromDate = null;
                      } else {
                        toDate = null;
                      }
                    });
                  },
                )
              : null,
        ),
        child: Text(
          value == null ? "" : DateFormat("dd/MM/yyyy").format(value),
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _desktopTable() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bill Records List",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${filteredGroups.length} records found",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          child: DataTable(
            columnSpacing: 60,
            headingRowColor: WidgetStateProperty.resolveWith(
              (states) => Colors.grey.shade50,
            ),
            columns: const [
              DataColumn(
                label: Text("#", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text(
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  "Bill No",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Entry No",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Date",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Checklist",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Actions",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: filteredGroups.asMap().entries.map((entry) {
              final index = entry.key;
              final group = entry.value;
              final isAllChecked = group.isAllChecked;
              final date = DateTime.parse(group.date.toString());
              final formatedDate = DateFormat('dd-MM-yyyy').format(date);
              return DataRow(
                color: WidgetStateProperty.resolveWith(
                  (states) => isAllChecked ? Colors.green.shade50 : null,
                ),
                cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(
                    Text(
                      group.invoiceNo,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(Text(group.entryNo)),
                  DataCell(Text(formatedDate)),
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          isAllChecked ? Icons.check_circle : Icons.pending,
                          color: isAllChecked ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${group.records.where((r) => r.isChecked == "1").length}/${group.records.length}",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isAllChecked ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          group.status,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        group.status,
                        style: TextStyle(
                          color: _getStatusColor(group.status),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_red_eye_outlined,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeliveryManagement(billNO: group.invoiceNo),
                              ),
                            );
                          },
                          tooltip: "View/Edit",
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _mobileList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: filteredGroups.length,
        itemBuilder: (_, index) {
          final group = filteredGroups[index];
          final isAllChecked = group.isAllChecked;
          final date = DateTime.parse(group.date.toString());
          final formatedDate = DateFormat('dd-MM-yyyy').format(date);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAllChecked
                      ? Colors.green.shade300
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.invoiceNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            group.status,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          group.status,
                          style: TextStyle(
                            color: _getStatusColor(group.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.numbers,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Entry: ${group.entryNo}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatedDate,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isAllChecked ? Icons.check_circle : Icons.pending,
                            color: isAllChecked ? Colors.green : Colors.orange,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Checklist: ${group.records.where((r) => r.isChecked == "1").length}/${group.records.length}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isAllChecked
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeliveryManagement(billNO: group.invoiceNo),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
