import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

OutlineInputBorder border({Color color = const Color(0xFFD1D5DB)}) {
  return OutlineInputBorder(
    borderSide: BorderSide(color: color, width: 1.4),
    borderRadius: BorderRadius.circular(6),
  );
}

Widget customSearchDropdownSalesPerson({
  required List<Map<String, dynamic>> salesPerson,
  required Map<String, dynamic>? selectedSalesPerson,
  required TextEditingController searchController1,
  required Function(Map<String, dynamic>?) onChanged,
}) {
  return DropdownSearch<Map<String, dynamic>>(
    selectedItem: selectedSalesPerson,

    compareFn: (item, selectedItem) => item['id'] == selectedItem['id'],

    items: (filter, loadProps) => salesPerson,

    itemAsString: (Map<String, dynamic> item) => item['name'] ?? "No Name",

    decoratorProps: DropDownDecoratorProps(
      baseStyle: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(),
        disabledBorder: border(color: const Color(0xFFD1D5DB)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintText: "Select Sales Person",
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      ),
    ),

    onSelected: onChanged,

    popupProps: PopupProps.menu(
      showSearchBox: true,

      searchFieldProps: TextFieldProps(
        controller: searchController1,
        decoration: InputDecoration(
          hintText: 'Search...',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            // borderRadius: BorderRadius.circular(8)
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              searchController1.clear();
            },
          ),
        ),
      ),

      menuProps: MenuProps(
        // borderRadius: BorderRadius.circular(12),
        elevation: 6,
        color: Colors.white,
        backgroundColor: Colors.white,
      ),

      itemBuilder:
          (
            context,
            Map<String, dynamic> item,
            bool isDisabled,
            bool isSelected,
          ) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                item['name'] ?? "No Name",
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black,
                ),
              ),
            );
          },
    ),
  );
}
