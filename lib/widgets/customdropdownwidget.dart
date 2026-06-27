import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class CustomDropdownSearch extends StatefulWidget {
  final String label;
  final bool isRequired;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?>? onChanged;
  final bool isCompact;
  final bool isReadOnly;
  final bool autoFocus;
  final GlobalKey<DropdownSearchState<String>>?
  dropdownKey; // Added dropdownKey

  const CustomDropdownSearch({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.isCompact = false,
    this.isReadOnly = false,
    this.autoFocus = false,
    this.dropdownKey, // Added dropdownKey parameter
  });

  @override
  State<CustomDropdownSearch> createState() => _CustomDropdownSearchState();
}

class _CustomDropdownSearchState extends State<CustomDropdownSearch> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<DropdownSearchState<String>> _internalDropdownKey =
      GlobalKey();

  // Track if dropdown is open
  // bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();

    // Auto-focus handling
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDropdown();
      });
    }
  }

  void _openDropdown() {
    if (!widget.isReadOnly && widget.items.isNotEmpty) {
      // Use the provided key or internal key
      final key = widget.dropdownKey ?? _internalDropdownKey;
      key.currentState?.openDropDownSearch();
    }
  }

  void _handleEnterKeySelection(String searchText) {
    if (searchText.isEmpty) return;

    final filteredItems = widget.items
        .where((item) => item.toLowerCase().contains(searchText.toLowerCase()))
        .toList();

    if (filteredItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No matching item found for "$searchText"')),
      );
      return;
    }

    _selectItem(filteredItems.first);
  }

  void _selectItem(String item) {
    if (widget.onChanged != null) {
      if (widget.isRequired && item.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("This field is required")));
      } else {
        widget.onChanged!(item);
        Navigator.of(context).pop();
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
    OutlineInputBorder _border({Color color = const Color(0xFFD1D5DB)}) {
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
          key: widget.dropdownKey ?? _internalDropdownKey,
          items: (filter, loadProps) => widget.items,
          selectedItem: widget.selectedItem,
          enabled: !widget.isReadOnly,
          onChanged: widget.isReadOnly
              ? null
              : (value) {
                  if (widget.isRequired && (value == null || value.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("This field is required")),
                    );
                    return;
                  }
                  widget.onChanged?.call(value);
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
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(),
              disabledBorder: _border(color: const Color(0xFFD1D5DB)),
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
                hintText: 'Search...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
              onSubmitted: _handleEnterKeySelection,
            ),
            menuProps: MenuProps(
              borderRadius: BorderRadius.circular(12),
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

class CustomDropdownSearchonlybox extends StatelessWidget {
  final String? label;
  final bool isRequired;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?>? onChanged;
  final bool isCompact;
  final bool isReadOnly;
  final bool autoFocus;
  final GlobalKey<DropdownSearchState<String>>? dropdownKey;

  const CustomDropdownSearchonlybox({
    super.key,
    this.label,
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
  Widget build(BuildContext context) {
    OutlineInputBorder _border({Color color = const Color(0xFFE5E7EB)}) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.circular(6),
      );
    }

    return SizedBox(
      height: 40,
      child: DropdownSearch<String>(
        key: dropdownKey,
        items: (filter, loadProps) => items,
        selectedItem: selectedItem,
        enabled: !isReadOnly,
        onChanged: isReadOnly
            ? null
            : (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("This field is required")),
                  );
                  return;
                }
                onChanged?.call(value);
              },
        suffixProps: DropdownSuffixProps(
          dropdownButtonProps: DropdownButtonProps(
            padding: const EdgeInsets.only(
              left: 0,
              top: 4,
              bottom: 4,
              right: 1,
            ),
            constraints: const BoxConstraints(),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          baseStyle: TextStyle(
            fontSize: 13,
            color: isReadOnly ? const Color(0xFF111827) : Colors.black,
          ),
          decoration: InputDecoration(
            constraints: const BoxConstraints(),
            isDense: true,
            hintText: label ?? "Select",
            hintStyle: TextStyle(
              color: isReadOnly
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF6B7280),
              fontSize: 13,
            ),
            filled: true,
            fillColor: isReadOnly ? const Color(0xFFF3F4F6) : Colors.white,
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(color: Colors.blue),
            disabledBorder: _border(color: const Color(0xFFE5E7EB)),
            suffixIconConstraints: const BoxConstraints(minWidth: 3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        popupProps: PopupProps.menu(
          fit: FlexFit.loose,
          constraints: const BoxConstraints(minWidth: 350),
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: const TextStyle(fontSize: 13),
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          menuProps: MenuProps(
            borderRadius: BorderRadius.circular(8),
            elevation: 6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';
//
// class CustomDropdownSearch extends StatefulWidget {
//   final String label;
//   final bool isRequired;
//   final List<String> items;
//   final String? selectedItem;
//   final ValueChanged<String?>? onChanged;
//   final bool isCompact;
//   final bool isReadOnly;
//   final bool autoFocus;
//
//   const CustomDropdownSearch({
//     super.key,
//     required this.label,
//     this.isRequired = false,
//     required this.items,
//     this.selectedItem,
//     required this.onChanged,
//     this.isCompact = false,
//     this.isReadOnly = false,
//     this.autoFocus = false,
//   });
//
//   @override
//   State<CustomDropdownSearch> createState() => _CustomDropdownSearchState();
// }
//
// class _CustomDropdownSearchState extends State<CustomDropdownSearch> {
//   final TextEditingController _searchController = TextEditingController();
//
//   void _handleEnterKeySelection(String searchText) {
//     if (searchText.isEmpty) return;
//
//     final filteredItems = widget.items.where((item) =>
//         item.toLowerCase().contains(searchText.toLowerCase())).toList();
//
//     if (filteredItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No matching item found for "$searchText"')),
//       );
//       return;
//     }
//
//     _selectItem(filteredItems.first);
//   }
//
//   void _selectItem(String item) {
//     if (widget.onChanged != null) {
//       if (widget.isRequired && item.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("This field is required")),
//         );
//       } else {
//         widget.onChanged!(item);
//         Navigator.of(context).pop();
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     OutlineInputBorder _border({Color color = const Color(0xFFD1D5DB)}) {
//       return OutlineInputBorder(
//         borderSide: BorderSide(color: color, width: 1.4),
//         borderRadius: BorderRadius.circular(6),
//       );
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (widget.label.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 6.0),
//             child: RichText(
//               text: TextSpan(
//                 text: widget.label,
//                 style: TextStyle(
//                   color: widget.isReadOnly ? const Color(0xFF111827) : const Color(0xFF374151),
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 children: widget.isRequired
//                     ? const [
//                   TextSpan(
//                     text: ' *',
//                     style: TextStyle(color: Colors.red),
//                   )
//                 ]
//                     : [],
//               ),
//             ),
//           ),
//         DropdownSearch<String>(
//           items: (filter, loadProps) => widget.items,
//           selectedItem: widget.selectedItem,
//           enabled: !widget.isReadOnly,
//           onChanged: widget.isReadOnly
//               ? null
//               : (value) {
//             if (widget.isRequired && (value == null || value.isEmpty)) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("This field is required")),
//               );
//               return;
//             }
//             widget.onChanged?.call(value);
//           },
//           decoratorProps: DropDownDecoratorProps(
//             baseStyle: TextStyle(
//               fontSize: 14,
//               color: widget.isReadOnly ? const Color(0xFF111827) : Colors.black,
//             ),
//             decoration: InputDecoration(
//               filled: true,
//               fillColor: widget.isReadOnly ? const Color(0xFFF3F4F6) : const Color(0xFFF3F4F6),
//               border: _border(),
//               enabledBorder: _border(),
//               focusedBorder: _border(),
//               disabledBorder: _border(color: const Color(0xFFD1D5DB)),
//               isDense: widget.isCompact,
//               contentPadding: widget.isCompact
//                   ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
//                   : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//               hintStyle: TextStyle(
//                 color: widget.isReadOnly ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
//               ),
//             ),
//           ),
//           popupProps: PopupProps.menu(
//             showSearchBox: true,
//             searchFieldProps: TextFieldProps(
//               controller: _searchController,
//               autofocus: widget.autoFocus,
//               decoration: InputDecoration(
//                 hintText: 'Search...',
//                 contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.clear, size: 20),
//                   onPressed: () {
//                     _searchController.clear();
//                   },
//                 ),
//               ),
//               onSubmitted: _handleEnterKeySelection,
//             ),
//             menuProps: MenuProps(
//               borderRadius: BorderRadius.circular(12),
//               elevation: 6,
//               color: Colors.white,
//               backgroundColor: Colors.white,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class CustomDropdownSearchonlybox extends StatelessWidget {
//   final String? label;
//   final bool isRequired;
//   final List<String> items;
//   final String? selectedItem;
//   final ValueChanged<String?>? onChanged;
//   final bool isCompact;
//   final bool isReadOnly;
//
//   const CustomDropdownSearchonlybox({
//     super.key,
//     this.label,
//     this.isRequired = false,
//     required this.items,
//     this.selectedItem,
//     required this.onChanged,
//     this.isCompact = false,
//     this.isReadOnly = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     OutlineInputBorder _border({Color color = const Color(0xFFE5E7EB)}) {
//       return OutlineInputBorder(
//         borderSide: BorderSide(color: color, width: 1),
//         borderRadius: BorderRadius.circular(6),
//       );
//     }
//
//     return SizedBox(
//       height: 40,
//       child: DropdownSearch<String>(
//         items: (filter, loadProps) => items,
//         selectedItem: selectedItem,
//         enabled: !isReadOnly,
//         onChanged: isReadOnly
//             ? null
//             : (value) {
//           if (isRequired && (value == null || value.isEmpty)) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text("This field is required")),
//             );
//             return;
//           }
//           onChanged?.call(value);
//         },
//         suffixProps: DropdownSuffixProps(
//           dropdownButtonProps: DropdownButtonProps(
//             padding: const EdgeInsets.only(left: 0, top: 4, bottom: 4, right: 1),
//             constraints: const BoxConstraints(),
//           ),
//         ),
//         decoratorProps: DropDownDecoratorProps(
//           baseStyle: TextStyle(
//             fontSize: 13,
//             color: isReadOnly ? const Color(0xFF111827) : Colors.black,
//           ),
//           decoration: InputDecoration(
//             constraints: const BoxConstraints(),
//             isDense: true,
//             hintText: label ?? "Select",
//             hintStyle: TextStyle(
//               color: isReadOnly ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
//               fontSize: 13,
//             ),
//             filled: true,
//             fillColor: isReadOnly ? const Color(0xFFF3F4F6) : Colors.white,
//             border: _border(),
//             enabledBorder: _border(),
//             focusedBorder: _border(color: Colors.blue),
//             disabledBorder: _border(color: const Color(0xFFE5E7EB)),
//             suffixIconConstraints: const BoxConstraints(
//               minWidth: 3,
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           ),
//         ),
//         popupProps: PopupProps.menu(
//           fit: FlexFit.loose,
//           constraints: const BoxConstraints(minWidth: 350),
//           showSearchBox: true,
//           searchFieldProps: TextFieldProps(
//             decoration: InputDecoration(
//               hintText: 'Search...',
//               hintStyle: const TextStyle(fontSize: 13),
//               fillColor: Colors.white,
//               isDense: true,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//           ),
//           menuProps: MenuProps(
//             borderRadius: BorderRadius.circular(8),
//             elevation: 6,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
