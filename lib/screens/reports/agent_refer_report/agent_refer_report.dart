import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kiruthikfab/models/agent_report_model.dart';
import 'package:kiruthikfab/screens/reports/agent_refer_report/refer_report_widget.dart';
import 'package:kiruthikfab/services/config.dart';
import 'package:kiruthikfab/widgets/customdropdownwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/source_apiservice.dart';
import 'agent_detail_report.dart';
import 'generates_refer_report.dart';

class AgentReferReport extends StatefulWidget {
  const AgentReferReport({super.key});

  @override
  State<AgentReferReport> createState() => _AgentReferReportState();
}

class _AgentReferReportState extends State<AgentReferReport> {
  List<AgentReportData> _agents = [];
  AgentReferReportModel? _summary;
  bool _isLoading = true;
  String _error = '';
  String _companyId = '';
  String _userType = '';

  String _selectedAgentId = '';
  String _selectedAgentName = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  List<Map<String, dynamic>> _allAgents = [];
  final SourceApiService _apiService = SourceApiService();

  String _selectedFromDate = '';
  String _selectedToDate = '';

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Future.wait([_fetchAgentReport(), _fetchAgents()]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchAgents() async {
    _allAgents = await _apiService.fetchAgents(context);
  }

  Future<void> _fetchAgentReport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyid') ?? '';
    _userType = prefs.getString('user_type') ?? '';
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final requestBody = {'companyid': _companyId};

      // Add agent ID if selected
      if (_selectedAgentId.isNotEmpty) {
        requestBody['agent_id'] = _selectedAgentId;
      }

      // Add date filters if selected
      if (_selectedFromDate.isNotEmpty) {
        requestBody['from_date'] = _selectedFromDate;
      }
      if (_selectedToDate.isNotEmpty) {
        requestBody['to_date'] = _selectedToDate;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/agent_refer_report.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _agents = (data['data'] as List)
                .map((item) => AgentReportData.fromJson(item))
                .toList();
            _summary = AgentReferReportModel.fromJson(data['summary']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['error'] ?? 'Failed to fetch data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  void _filterByAgent(String? agentName) {
    setState(() {
      if (agentName == null || agentName == 'All Agents') {
        _selectedAgentId = '';
        _selectedAgentName = '';
      } else {
        _selectedAgentName = agentName;
        final agent = _allAgents.firstWhere(
          (a) => a['name'] == agentName,
          orElse: () => {},
        );
        _selectedAgentId = agent['id']?.toString() ?? '';
      }
    });
  }

  void _viewAgentDetails(AgentReportData agent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AgentDetailReport(agentId: agent.agentId, companyId: _companyId),
      ),
    );
  }

  void _exportPDF() async {
    exportAgentReportPDF(
      companyId: _companyId,
      fromDate: _selectedFromDate,
      toDate: _selectedToDate,
      agentId: _selectedAgentId.isNotEmpty ? _selectedAgentId : null,
      searchQuery: null,
      context: context,
    );
  }

  void _exportExcel() async {
    exportAgentReportExcel(
      companyId: _companyId,
      fromDate: _selectedFromDate,
      toDate: _selectedToDate,
      agentId: _selectedAgentId.isNotEmpty ? _selectedAgentId : null,
      searchQuery: null,
      context: context,
    );
  }

  void _printReport() async {
    printAgentReport(
      companyId: _companyId,
      fromDate: _selectedFromDate,
      toDate: _selectedToDate,
      agentId: _selectedAgentId.isNotEmpty ? _selectedAgentId : null,
      searchQuery: null,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(
        context: context,
        exportExcel: _exportExcel,
        exportPDF: _exportPDF,
        fetchAgentReport: _fetchAgentReport,
        printReport: _printReport,
        userType: _userType,
      ),
      body: Column(
        children: [
          // Filters Row
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("From Date"),
                          const SizedBox(height: 8),
                          buildDate(
                            'From Date',
                            _fromDateController,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedFromDate = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(picked);
                                  _fromDateController.text = DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(picked);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("From Date"),
                          const SizedBox(height: 8),
                          buildDate(
                            'To Date',
                            _toDateController,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedToDate = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(picked);
                                  _toDateController.text = DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(picked);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomDropdownSearch(
                        selectedItem: _selectedAgentName.isEmpty
                            ? null
                            : _selectedAgentName,
                        label: 'Agent',
                        items: [
                          'All Agents',
                          ..._allAgents.map(
                            (agent) => agent['name'].toString(),
                          ),
                        ],
                        onChanged: (value) => _filterByAgent(value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0),
                      child: ElevatedButton.icon(
                        onPressed: _fetchAgentReport,
                        icon: const Icon(Icons.filter_alt),
                        label: const Text(
                          'Filter',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(100, 45),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Padding(
                      padding: const EdgeInsets.only(top: 18.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _searchController.clear();

                          _fromDateController.clear();
                          _toDateController.clear();

                          setState(() {
                            _selectedAgentName = '';
                            _selectedAgentId = '';
                            _selectedFromDate = '';
                            _selectedToDate = '';
                          });

                          _fetchAgentReport();
                        },
                        icon: const Icon(Icons.clear, color: Colors.white),
                        label: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(100, 45),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Summary Cards
          if (_summary != null && !_isLoading) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: buildSummaryCard(
                        'Total Orders',
                        '₹${NumberFormat('#,##0').format(_summary!.totalOrderAmount)}',
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: buildSummaryCard(
                        'Total Subtotal',
                        '₹${NumberFormat('#,##0').format(_summary!.totalSubtotal)}',
                        Icons.shopping_cart,
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: buildSummaryCard(
                        'Total Commission',
                        '₹${NumberFormat('#,##0').format(_summary!.totalCommission)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: buildSummaryCard(
                        'Invoices',
                        '${_summary!.totalInvoices}',
                        Icons.receipt,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: buildSummaryCard(
                        'Sources',
                        '${_summary!.totalSources}',
                        Icons.people,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: buildSummaryCard(
                        'Avg Order',
                        '₹${NumberFormat('#,##0').format(_summary!.averageOrderValue)}',
                        Icons.trending_up,
                        Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],

          // Top Performer
          if (_summary != null &&
              _summary!.topPerformer != null &&
              !_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[300]!, Colors.amber[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏆 Top Performer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _summary!.topPerformer!.agentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Text(
                            'Orders: ₹${NumberFormat('#,##0').format(_summary!.topPerformer!.totalOrderAmount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Commission: ₹${NumberFormat('#,##0').format(_summary!.topPerformer!.totalCommissionEarned)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Agents List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAgentReport,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _agents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No agents found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _agents.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final agent = _agents[index];
                      return buildAgentCard(agent, _viewAgentDetails);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
