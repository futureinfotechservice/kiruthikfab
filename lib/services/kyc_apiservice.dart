import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/kyc_master_model.dart';
import 'config.dart';

class KYCApiService {
  // Fetch Customers for dropdown
  Future<List<Map<String, dynamic>>> fetchCustomers(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_customers_for_kyc1.php');
    try {
      var response = await http.post(url, body: {'companyid': companyid});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch Products for dropdown
  Future<List<Map<String, dynamic>>> fetchProducts(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_products_for_kyc.php');
    try {
      var response = await http.post(url, body: {'companyid': companyid});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch Genders
  Future<List<Map<String, dynamic>>> fetchGenders(BuildContext context) async {
    var url = Uri.parse('$baseUrl/fetch_genders.php');
    try {
      var response = await http.post(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch Relations

  // Fetch Sizes
  Future<List<Map<String, dynamic>>> fetchSizes(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];
    var url = Uri.parse('$baseUrl/size_fetch.php');
    try {
      var response = await http.post(url, body: {'companyid': companyid});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch Occupations (reusing existing)
  Future<List<Map<String, dynamic>>> fetchOccupations(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_occupation.php');
    try {
      var response = await http.post(url, body: {'companyid': companyid});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Insert KYC
  Future<String> insertKYC({
    required BuildContext context,
    required String customerId,
    required String customerName,
    required String totalAmount,
    required List<Map<String, dynamic>> familyMembers,
    required List<Map<String, dynamic>> productSections,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/kyc_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'customer_id': customerId,
        'customer_name': customerName,
        'total_amount': totalAmount,
        'addedby': userid,
        'family_members': json.encode(familyMembers),
        'product_sections': json.encode(productSections),
      };

      var response = await http.post(url, body: data);
      return _handleResponse(context, response.body);
    } catch (e) {
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  // Update KYC
  Future<String> updateKYC({
    required BuildContext context,
    required String kycId,
    required String customerId,
    required String customerName,
    required String totalAmount,
    required List<Map<String, dynamic>> familyMembers,
    required List<Map<String, dynamic>> productSections,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/kyc_update.php');

    try {
      var data = {
        'kyc_id': kycId,
        'companyid': companyid,
        'customer_id': customerId,
        'customer_name': customerName,
        'total_amount': totalAmount,
        'addedby': userid,
        'family_members': json.encode(familyMembers),
        'product_sections': json.encode(productSections),
      };

      var response = await http.post(url, body: data);
      return _handleResponse(context, response.body);
    } catch (e) {
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  // Fetch All KYC
  Future<List<KYCMasterModel>> fetchKYCList(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/kyc_fetch.php');

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty || response.body.trim() == "[]") {
          return [];
        }

        try {
          List<dynamic> items = json.decode(response.body);
          List<KYCMasterModel> kycList = items
              .map((item) => KYCMasterModel.fromJson(item))
              .toList();
          return kycList;
        } catch (e) {
          return [];
        }
      } else {
        throw Exception('Failed to load KYC: ${response.statusCode}');
      }
    } catch (e) {
      _showError(context, "Error fetching KYC: $e");
      return [];
    }
  }

  // Fetch Single KYC
  Future<Map<String, dynamic>?> fetchKYCDetail(
    BuildContext context,
    String kycId,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return null;

    var url = Uri.parse('$baseUrl/kyc_fetch_one.php');

    try {
      var response = await http.post(
        url,
        body: {'kyc_id': kycId, 'companyid': companyid},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete KYC
  Future<String> deleteKYC(BuildContext context, String kycId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/kyc_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'kyc_id': kycId, 'companyid': companyid},
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
