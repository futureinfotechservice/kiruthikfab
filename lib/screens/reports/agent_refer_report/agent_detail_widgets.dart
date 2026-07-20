import 'package:flutter/material.dart';

Widget buildDetailSummaryCard(
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
          blurRadius: 3,
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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

AppBar buildAppBarAgent({
  required BuildContext context,
  required String title,
  required VoidCallback fetchAgentReport,
  required VoidCallback exportPDF,
  required VoidCallback exportExcel,
  required VoidCallback printReport,
}) {
  return AppBar(
    title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),

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
