import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kiruthikfab/models/agent_report_model.dart';
import 'package:kiruthikfab/screens/reports/agent_refer_report/refer_report_widget.dart';
import 'package:kiruthikfab/services/config.dart';

import '../../../indigator/main.dart';
import 'agent_detail_widgets.dart';
import 'generate_agent_report.dart';

class AgentDetailReport extends StatefulWidget {
  final int agentId;
  final String companyId;

  const AgentDetailReport({
    super.key,
    required this.agentId,
    required this.companyId,
  });

  @override
  State<AgentDetailReport> createState() => _AgentDetailReportState();
}

class _AgentDetailReportState extends State<AgentDetailReport> {
  AgentReportData? _agentDetails;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _error = '';
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  String _selectedFromDate = '';
  String _selectedToDate = '';

  @override
  void initState() {
    super.initState();
    _fetchAgentDetails();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchAgentDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agent_refer_report_agent.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'companyid': widget.companyId,
          'agent_id': widget.agentId.toString(),
          'from_date': _selectedFromDate,
          'to_date': _selectedToDate,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            if (data['agent_details'] != null) {
              _agentDetails = AgentReportData.fromJson(data['agent_details']);
            }
            _orders = (data['orders'] as List)
                .map((item) => OrderModel.fromJson(item))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['error'] ?? 'Failed to fetch details';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  void _exportPDF() async {
    exportAgentReportAgentPDF(
      companyId: widget.companyId,
      fromDate: _selectedFromDate,
      toDate: _selectedToDate,
      agentId: widget.agentId.toString(),
      context: context,
    );
  }

  void _exportExcel() async {
    exportAgentReportAgentExcel(
      companyId: widget.companyId,
      fromDate: _selectedFromDate,
      toDate: _selectedToDate,
      agentId: widget.agentId.toString(),
      context: context,
    );
  }

  void _printReport() async {
    printAgentReportAgent(
      companyId: widget.companyId,
      fromDate: _selectedFromDate,
      toDate: _selectedToDate,
      agentId: widget.agentId.toString(),
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBarAgent(
        context: context,
        title: _agentDetails?.agentName ?? 'Agent Details',
        fetchAgentReport: _fetchAgentDetails,
        exportPDF: _exportPDF,
        exportExcel: _exportExcel,
        printReport: _printReport,
      ),
      body: _isLoading
          ? const Center(child: CircularWaveProgress())
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(_error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchAgentDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 8,
                      bottom: 8,
                    ),
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
                            Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: ElevatedButton.icon(
                                onPressed: _fetchAgentDetails,
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
                                  _fromDateController.clear();
                                  _toDateController.clear();

                                  setState(() {
                                    _selectedFromDate = '';
                                    _selectedToDate = '';
                                  });

                                  _fetchAgentDetails();
                                },
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                ),
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
                  // Agent Summary Cards
                  if (_agentDetails != null) ...[
                    buildDetailSummaryCard(
                      'Total Orders',
                      '₹${NumberFormat('#,##0').format(_agentDetails!.totalOrderAmount)}',
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildDetailSummaryCard(
                            'Commission',
                            '₹${NumberFormat('#,##0').format(_agentDetails!.totalCommissionEarned)}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildDetailSummaryCard(
                            'Avg Order',
                            '₹${NumberFormat('#,##0').format(_agentDetails!.averageOrderValue)}',
                            Icons.trending_up,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildDetailSummaryCard(
                            'Sources',
                            '${_agentDetails!.totalSources}',
                            Icons.people,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildDetailSummaryCard(
                            'Invoices',
                            '${_agentDetails!.totalInvoices}',
                            Icons.receipt,
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Orders List
                  if (_orders.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Order History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return ListTile(
                          title: Text('Invoice: ${order.invoiceNo}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer: ${order.customerName}'),
                              Text('Date: ${order.date}'),
                            ],
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '₹${NumberFormat('#,##0').format(order.grandtotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                order.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: order.status == 'Paid'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No orders found for this agent'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
