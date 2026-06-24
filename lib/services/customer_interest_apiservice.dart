import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CustomerInterestModel.dart';
import 'config.dart';

class CustomerInterestApiservice {
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<List<CustomerInterestModel>> fetchInterests(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return [];
    }

    var url = Uri.parse('$baseUrl/customer_interest_master_fetch.php');

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        if (response.body.trim() == "No Data Found." ||
            response.body.trim().isEmpty) {
          return [];
        }

        try {
          List<dynamic> items = json.decode(response.body);

          List<CustomerInterestModel> interest = items
              .map((item) => CustomerInterestModel.fromJson(item))
              .toList();
          return interest;
        } catch (e) {
          return [];
        }
      } else {
        throw Exception('Failed to load interest: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, "Error fetching interest: $e");
      }
      return [];
    }
  }

  Future<String> updateInterest({
    required BuildContext context,
    required String id,
    required String interest,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/customer_interest_master_update.php');

    try {
      var data = {'id': id, 'companyid': companyid, 'interest': interest};

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: data,
      );

      return _handleResponse(context, response.body);
    } catch (e) {
      if (context.mounted) {
        _showError(context, "Error: $e");
      }
      return "Failed";
    }
  }

  Future<String> insertInterest({
    required BuildContext context,
    required String interest,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/customer_interest_master_create.php');

    try {
      var data = {'companyid': companyid, 'interest': interest};

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: data,
      );

      return _handleResponse(context, response.body);
    } catch (e) {
      if (context.mounted) {
        _showError(context, "Error: $e");
      }
      return "Failed";
    }
  }

  Future<String> deleteInterest(BuildContext context, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/customer_interest_master_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id, 'companyid': companyid},
      );

      var message = jsonDecode(response.body);
      if (message["status"] == "success") {
        return "Success";
      } else {
        _showError(context, message["message"] ?? "Delete failed");
        return "Failed";
      }
    } catch (e) {
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  String _handleResponse(BuildContext context, String responseBody) {
    try {
      var message = jsonDecode(responseBody);
      if (message["status"] == "success") {
        return "Success";
      } else {
        _showError(context, message["message"] ?? "Unknown error");
        return "Failed";
      }
    } catch (e) {
      if (responseBody.toLowerCase().contains("success")) {
        return "Success";
      } else {
        _showError(context, "Server error");
        return "Failed";
      }
    }
  }
}
