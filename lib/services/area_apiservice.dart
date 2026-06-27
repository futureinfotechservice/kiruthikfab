import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/AreaMasterModel.dart';
import 'config.dart';

class AreaApiService {
  Future<String> insertArea({
    required BuildContext context,
    required String areaname,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/area_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'areaname': areaname,
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

  Future<String> updateArea({
    required BuildContext context,
    required String areaId,
    required String areaname,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/area_update.php');

    try {
      var data = {
        'areaid': areaId,
        'companyid': companyid,
        'areaname': areaname,
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

  Future<List<AreaMasterModel>> fetchAreas(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      print("Company ID is empty");
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/area_fetch.php');
    print("Fetching areas for companyid: $companyid");

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
          List<AreaMasterModel> areas = items
              .map((item) => AreaMasterModel.fromJson(item))
              .toList();
          return areas;
        } catch (e) {
          print("JSON decode error: $e");
          return [];
        }
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      _showError(context, "Error fetching areas: $e");
      return [];
    }
  }

  Future<String> deleteArea(BuildContext context, String areaId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/area_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'areaid': areaId, 'companyid': companyid},
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
