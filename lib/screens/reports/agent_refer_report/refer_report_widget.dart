import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiruthikfab/models/agent_report_model.dart';
import 'package:kiruthikfab/screens/navigation_provider.dart';
import 'package:provider/provider.dart';

Widget buildDate(
  String label,
  TextEditingController controller, {
  required GestureTapCallback onTap,
}) {
  return TextFormField(
    controller: controller,
    readOnly: true,
    onTap: onTap,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.calendar_today_rounded, color: Colors.blue),
      suffixIcon: const Icon(Icons.arrow_drop_down),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    ),
  );
}

AppBar buildAppBar({
  required BuildContext context,
  required String userType,
  required VoidCallback fetchAgentReport,
  required VoidCallback exportPDF,
  required VoidCallback exportExcel,
  required VoidCallback printReport,
}) {
  final navProvider = context.watch<NavigationProvider>();

  return AppBar(
    title: const Text(
      'Agent Refer Report',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    leading: IconButton(
      onPressed: () {
        if (userType.toUpperCase() == "ADMIN") {
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
        onPressed: fetchAgentReport,
        tooltip: 'Refresh',
      ),
      PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'export_pdf':
              exportPDF();
              break;
            case 'export_excel':
              exportExcel();
              break;
            case 'print':
              printReport();
              break;
          }
        },
        itemBuilder: (context) => [
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

Widget buildSummaryCard(
  String title,
  String value,
  IconData icon,
  Color color,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 1,
          blurRadius: 5,
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildAgentCard(
  AgentReportData agent,
  Function(AgentReportData) viewAgentDetails,
) {
  Color performanceColor;
  IconData performanceIcon;

  switch (agent.performanceLevel) {
    case 'High':
      performanceColor = Colors.green;
      performanceIcon = Icons.trending_up;
      break;
    case 'Medium':
      performanceColor = Colors.orange;
      performanceIcon = Icons.trending_flat;
      break;
    default:
      performanceColor = Colors.red;
      performanceIcon = Icons.trending_down;
      break;
  }

  return Card(
    color: Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: () => viewAgentDetails(agent),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    agent.agentName.isNotEmpty
                        ? agent.agentName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.agentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: performanceColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  performanceIcon,
                                  color: performanceColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  agent.performanceLevel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: performanceColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${agent.totalInvoices} invoices',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${agent.totalSources} sources',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Subtotal: ₹${NumberFormat('#,##0').format(agent.totalSubtotal)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Commission: ${agent.commissionPercentage}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${NumberFormat('#,##0').format(agent.totalOrderAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Comm: ₹${NumberFormat('#,##0').format(agent.totalCommissionEarned)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
