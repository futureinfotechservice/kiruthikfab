import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/OccupationMasterModel.dart';
import 'config.dart';

class OccupationApiService {
  Future<String> insertOccupation({
    required BuildContext context,
    required String occupationname,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/occupation_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'occupationname': occupationname,
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

  Future<String> updateOccupation({
    required BuildContext context,
    required String occupationId,
    required String occupationname,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/occupation_update.php');

    try {
      var data = {
        'occupationid': occupationId,
        'companyid': companyid,
        'occupationname': occupationname,
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

  Future<List<OccupationMasterModel>> fetchOccupations(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      print("Company ID is empty");
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/occupation_fetch.php');
    print("Fetching occupations for companyid: $companyid");

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
          List<OccupationMasterModel> occupations = items
              .map((item) => OccupationMasterModel.fromJson(item))
              .toList();
          return occupations;
        } catch (e) {
          print("JSON decode error: $e");
          return [];
        }
      } else {
        throw Exception('Failed to load occupations: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      _showError(context, "Error fetching occupations: $e");
      return [];
    }
  }

  Future<String> deleteOccupation(
    BuildContext context,
    String occupationId,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/occupation_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'occupationid': occupationId, 'companyid': companyid},
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
