import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agent_master_model.dart';
import 'config.dart';

class AgentApiService {
  Future<String> insertAgent({
    required BuildContext context,
    required String agentname,
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

    var url = Uri.parse('$baseUrl/agent_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'agentname': agentname,
        'addedby': userid,
        'activestatus': '1',
      };

      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
        body: json.encode(data),
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

  Future<String> updateAgent({
    required BuildContext context,
    required String agentId,
    required String agentname,
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

    var url = Uri.parse('$baseUrl/agent_update.php');

    try {
      var data = {
        'agentid': agentId,
        'companyid': companyid,
        'agentname': agentname,
        'addedby': userid,
      };

      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
        body: json.encode(data),
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

  Future<List<AgentMasterModel>> fetchAgents(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return [];
    }

    var url = Uri.parse('$baseUrl/agent_fetch.php');

    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
        body: json.encode({'companyid': companyid}),
      );

      if (response.statusCode == 200) {
        if (response.body.trim() == "No Data Found." ||
            response.body.trim().isEmpty) {
          return [];
        }
        final data = json.decode(response.body);

        try {
          if (data['status'] == 'success') {
            final agents = (data['data'] as List)
                .map((item) => AgentMasterModel.fromJson(item))
                .toList();
            return agents;
          } else {
            return [];
          }
        } catch (e) {
          return [];
        }
      } else {
        throw Exception('Failed to load agents: ${response.statusCode}');
      }
    } catch (e) {
      //_showError(context, "Error fetching agents: $e");
      return [];
    }
  }

  Future<String> deleteAgent(BuildContext context, String agentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/agent_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
        body: json.encode({'agentid': agentId, 'companyid': companyid}),
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
