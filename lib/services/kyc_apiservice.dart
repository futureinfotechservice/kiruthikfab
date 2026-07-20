import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/models/kyc_master_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/kyc_insert1.php');

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

      print('Insert KYC Data: ${json.encode(data)}');

      var response = await http.post(url, body: data);
      print('Insert Response: ${response.body}');

      if (context.mounted) {
        return _handleResponse(context, response.body);
      } else {
        return '';
      }
    } catch (e) {
      print('Insert Error: $e');
      if (context.mounted) _showError(context, "Error: $e");
      return "Failed";
    }
  }

  // Insert KYC
  // Future<String> insertKYC({
  //   required BuildContext context,
  //   required String customerId,
  //   required String customerName,
  //   required String totalAmount,
  //   required List<Map<String, dynamic>> familyMembers,
  //   required List<Map<String, dynamic>> productSections,
  // }) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final companyid = prefs.getString('companyid') ?? '';
  //   final userid = prefs.getString('id') ?? '';
  //
  //   if (companyid.isEmpty) {
  //     if (context.mounted) {
  //       _showError(context, "Company ID not found. Please login again.");
  //     }
  //     return "Failed";
  //   }
  //
  //   var url = Uri.parse('$baseUrl/kyc_insert.php');
  //
  //   try {
  //     var data = {
  //       'companyid': companyid,
  //       'customer_id': customerId,
  //       'customer_name': customerName,
  //       'total_amount': totalAmount,
  //       'addedby': userid,
  //       'family_members': json.encode(familyMembers),
  //       'product_sections': json.encode(productSections),
  //     };
  //
  //     var response = await http.post(url, body: data);
  //     if (context.mounted) {
  //       return _handleResponse(context, response.body);
  //     } else {
  //       return '';
  //     }
  //   } catch (e) {
  //     if (context.mounted) _showError(context, "Error: $e");
  //     return "Failed";
  //   }
  // }

  // Update KYC
  // Future<String> updateKYC({
  //   required BuildContext context,
  //   required String kycId,
  //   required String customerId,
  //   required String customerName,
  //   required String totalAmount,
  //   required List<Map<String, dynamic>> familyMembers,
  //   required List<Map<String, dynamic>> productSections,
  // }) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final companyid = prefs.getString('companyid') ?? '';
  //   final userid = prefs.getString('id') ?? ''; // Changed from 'id' to 'userid'
  //
  //   if (companyid.isEmpty) {
  //     if (context.mounted) {
  //       _showError(context, "Company ID not found. Please login again.");
  //     }
  //     return "Failed";
  //   }
  //
  //   var url = Uri.parse('$baseUrl/kyc_update.php');
  //
  //   try {
  //     var data = {
  //       'kyc_id': kycId,
  //       'companyid': companyid,
  //       'customer_id': customerId,
  //       'customer_name': customerName,
  //       'total_amount': totalAmount,
  //       'addedby': userid,
  //       'family_members': json.encode(familyMembers),
  //       'product_sections': json.encode(productSections),
  //     };
  //
  //     print('Update KYC Data: ${json.encode(data)}');
  //
  //     var response = await http.post(url, body: data);
  //     print('Update Response: ${response.body}');
  //
  //     if (context.mounted) {
  //       return _handleResponse(context, response.body);
  //     } else {
  //       return '';
  //     }
  //   } catch (e) {
  //     print('Update Error: $e');
  //     if (context.mounted) _showError(context, "Error: $e");
  //     return "Failed";
  //   }
  // }
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
    final userid =
        prefs.getString('id') ?? ''; // Keep as 'id' if that's what you're using

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/kyc_update1.php');

    try {
      // Prepare data as JSON
      Map<String, dynamic> data = {
        'kyc_id': kycId,
        'companyid': companyid,
        'customer_id': customerId,
        'customer_name': customerName,
        'total_amount': totalAmount,
        'addedby': userid,
        'family_members': familyMembers, // Send as List, not JSON string
        'product_sections': productSections, // Send as List, not JSON string
      };

      print('=== UPDATE KYC REQUEST ===');
      print('URL: $url');
      print('Data: ${jsonEncode(data)}');
      print('=== END UPDATE KYC REQUEST ===');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('=== UPDATE KYC RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=== END UPDATE KYC RESPONSE ===');

      if (context.mounted) {
        return _handleResponse(context, response.body);
      } else {
        return '';
      }
    } catch (e) {
      print('Update Error: $e');
      if (context.mounted) _showError(context, "Error: $e");
      return "Failed";
    }
  }

  // Update KYC
  // Future<String> updateKYC({
  //   required BuildContext context,
  //   required String kycId,
  //   required String customerId,
  //   required String customerName,
  //   required String totalAmount,
  //   required List<Map<String, dynamic>> familyMembers,
  //   required List<Map<String, dynamic>> productSections,
  // }) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final companyid = prefs.getString('companyid') ?? '';
  //   final userid = prefs.getString('id') ?? '';
  //
  //   if (companyid.isEmpty) {
  //     if (context.mounted) {
  //       _showError(context, "Company ID not found. Please login again.");
  //     }
  //     return "Failed";
  //   }
  //
  //   var url = Uri.parse('$baseUrl/kyc_update.php');
  //
  //   try {
  //     var data = {
  //       'kyc_id': kycId,
  //       'companyid': companyid,
  //       'customer_id': customerId,
  //       'customer_name': customerName,
  //       'total_amount': totalAmount,
  //       'addedby': userid,
  //       'family_members': json.encode(familyMembers),
  //       'product_sections': json.encode(productSections),
  //     };
  //
  //     var response = await http.post(url, body: data);
  //     if (context.mounted) {
  //       return _handleResponse(context, response.body);
  //     } else {
  //       return '';
  //     }
  //   } catch (e) {
  //     if (context.mounted) _showError(context, "Error: $e");
  //     return "Failed";
  //   }
  // }

  // Fetch All KYC
  Future<List<KYCMasterModel>> fetchKYCList(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
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
      // _showError(context, "Error fetching KYC: $e");
      return [];
    }
  }

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

      print('Fetch KYC Response Status: ${response.statusCode}');
      print('Fetch KYC Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          var kycData = data['data'];

          // Parse family_members if it's a string
          if (kycData != null && kycData['family_members'] != null) {
            var familyMembers = kycData['family_members'];
            if (familyMembers is String) {
              try {
                kycData['family_members'] = json.decode(familyMembers);
              } catch (e) {
                print('Error parsing family_members: $e');
                kycData['family_members'] = [];
              }
            }
            // Ensure family_members is a List
            if (kycData['family_members'] is! List) {
              kycData['family_members'] = [];
            }

            // Ensure each member has products as List
            if (kycData['family_members'] is List) {
              for (var member in kycData['family_members']) {
                if (member['products'] is String) {
                  try {
                    member['products'] = json.decode(member['products']);
                  } catch (e) {
                    member['products'] = [];
                  }
                }
                if (member['products'] is! List) {
                  member['products'] = [];
                }
              }
            }
          }

          print('Parsed KYC Data: ${json.encode(kycData)}');
          return kycData;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching KYC detail: $e');
      return null;
    }
  }

  // Fetch Single KYC
  // Future<Map<String, dynamic>?> fetchKYCDetail(
  //   BuildContext context,
  //   String kycId,
  // ) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final companyid = prefs.getString('companyid') ?? '';
  //
  //   if (companyid.isEmpty) return null;
  //
  //   var url = Uri.parse('$baseUrl/kyc_fetch_one.php');
  //
  //   try {
  //     var response = await http.post(
  //       url,
  //       body: {'kyc_id': kycId, 'companyid': companyid},
  //     );
  //
  //     if (response.statusCode == 200) {
  //       var data = json.decode(response.body);
  //       if (data['status'] == 'success') {
  //         return data['data'];
  //       }
  //     }
  //     return null;
  //   } catch (e) {
  //     return null;
  //   }
  // }

  // Delete KYC
  Future<String> deleteKYC(BuildContext context, String kycId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
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
