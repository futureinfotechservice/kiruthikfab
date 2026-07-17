import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kiruthikfab/models/stock_ledger_model.dart';

void showErrorSnackBar(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Widget buildInfoChip(String label, String value, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
  );
}

Widget buildSummaryItem(
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 8,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    ),
  );
}

Widget buildTransactionCard(StockLedgerTransaction transaction, int index) {
  final isInward = transaction.transactionType == 'INWARD';
  final color = isInward ? Colors.green : Colors.red;
  final icon = isInward ? Icons.arrow_downward : Icons.arrow_upward;

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
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: InkWell(
              onTap: () => _showTransactionDetails(transaction, context),
              onLongPress: () => _showQuickActions(transaction, context),
              borderRadius: BorderRadius.circular(12),
              splashColor: color.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: color, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                transaction.transactionType,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Balance: ${transaction.closingStock}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.inventoryNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                transaction.productName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${transaction.quantity} ${transaction.unitName}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTransactionInfo(
                          'Date',
                          DateFormat(
                            'dd-MM-yyyy HH:mm:ss',
                          ).format(transaction.date),
                          Icons.calendar_today,
                        ),
                        const SizedBox(width: 8),
                        _buildTransactionInfo(
                          'Rate',
                          '₹${transaction.rate.toStringAsFixed(2)}',
                          Icons.currency_rupee,
                        ),
                        const SizedBox(width: 8),
                        _buildTransactionInfo(
                          'Amount',
                          '₹${transaction.amount.toStringAsFixed(2)}',
                          Icons.payments,
                        ),
                        if (transaction.manufacturer != null &&
                            transaction.manufacturer!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.factory,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  transaction.manufacturer!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (transaction.referenceNumber != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text(
                              'Ref: ${transaction.referenceNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
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

Widget _buildTransactionInfo(String label, String value, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
  );
}

Widget buildTransactionGridCard(
  StockLedgerTransaction transaction,
  BuildContext context,
) {
  final isInward = transaction.transactionType == 'INWARD';
  final color = isInward ? Colors.green : Colors.red;
  final icon = isInward ? Icons.arrow_downward : Icons.arrow_upward;

  return Card(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
    ),
    child: InkWell(
      onTap: () => _showTransactionDetails(transaction, context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        transaction.transactionType,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd-MM-yyyy HH:mm:ss').format(transaction.date),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              transaction.inventoryNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              transaction.productName,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${transaction.quantity}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transaction.unitName,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGridInfo(
                  'Rate',
                  '₹${transaction.rate.toStringAsFixed(0)}',
                ),
                _buildGridInfo(
                  'Amount',
                  '₹${transaction.amount.toStringAsFixed(0)}',
                ),
                _buildGridInfo('Balance', transaction.closingStock.toString()),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildGridInfo(String label, String value) {
  return Expanded(
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
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget buildEmptyState({required Function() fetchLedgerData}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'No ledger entries found',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try adjusting your filters or select an inventory',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: fetchLedgerData,
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

void shareTransaction(
  StockLedgerTransaction transaction,
  BuildContext context,
) {
  // Implement share functionality
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Share functionality coming soon')),
  );
}

void copyToClipboard(String text, BuildContext context) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Copied to clipboard'),
      duration: Duration(seconds: 1),
    ),
  );
}

Color getStockColor(int stock) {
  if (stock == 0) return Colors.red;
  if (stock <= 10) return Colors.orange;
  return Colors.green;
}

Widget _buildDetailCard(String title, List<Widget> children) {
  return Card(
    color: Colors.white,
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

Widget buildDetailRow(
  String label,
  String value,
  BuildContext context, {
  Color? color,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showTransactionDetails(
  StockLedgerTransaction transaction,
  BuildContext context,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final isInward = transaction.transactionType == 'INWARD';
          final color = isInward ? Colors.green : Colors.red;

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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isInward ? Icons.arrow_downward : Icons.arrow_upward,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.transactionType,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            transaction.inventoryNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${transaction.quantity} ${transaction.unitName}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailCard('Transaction Details', [
                        buildDetailRow(
                          'Date',
                          DateFormat(
                            'dd-MM-yyyy HH:mm:ss',
                          ).format(transaction.date),
                          context,
                        ),
                        buildDetailRow(
                          'Type',
                          transaction.transactionType,
                          context,
                          color: color,
                        ),
                        buildDetailRow(
                          'Quantity',
                          '${transaction.quantity} ${transaction.unitName}',
                          context,
                        ),
                        buildDetailRow(
                          'Rate',
                          '₹${transaction.rate.toStringAsFixed(2)}',
                          context,
                        ),
                        buildDetailRow(
                          'Amount',
                          '₹${transaction.amount.toStringAsFixed(2)}',
                          context,
                        ),
                        if (transaction.referenceNumber != null)
                          buildDetailRow(
                            'Reference',
                            transaction.referenceNumber!,
                            context,
                          ),
                        if (transaction.addedBy != null)
                          buildDetailRow(
                            'Added By',
                            transaction.addedBy!,
                            context,
                          ),
                      ]),
                      const SizedBox(height: 12),
                      _buildDetailCard('Product Details', [
                        buildDetailRow(
                          'Product',
                          transaction.productName,
                          context,
                        ),
                        buildDetailRow('Model', transaction.modelName, context),
                        buildDetailRow('Size', transaction.sizeName, context),
                        buildDetailRow('Unit', transaction.unitName, context),
                        if (transaction.manufacturer != null)
                          buildDetailRow(
                            'Manufacturer',
                            transaction.manufacturer!,
                            context,
                          ),
                      ]),
                      const SizedBox(height: 12),
                      _buildDetailCard('Stock Movement', [
                        buildDetailRow(
                          'Opening Stock',
                          transaction.openingStock.toString(),
                          context,
                        ),
                        buildDetailRow(
                          'Stock In',
                          transaction.stockIn.toString(),
                          context,
                          color: Colors.green,
                        ),
                        buildDetailRow(
                          'Stock Out',
                          transaction.stockOut.toString(),
                          context,
                          color: Colors.red,
                        ),
                        buildDetailRow(
                          'Closing Stock',
                          transaction.closingStock.toString(),
                          context,
                          color: Colors.blue,
                        ),
                        buildDetailRow(
                          'Calculated Balance',
                          transaction.calculatedBalance.toString(),
                          context,
                          color: Colors.orange,
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
                                copyToClipboard(transaction.id, context);
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy ID'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: const Color(0xFFFFFFFF),
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

void _showQuickActions(
  StockLedgerTransaction transaction,
  BuildContext context,
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
                _showTransactionDetails(transaction, context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.purple),
              title: const Text('Copy Transaction ID'),
              onTap: () {
                Navigator.pop(context);
                copyToClipboard(transaction.id, context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share Transaction'),
              onTap: () {
                Navigator.pop(context);
                shareTransaction(transaction, context);
              },
            ),
          ],
        ),
      );
    },
  );
}
