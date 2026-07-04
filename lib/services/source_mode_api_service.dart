import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/source_mode_master_model.dart';
import 'config.dart';

class SourceModeApiService {
  Future<String> insertSourceMode({
    required BuildContext context,
    required String sourcingmode_name,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/sourcingmode_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'sourcingmode_name': sourcingmode_name,
        'addedby': userid,
        'activestatus': '1',
      };

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: data,
      );

      return _handleResponse(context, response.body);
    } catch (e) {
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<String> updateSourceMode({
    required BuildContext context,
    required String occupationId,
    required String sourcingmode_name,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/sourcingmode_update.php');

    try {
      var data = {
        'sourcingmodeid': occupationId,
        'companyid': companyid,
        'sourcingmode_name': sourcingmode_name,
        'addedby': userid,
      };

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: data,
      );

      return _handleResponse(context, response.body);
    } catch (e) {
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<List<SourceModeMasterModel>> fetchSourceModes(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/sourcingmode_fetch.php');

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
          List<dynamic> items = json.decode(response.body)['data'];
          List<SourceModeMasterModel> occupations = items
              .map((item) => SourceModeMasterModel.fromJson(item))
              .toList();
          return occupations;
        } catch (e) {
          return [];
        }
      } else {
        throw Exception('Failed to load occupations: ${response.statusCode}');
      }
    } catch (e) {
      _showError(context, "Error fetching occupations: $e");
      return [];
    }
  }

  Future<String> deleteSourceMode(
    BuildContext context,
    String occupationId,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/sourcingmode_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'sourcingmodeid': occupationId, 'companyid': companyid},
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
