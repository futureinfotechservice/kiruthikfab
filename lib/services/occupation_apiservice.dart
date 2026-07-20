import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/occupation_master_model.dart';
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
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
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

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: data,
      );

      if (context.mounted) {
        return _handleResponse(context, response.body);
      } else {
        return '';
      }
    } catch (e) {
      if (context.mounted) _showError(context, "Error: $e");
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
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
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

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: data,
      );

      if (context.mounted) {
        return _handleResponse(context, response.body);
      } else {
        return '';
      }
    } catch (e) {
      if (context.mounted) _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<List<OccupationMasterModel>> fetchOccupations(
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

    var url = Uri.parse('$baseUrl/occupation_fetch.php');

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
          List<OccupationMasterModel> occupations = items
              .map((item) => OccupationMasterModel.fromJson(item))
              .toList();
          return occupations;
        } catch (e) {
          return [];
        }
      } else {
        throw Exception('Failed to load occupations: ${response.statusCode}');
      }
    } catch (e) {
      //_showError(context, "Error fetching occupations: $e");
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
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/occupation_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'occupationid': occupationId, 'companyid': companyid},
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
