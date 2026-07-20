import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inward_entry_model.dart';
import 'config.dart';

class InventoryApiService {
  Future<String> getNextInventoryNumber(
    BuildContext context,
    String companyid,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/inventory_fetch_inventoryid.php');
      final response = await http.post(
        url,
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['inventoryid']?.toString() ?? '1';
      }
      return '1';
    } catch (e) {
      return '1';
    }
  }

  Future<String> deleteInventory(
    BuildContext context,
    String inventoryId,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      // _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/inventory_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'inventoryid': inventoryId, 'companyid': companyid},
      );

      var message = jsonDecode(response.body);
      if (message["status"] == "success") {
        return "Success";
      } else {
        if (context.mounted) {
          _showError(context, message["message"] ?? "Delete failed");
        }
        return "Failed";
      }
    } catch (e) {
      if (context.mounted) _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<Map<String, dynamic>> createInwardEntry(InwardEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inward_insert.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'companyid': entry.companyId,
          'inventoryid': entry.inventoryId,
          'stock': entry.stock,
          'amount': entry.amount,
          'addedby': entry.addedBy,
          'manufacturer': entry.manufacturer,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  Future<List<InwardEntry>> getInwardEntries(String companyid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inward_list.php?companyid=$companyid'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> entries = data['data'] ?? [];
          return entries.map((e) => InwardEntry.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<InventoriesNo>> fetchInventoriesNumbers(String companyid) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/inward_fetch_all_inventoryid.php?companyid=$companyid',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> entries = data['data'] ?? [];
          return entries.map((e) => InventoriesNo.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<InwardEntry>> fetchInventoryById(
    String companyid,
    String id,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inward_fetch_by_id.php'),
        body: {'companyid': companyid, "id": id},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> entries = data ?? [];
        return entries.map((e) => InwardEntry.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class InventoriesNo {
  final String id;

  final String inventoryId;
  final String productName;
  final String modelName;
  final String sizeName;
  final String unitName;

  InventoriesNo({
    required this.inventoryId,
    required this.id,
    required this.productName,
    required this.modelName,
    required this.sizeName,
    required this.unitName,
  });

  factory InventoriesNo.fromJson(Map<String, dynamic> json) {
    return InventoriesNo(
      id: json['id']?.toString() ?? '',

      inventoryId: json['inventoryid'] ?? '',
      productName: json['productname'] ?? '',
      modelName: json['modelname'] ?? '',
      sizeName: json['sizename'] ?? '',
      unitName: json['unitname'] ?? '',
    );
  }
}
