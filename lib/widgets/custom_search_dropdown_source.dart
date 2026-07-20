import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class CustomDropdownSearchSource extends StatefulWidget {
  final String label;
  final bool isRequired;
  final List<Map<String, String>> items;
  final String? selectedItem;
  final ValueChanged<String?>? onChanged;
  final bool isCompact;
  final bool isReadOnly;
  final bool autoFocus;
  final GlobalKey<DropdownSearchState<String>>? dropdownKey;

  const CustomDropdownSearchSource({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.isCompact = false,
    this.isReadOnly = false,
    this.autoFocus = false,
    this.dropdownKey,
  });

  @override
  State<CustomDropdownSearchSource> createState() =>
      _CustomDropdownSearchSourceState();
}

class _CustomDropdownSearchSourceState
    extends State<CustomDropdownSearchSource> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<DropdownSearchState<String>> _internalDropdownKey =
      GlobalKey();

  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    // Initialize filtered items with all names
    _filteredItems = widget.items.map((item) => item['name']!).toList();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDropdown();
      });
    }
  }

  @override
  void didUpdateWidget(CustomDropdownSearchSource oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items.map((item) => item['name']!).toList();
    }
  }

  void _openDropdown() {
    if (!widget.isReadOnly && widget.items.isNotEmpty) {
      final key = widget.dropdownKey ?? _internalDropdownKey;
      key.currentState?.openDropDownSearch();
    }
  }

  // Custom filter function that searches both name and mobile
  void _filterItems(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        _filteredItems = widget.items.map((item) => item['name']!).toList();
      });
      return;
    }

    final searchLower = searchText.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) {
            final name = item['name']?.toLowerCase() ?? '';
            final mobile = item['mobile']?.toLowerCase() ?? '';
            return name.contains(searchLower) || mobile.contains(searchLower);
          })
          .map((item) => item['name']!)
          .toList();
    });
  }

  void _handleEnterKeySelection(String searchText) {
    if (searchText.isEmpty) return;

    _filterItems(searchText);

    if (_filteredItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No matching item found for "$searchText"')),
      );
      return;
    }

    _selectItem(_filteredItems.first);
  }

  void _selectItem(String item) {
    if (widget.onChanged != null) {
      if (widget.isRequired && item.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("This field is required")));
      } else {
        widget.onChanged!(item);
        // Close the dropdown after selection
        final key = widget.dropdownKey ?? _internalDropdownKey;
        key.currentState?.closeDropDownSearch();
        // Clear search
        _searchController.clear();
        // Reset filtered items
        _filteredItems = widget.items.map((item) => item['name']!).toList();
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border({Color color = const Color(0xFFD1D5DB)}) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(6),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: RichText(
              text: TextSpan(
                text: widget.label,
                style: TextStyle(
                  color: widget.isReadOnly
                      ? const Color(0xFF111827)
                      : const Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: widget.isRequired
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        DropdownSearch<String>(
          filterFn: (item, filter) => true,
          key: widget.dropdownKey ?? _internalDropdownKey,
          items: (filter, loadProps) {
            // Return filtered items based on search
            if (filter.isNotEmpty) {
              final searchLower = filter.toLowerCase();
              return widget.items
                  .where((item) {
                    final name = item['name']?.toLowerCase() ?? '';
                    final mobile = item['mobile']?.toLowerCase() ?? '';
                    return name.contains(searchLower) ||
                        mobile.contains(searchLower);
                  })
                  .map((item) => item['name']!)
                  .toList();
            }
            return widget.items.map((item) => item['name']!).toList();
          },
          selectedItem: widget.selectedItem,
          enabled: !widget.isReadOnly,
          onSelected: widget.isReadOnly
              ? null
              : (value) {
                  if (widget.isRequired && (value == null || value.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("This field is required")),
                    );
                    return;
                  }
                  widget.onChanged?.call(value);
                  // Clear search after selection
                  _searchController.clear();
                },
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(
              fontSize: 14,
              color: widget.isReadOnly ? const Color(0xFF111827) : Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.isReadOnly
                  ? const Color(0xFFF3F4F6)
                  : const Color(0xFFF3F4F6),
              border: border(),
              enabledBorder: border(),
              focusedBorder: border(),
              disabledBorder: border(color: const Color(0xFFD1D5DB)),
              isDense: widget.isCompact,
              contentPadding: widget.isCompact
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              hintStyle: TextStyle(
                color: widget.isReadOnly
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              controller: _searchController,
              autofocus: widget.autoFocus,

              decoration: InputDecoration(
                hintText: 'Search by name or mobile...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    // Trigger rebuild with empty search
                    setState(() {});
                  },
                ),
              ),
              onSubmitted: _handleEnterKeySelection,
            ),
            itemBuilder: (context, item, isSelected, isDisabled) {
              // Find the mobile number for this name
              final matchedItem = widget.items.firstWhere(
                (element) => element['name'] == item,
                orElse: () => {},
              );
              final mobile = matchedItem['mobile'] ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    if (mobile.isNotEmpty)
                      Text(
                        mobile,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              );
            },
            menuProps: MenuProps(
              elevation: 6,
              color: Colors.white,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
