import 'package:flutter/material.dart';
import 'package:kiruthikfab/services/inventory_api_service.dart';

import 'inventory_master.dart';

class CollapsibleProductGroup extends StatefulWidget {
  final String productName;
  final List<InventoryItem> items;
  final bool isNew;
  final Function(InventoryItem) onRemoveItem;
  final Function init;

  const CollapsibleProductGroup({
    super.key,
    required this.productName,
    required this.items,
    required this.isNew,
    required this.onRemoveItem,
    required this.init,
  });

  @override
  State<CollapsibleProductGroup> createState() =>
      _CollapsibleProductGroupState();
}

class _CollapsibleProductGroupState extends State<CollapsibleProductGroup> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: widget.isNew ? Colors.green.shade50 : Colors.white,
      child: Column(
        children: [
          // Header - Always visible
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isNew
                    ? Colors.green.shade100
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${widget.items.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isNew
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            title: Text(
              widget.productName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: widget.isNew ? Colors.green.shade800 : Colors.black87,
              ),
            ),
            subtitle: Text(
              widget.isNew
                  ? '${widget.items.length} new combinations • Click to expand'
                  : '${widget.items.length} combinations • Click to expand',
              style: TextStyle(
                fontSize: 12,
                color: widget.isNew
                    ? Colors.green.shade600
                    : Colors.grey.shade600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isNew) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),

          // Expanded content - Show details when expanded
          if (_isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: widget.items.asMap().entries.map((entry) {
                  // int index = entry.key;
                  InventoryItem item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    elevation: 0,
                    color: widget.isNew
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 90,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.isNew
                              ? Colors.green.shade100
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            item.inventoryid,
                            // '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: widget.isNew
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        '${item.modelName} • ${item.sizeName} • ${item.unitName}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Opening Stock: ${item.openingStock}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (widget.isNew) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () => widget.onRemoveItem(item),
                            ),
                          ] else ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade400,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () async {
                                final res = await InventoryApiService()
                                    .deleteInventory(context, item.id);
                                if (res == 'Success') {
                                  widget.init();
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
