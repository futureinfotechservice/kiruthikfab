import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery_partner_master_model.dart';
import 'config.dart';

class DeliveryPartnerApiService {
  Future<String> insertDeliveryPartner({
    required BuildContext context,
    required String deliveryPartner,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/delivery_partner_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'name': deliveryPartner,
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

  Future<String> updateDeliveryPartner({
    required BuildContext context,
    required String deliveryPartnerId,
    required String deliveryPartner,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/delivery_partner_update.php');

    try {
      var data = {
        'delivery_person_id': deliveryPartnerId,
        'companyid': companyid,
        'name': deliveryPartner,
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

  Future<List<DeliveryPartnerMasterModel>> fetchDeliveryPartners(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/delivery_partner_fetch.php');

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

          List<DeliveryPartnerMasterModel> deliveryPartners = items
              .map((item) => DeliveryPartnerMasterModel.fromJson(item))
              .toList();
          return deliveryPartners;
        } catch (e) {
          return [];
        }
      } else {
        throw Exception(
          'Failed to load DeliveryPartners: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showError(context, "Error fetching DeliveryPartners: $e");
      return [];
    }
  }

  Future<String> deleteDeliveryPartner(
    BuildContext context,
    String deliveryPartnerId,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/delivery_partner_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'delivery_partner_id': deliveryPartnerId,
          'companyid': companyid,
        },
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
