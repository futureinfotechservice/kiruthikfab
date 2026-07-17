import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiruthikfab/models/inward_entry_model.dart';

Widget buildInfoTile(String label, String value, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ],
  );
}

Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blue.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    validator: validator,
  );
}

// Main widget with state management
class InwardListView extends StatefulWidget {
  final List<InwardEntry> inward;
  final bool isFull;

  const InwardListView({super.key, required this.inward, required this.isFull});

  @override
  State<InwardListView> createState() => _InwardListViewState();
}

class _InwardListViewState extends State<InwardListView> {
  // Track expanded states for each inventory group
  final Map<String, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    return buildInward(widget.inward, widget.isFull);
  }

  Widget buildInward(List<InwardEntry> inward, bool isFull) {
    // Group entries by inventoryNumber when isFull is true
    Map<String, List<InwardEntry>> groupedEntries = {};
    if (isFull) {
      for (var entry in inward) {
        if (!groupedEntries.containsKey(entry.inventoryNumber)) {
          groupedEntries[entry.inventoryNumber] = [];
        }
        groupedEntries[entry.inventoryNumber]!.add(entry);
      }
    }

    // Initialize expansion states if not already set
    if (isFull) {
      for (var key in groupedEntries.keys) {
        if (!_expandedStates.containsKey(key)) {
          _expandedStates[key] = false; // Default collapsed
        }
      }
    }

    if (!isFull) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: inward.length,
        itemBuilder: (context, index) {
          final entry = inward[index];
          return _buildCompactCard(entry);
        },
      );
    } else {
      return ListView.builder(
        //shrinkWrap: true,
        //physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: groupedEntries.keys.length,
        itemBuilder: (context, index) {
          final inventoryNumber = groupedEntries.keys.elementAt(index);
          final entries = groupedEntries[inventoryNumber]!;
          return _buildGroupedCard(
            inventoryNumber,
            entries,
            _expandedStates[inventoryNumber] ?? false,
            (bool expanded) {
              setState(() {
                _expandedStates[inventoryNumber] = expanded;
              });
            },
          );
        },
      );
    }
  }

  Widget _buildCompactCard(InwardEntry entry) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: buildInfoTile('Stock', entry.stock, Icons.numbers),
                ),
                Expanded(
                  flex: 2,
                  child: buildInfoTile(
                    'Amount',
                    '₹${entry.amount}',
                    Icons.currency_rupee,
                  ),
                ),
                if (entry.manufacturer.isNotEmpty &&
                    entry.manufacturer != "null")
                  Expanded(
                    flex: 2,
                    child: buildInfoTile(
                      'Manufacturer',
                      entry.manufacturer,
                      Icons.factory,
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.createdAt.isNotEmpty
                        ? DateFormat(
                            'dd-MM-yyyy HH:mm',
                          ).format(DateTime.parse(entry.createdAt))
                        : '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedCard(
    String inventoryNumber,
    List<InwardEntry> entries,
    bool isExpanded,
    Function(bool) onToggle,
  ) {
    final firstEntry = entries.first;

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with inventory number and expand/collapse
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100.withOpacity(0.5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inventory number and badge with expand button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory #$inventoryNumber',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            '${entries.length} items • ${firstEntry.productName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand/Collapse button
                    GestureDetector(
                      onTap: () {
                        onToggle(!isExpanded);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Common details with modern design
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade100.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade50,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModernInfoTile(
                        'Product',
                        firstEntry.productName,
                        Icons.inventory_2_outlined,
                        Colors.purple,
                      ),
                      _buildModernInfoTile(
                        'Model',
                        firstEntry.modelName,
                        Icons.factory,
                        Colors.orange,
                      ),
                      _buildModernInfoTile(
                        'Unit',
                        firstEntry.unitName,
                        Icons.category_outlined,
                        Colors.green,
                      ),
                      _buildModernInfoTile(
                        'Size',
                        firstEntry.sizeName,
                        Icons.numbers,
                        Colors.teal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Animated expand/collapse section
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                'Tap to expand',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade50,
                          Colors.grey.shade100.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200.withOpacity(0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item header with number and quick stats
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Item ${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Quick stock badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: int.parse(item.stock) > 100
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory,
                                    size: 12,
                                    color: int.parse(item.stock) > 100
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Qty: ${item.stock}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: int.parse(item.stock) > 100
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (item.createdAt.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'dd-MM-yyyy HH:mm',
                                      ).format(DateTime.parse(item.createdAt)),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Item details in a responsive grid
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildCompactInfoTile(
                              'Stock',
                              item.stock.toString(),
                              Icons.numbers,
                              Colors.blue,
                            ),
                            _buildCompactInfoTile(
                              'Amount',
                              '₹${item.amount}',
                              Icons.currency_rupee,
                              Colors.green,
                            ),
                            if (item.manufacturer.isNotEmpty &&
                                item.manufacturer != "null")
                              _buildCompactInfoTile(
                                'Manufacturer',
                                item.manufacturer,
                                Icons.factory,
                                Colors.orange,
                              ),
                            // Status indicator
                            _buildStatusIndicator(item),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(InwardEntry entry) {
    final stockValue = int.tryParse(entry.stock) ?? 0;
    final status = stockValue > 100 ? 'In Stock' : 'Low Stock';
    final color = stockValue > 100 ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// // Helper widget - make sure this is defined elsewhere or add it here
// Widget buildInfoTile(String label, String value, IconData icon) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         label,
//         style: const TextStyle(
//           fontSize: 12,
//           color: Colors.grey,
//         ),
//       ),
//       const SizedBox(height: 2),
//       Row(
//         children: [
//           Icon(icon, size: 14, color: Colors.grey.shade600),
//           const SizedBox(width: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     ],
//   );
// }
