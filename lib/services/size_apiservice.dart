import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sizemaster_model.dart';
import 'config.dart';

class SizeApiService {
  Future<String> insertSize({
    required BuildContext context,
    required String sizename,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/size_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'sizename': sizename,
        'addedby': userid,
        'activestatus': '1',
      };

      print("Sending insert request: $data");

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: data,
      );

      print("Insert Response: ${response.body}");
      return _handleResponse(context, response.body);
    } catch (e) {
      print("Insert Error: $e");
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<String> updateSize({
    required BuildContext context,
    required String sizeId,
    required String sizename,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/size_update.php');

    try {
      var data = {
        'sizeid': sizeId,
        'companyid': companyid,
        'sizename': sizename,
        'addedby': userid,
      };

      print("Sending update request: $data");

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: data,
      );

      print("Update Response: ${response.body}");
      return _handleResponse(context, response.body);
    } catch (e) {
      print("Update Error: $e");
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<List<SizeMasterModel>> fetchSizes(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      print("Company ID is empty");
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/size_fetch.php');
    print("Fetching sizes for companyid: $companyid");

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'companyid': companyid},
      );

      print("Fetch Response Status: ${response.statusCode}");
      print("Fetch Response Body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.trim() == "No Data Found." ||
            response.body.trim().isEmpty) {
          return [];
        }

        try {
          List<dynamic> items = json.decode(response.body);
          print("Decoded items count: ${items.length}");
          List<SizeMasterModel> sizes = items
              .map((item) => SizeMasterModel.fromJson(item))
              .toList();
          return sizes;
        } catch (e) {
          print("JSON decode error: $e");
          return [];
        }
      } else {
        throw Exception('Failed to load sizes: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      _showError(context, "Error fetching sizes: $e");
      return [];
    }
  }

  Future<String> deleteSize(BuildContext context, String sizeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/size_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'sizeid': sizeId, 'companyid': companyid},
      );

      print("Delete Response: ${response.body}");

      var message = jsonDecode(response.body);
      if (message["status"] == "success") {
        return "Success";
      } else {
        _showError(context, message["message"] ?? "Delete failed");
        return "Failed";
      }
    } catch (e) {
      print("Delete Error: $e");
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
      print("Response Parse Error: $e");
      print("Raw Response: $responseBody");
      if (responseBody.toLowerCase().contains("success")) {
        return "Success";
      } else {
        _showError(context, "Server error");
        return "Failed";
      }
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
