import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../indigator/main.dart';
import '../../models/source_followup_report_model.dart';
import '../../services/source_followup_report_apiservice.dart';
import '../navigation_provider.dart';
import 'generate_followup_report.dart';

class SourceFollowupReport extends StatefulWidget {
  const SourceFollowupReport({super.key});

  @override
  State<SourceFollowupReport> createState() => _SourceFollowupReportState();
}

class _SourceFollowupReportState extends State<SourceFollowupReport> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isReportGenerated = false;
  bool isNotCalled = false;
  bool isCalled = false;
  bool isAll = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  List<SourceFollowupReportModel> records = [];

  int currentPage = 1;
  bool hasMore = true;
  bool loadingMore = false;

  final ScrollController scrollController = ScrollController();
  final ScrollController horizontalController = ScrollController();
  List<SourceFollowupReportModel> filtered = [];

  bool loading = true;

  final searchController = TextEditingController();
  final _searchController = TextEditingController();

  String? userType;
  String? loginUsername;
  String? loginId;

  @override
  void initState() {
    super.initState();
    load();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 300) {
        loadMore();
      }
    });
  }

  Future<void> fetchNotCalled() async {
    setState(() {
      isNotCalled = true;
      isCalled = false;
      isAll = false;
    });
    currentPage = 1;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final id = prefs.getString('id');
      // final username = prefs.getString('username');
      final userTypes = prefs.getString('user_type');

      final isUser = userTypes == "USER";

      if (isUser) {
        final response = await SourceFollowupReportApiservice()
            .fetchAllNotCalledUser(id: id!, page: 1, limit: 100);

        records = response.data;
        filtered = response.data;
        hasMore = response.hasMore;
      } else {
        final response = await SourceFollowupReportApiservice()
            .fetchAllNotCalled(page: 1, limit: 100);

        records = response.data;
        filtered = response.data;
        hasMore = response.hasMore;
      }

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> fetchCalled() async {
    setState(() {
      isCalled = true;
      isNotCalled = false;
      isAll = false;
    });
    currentPage = 1;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final id = prefs.getString('id');
      // final username = prefs.getString('username');
      final userTypes = prefs.getString('user_type');

      final isUser = userTypes == "USER";

      if (isUser) {
        final response = await SourceFollowupReportApiservice()
            .fetchAllCalledUser(id: id!, page: 1, limit: 100);

        records = response.data;
        filtered = response.data;
        hasMore = response.hasMore;
      } else {
        final response = await SourceFollowupReportApiservice().fetchAllCalled(
          page: 1,
          limit: 100,
        );

        records = response.data;
        filtered = response.data;
        hasMore = response.hasMore;
      }

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;

    loadingMore = true;

    try {
      currentPage++;

      SharedPreferences prefs = await SharedPreferences.getInstance();

      final id = prefs.getString('id');
      final userTypes = prefs.getString('user_type');

      final isUser = userTypes == "USER";

      SourceFollowupResponse response;
      if (isAll) {
        if (isUser) {
          response = await SourceFollowupReportApiservice().fetchAllUser(
            id: id!,
            page: currentPage,
            limit: 100,
          );
        } else {
          response = await SourceFollowupReportApiservice().fetchAll(
            page: currentPage,
            limit: 100,
          );
        }

        setState(() {
          records.addAll(response.data);
          filtered = List.from(records);
          hasMore = response.hasMore;
        });
      } else if (isCalled) {
        if (isUser) {
          response = await SourceFollowupReportApiservice().fetchAllCalledUser(
            id: id!,
            page: currentPage,
            limit: 100,
          );
        } else {
          response = await SourceFollowupReportApiservice().fetchAllCalled(
            page: currentPage,
            limit: 100,
          );
        }

        setState(() {
          records.addAll(response.data);
          filtered = List.from(records);
          hasMore = response.hasMore;
        });
      } else if (isNotCalled) {
        if (isUser) {
          response = await SourceFollowupReportApiservice()
              .fetchAllNotCalledUser(id: id!, page: currentPage, limit: 100);
        } else {
          response = await SourceFollowupReportApiservice().fetchAllNotCalled(
            page: currentPage,
            limit: 100,
          );
        }

        setState(() {
          records.addAll(response.data);
          filtered = List.from(records);
          hasMore = response.hasMore;
        });
      }
    } finally {
      loadingMore = false;
    }
  }

  Future<void> printReport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final id = prefs.getString('id');
    // final username = prefs.getString('username');
    final userTypes = prefs.getString('user_type');

    final isUser = userTypes == "USER";

    if (isUser) {
      await SourceFollowupReportApiservice().fetchAllUserReport(id: id!);
    } else {
      await SourceFollowupReportApiservice().fetchAllReport();
    }
  }

  Future<void> load() async {
    setState(() {
      isAll = true;
      isNotCalled = false;
      isCalled = false;
    });
    currentPage = 1;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final id = prefs.getString('id');
      final username = prefs.getString('username');
      final userTypes = prefs.getString('user_type');

      final isUser = userTypes == "USER";

      if (isUser) {
        final response = await SourceFollowupReportApiservice().fetchAllUser(
          id: id!,
          page: 1,
          limit: 100,
        );

        records = response.data;
        filtered = response.data;
        hasMore = response.hasMore;
      } else {
        final response = await SourceFollowupReportApiservice().fetchAll(
          page: 1,
          limit: 100,
        );

        records = response.data;
        filtered = response.data;
        hasMore = response.hasMore;
      }

      if (!mounted) return;

      setState(() {
        loginId = id;
        loginUsername = username;
        userType = userTypes;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  // Reset/Cancel
  void _cancel() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      // filtered = [];
      _isReportGenerated = false;
      _searchController.clear();
      isCalled = false;
      isNotCalled = false;
    });
    load();
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
        filtered = filtered.where((item) {
          final date = DateTime.parse(item.date);
          return date.isAfter(_fromDate!.subtract(const Duration(days: 1))) &&
              date.isBefore(_toDate!.add(const Duration(days: 1)));
        }).toList();
        _isReportGenerated = true;
      } else {
        filtered = List.from(filtered);
        _isReportGenerated = true;
      }
    });
  }

  void _filterData(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        filtered = List.from(records);
      });
      return;
    }

    final search = query.toLowerCase();

    setState(() {
      filtered = (records).where((item) {
        return item.salesPersonName.toLowerCase().contains(search) ||
            item.interest.interest.toLowerCase().contains(search) ||
            item.sourceName.toLowerCase().contains(search);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final navProvider = context.watch<NavigationProvider>();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: const Color(0xff1E293B),
        foregroundColor: Colors.white,
        automaticallyImplyActions: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        title: const Text('Source Followup Report', style: TextStyle()),

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
                      hintText: 'Search by source name, called by and interest',
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

            Wrap(
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: fetchCalled,
                  icon: const Icon(Icons.call),
                  label: const Text('Called'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCalled
                        ? Colors.green[700]
                        : Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: fetchNotCalled,
                  icon: const Icon(Icons.call_end),
                  label: const Text('Not Called'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNotCalled
                        ? Colors.green[700]
                        : Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: load,
                  icon: const Icon(Icons.all_inclusive),
                  label: const Text('All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAll
                        ? Colors.green[700]
                        : Colors.blue[700],
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
                    List<SourceFollowupReportModel> exportData;

                    if (_fromDate != null && _toDate != null) {
                      exportData = filtered.where((item) {
                        final date = DateTime.parse(item.date);

                        return date.isAfter(
                              _fromDate!.subtract(const Duration(days: 1)),
                            ) &&
                            date.isBefore(
                              _toDate!.add(const Duration(days: 1)),
                            );
                      }).toList();
                    } else {
                      exportData = List.from(filtered);
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
                  onPressed: printReport,
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
                  "Total: ${filtered.length}",
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
                    Expanded(
                      child: _isReportGenerated && filtered.isNotEmpty
                          ? _buildReportTable(isSmallScreen)
                          : _buildEmptyState(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
    const double tableWidth = 1260;

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.top,
            child: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    //================ HEADER =================
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell("S.No", 60),
                          _buildHeaderCell("Source No", 100),
                          _buildHeaderCell("Source Name", 220),
                          _buildHeaderCell("Mobile", 110),
                          _buildHeaderCell("Sales Person", 220),
                          _buildHeaderCell("Entry No", 140),
                          _buildHeaderCell("Date", 120),
                          _buildHeaderCell("Followup Date", 140),
                          _buildHeaderCell("Interest", 140),
                        ],
                      ),
                    ),

                    //================ BODY =================
                    Expanded(
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount:
                              filtered.length +
                              (loadingMore ? 1 : 0) +
                              (!hasMore && filtered.isNotEmpty && !loadingMore
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index == filtered.length && loadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(15),
                                child: Center(child: CircularWaveProgress()),
                              );
                            }

                            if (index == filtered.length &&
                                !loadingMore &&
                                !hasMore) {
                              return Padding(
                                padding: const EdgeInsets.all(15),
                                child: Center(
                                  child: Text(
                                    "No more data available",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final item = filtered[index];

                            return Container(
                              color: index.isEven
                                  ? Colors.white
                                  : Colors.grey.shade50,
                              child: Row(
                                children: [
                                  _buildDataCell("${index + 1}", 60),
                                  _buildDataCell(item.sourceNo, 100),
                                  _buildDataCell(item.sourceName, 220),
                                  _buildDataCell(item.mobile, 110),
                                  _buildDataCell(item.salesPersonName, 220),
                                  _buildDataCell(item.entryNo.toString(), 140),
                                  _buildDataCell(item.date.toString(), 120),
                                  _buildDataCell(
                                    item.followupDate.toString(),
                                    140,
                                  ),
                                  _buildDataCell(item.interest.interest, 140),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataCell(String value, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: value,
        child: Text(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 13),
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
