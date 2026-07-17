import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/stock_statement_model.dart';
import '../../navigation_provider.dart';

void showErrorSnackBar(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFD32F2F),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Widget buildSummaryCard(
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

Widget buildInfoChip(String label, String value, IconData icon, Color color) {
  return Container(
    width: 150,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.02)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildEmptyState(VoidCallback fetchStockStatement) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'No stock items found',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try adjusting your search or filters',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: fetchStockStatement,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildStockItemCard(StockStatementItem item, int index, String userType) {
  final status = item.calculatedStock == 0
      ? 'Out of Stock'
      : item.calculatedStock <= 10
      ? 'Low Stock'
      : 'In Stock';

  final color = item.calculatedStock == 0
      ? Colors.red
      : item.calculatedStock <= 10
      ? Colors.orange
      : Colors.green;

  final statusIcon = item.calculatedStock == 0
      ? Icons.cancel_outlined
      : item.calculatedStock <= 10
      ? Icons.warning_amber_outlined
      : Icons.check_circle_outline;

  return TweenAnimationBuilder<double>(
    duration: Duration(milliseconds: 300 + (index * 50)),
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: Opacity(
          opacity: value,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: InkWell(
              onTap: () => _showStockDetails(item, context, userType),
              onLongPress: () => _showQuickActions(item, context, userType),
              borderRadius: BorderRadius.circular(16),
              splashColor: color.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Status
                    Row(
                      children: [
                        // Stock Status Badge
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.15),
                                color.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.inventoryNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.productName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.15),
                                color.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: color, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.calculatedStock} ${item.unitName}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Info Grid
                    Row(
                      children: [
                        buildInfoChip(
                          'Model',
                          item.modelName,
                          Icons.factory,
                          Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        buildInfoChip(
                          'Size',
                          item.sizeName,
                          Icons.aspect_ratio,
                          Colors.purple.shade700,
                        ),
                        const SizedBox(width: 8),
                        if ((item.manufacturer != null ||
                            item.lastTransactionDate != null))
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  if (item.manufacturer != null) ...[
                                    Icon(
                                      Icons.business,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.manufacturer!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  if (item.manufacturer != null &&
                                      item.lastTransactionDate != null)
                                    Container(
                                      width: 1,
                                      height: 16,
                                      color: Colors.grey.shade300,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  if (item.lastTransactionDate != null)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.history,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat(
                                              'dd-MM-yyyy HH:mm',
                                            ).format(item.lastTransactionDate!),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget buildGridItemCard(StockStatementItem item, int index, String userType) {
  final status = item.calculatedStock == 0
      ? 'Out of Stock'
      : item.calculatedStock <= 10
      ? 'Low Stock'
      : 'In Stock';

  final color = item.calculatedStock == 0
      ? Colors.red
      : item.calculatedStock <= 10
      ? Colors.orange
      : Colors.green;

  return TweenAnimationBuilder<double>(
    duration: Duration(milliseconds: 300 + (index * 50)),
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: Opacity(
          opacity: value,
          child: Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: InkWell(
              onTap: () => _showStockDetails(item, context, userType),
              onLongPress: () => _showQuickActions(item, context, userType),
              borderRadius: BorderRadius.circular(16),
              splashColor: color.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.15),
                                color.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.inventoryNumber,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.productName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.15),
                                color.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                status == 'Out of Stock'
                                    ? Icons.cancel_outlined
                                    : status == 'Low Stock'
                                    ? Icons.warning_amber_outlined
                                    : Icons.check_circle_outline,
                                color: color,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Stock Info
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.numbers, size: 16, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '${item.calculatedStock}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.unitName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Details Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridInfo('Model', item.modelName),
                        ),
                        Expanded(child: _buildGridInfo('Size', item.sizeName)),
                      ],
                    ),

                    if (item.lastTransactionDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 10,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'dd-MM-yyyy HH:mm',
                              ).format(item.lastTransactionDate!),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildGridInfo(String label, String value) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

void _showQuickActions(
  StockStatementItem item,
  BuildContext context,
  String userType,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showStockDetails(item, context, userType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('View Ledger'),
              onTap: () {
                Navigator.pop(context);
                _navigateToLedger(item, context, userType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share Stock Info'),
              onTap: () {
                Navigator.pop(context);
                _shareStockInfo(item, context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.purple),
              title: const Text('Copy Inventory ID'),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(item.inventoryNumber, context);
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showStockDetails(
  StockStatementItem item,
  BuildContext context,
  String userType,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.inventoryNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailCard('Basic Information', [
                        _buildDetailRow(
                          'Inventory Number',
                          item.inventoryNumber,
                        ),
                        _buildDetailRow('Product', item.productName),
                        _buildDetailRow('Model', item.modelName),
                        _buildDetailRow('Size', item.sizeName),
                        _buildDetailRow('Unit', item.unitName),
                        if (item.manufacturer != null)
                          _buildDetailRow('Manufacturer', item.manufacturer!),
                      ]),
                      const SizedBox(height: 12),
                      _buildDetailCard('Stock Information', [
                        _buildDetailRow(
                          'Current Stock',
                          item.calculatedStock.toString(),
                          color: _getStockColor(item.calculatedStock),
                        ),
                        _buildDetailRow(
                          'Opening Stock',
                          item.openingStock.toString(),
                        ),
                        _buildDetailRow(
                          'Inward Stock',
                          item.inwardStocks.toString(),
                          color: Colors.green,
                        ),
                        _buildDetailRow(
                          'Outward Stock',
                          item.outwardStocks.toString(),
                          color: Colors.red,
                        ),
                        _buildDetailRow(
                          'Calculated Stock',
                          item.calculatedStock.toString(),
                          color: Colors.orange,
                        ),
                        _buildDetailRow(
                          'Stock Status',
                          _getStockStatus(item.calculatedStock),
                          color: _getStockColor(item.calculatedStock),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildDetailCard('Timestamps', [
                        if (item.lastTransactionDate != null)
                          _buildDetailRow(
                            'Last Transaction',
                            DateFormat(
                              'dd-MM-yyyy HH:mm',
                            ).format(item.lastTransactionDate!),
                          ),
                        if (item.createdAt != null)
                          _buildDetailRow(
                            'Created At',
                            DateFormat(
                              'dd-MM-yyyy HH:mm',
                            ).format(item.createdAt!),
                          ),
                      ]),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateToLedger(item, context, userType);
                              },
                              icon: const Icon(Icons.history),
                              label: const Text('View Ledger'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildDetailCard(String title, List<Widget> children) {
  return Card(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

Widget _buildDetailRow(String label, String value, {Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

void _navigateToLedger(
  StockStatementItem item,
  BuildContext context,
  String userType,
) {
  final navProvider = context.read<NavigationProvider>();

  navProvider.updateInventory(inventoryNo: item.id);
  if (userType.toUpperCase() == "ADMIN") {
    navProvider.updateIndex(
      selectedIndex: 3,
      reportSubIndex: 3,
      masterSubIndex: 0,
      entrySubIndex: 0,
    );
  } else {
    navProvider.updateIndex(
      selectedIndex: 2,
      reportSubIndex: 3,
      masterSubIndex: 0,
      entrySubIndex: 0,
    );
  }

  // Navigator.push(
  //   context,
  //   MaterialPageRoute(
  //     builder: (context) => StockLedgerPage(initialInventoryId: item.id),
  //   ),
  // );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Viewing ledger for ${item.inventoryNumber}'),
      backgroundColor: Colors.blue.shade700,
    ),
  );
}

void _shareStockInfo(StockStatementItem item, BuildContext context) {
  // Implement share functionality
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Share functionality coming soon')),
  );
}

String _getStockStatus(int stock) {
  if (stock == 0) return 'Out of Stock';
  if (stock <= 10) return 'Low Stock';
  return 'In Stock';
}

Color _getStockColor(int stock) {
  if (stock == 0) return Colors.red;
  if (stock <= 10) return Colors.orange;
  return Colors.green;
}

void _copyToClipboard(String text, BuildContext context) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Copied to clipboard'),
      duration: Duration(seconds: 1),
    ),
  );
}
