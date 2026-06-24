import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/salespersonmaster_model.dart';
import 'config.dart';

class SalesPersonApiService {
  Future<String> insertSalesPerson({
    required BuildContext context,
    required String salespersonname,
    required String password,
    required String usertype,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/salesperson_insert1.php');

    try {
      var data = {
        'companyid': companyid,
        'salespersonname': salespersonname,
        'addedby': userid,
        'activestatus': '1',
        'password': password,
        'user_type': usertype,
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

  Future<String> updateSalesPerson({
    required BuildContext context,
    required String salesPersonId,
    required String salespersonname,
    required String usertype,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/salesperson_update1.php');

    try {
      var data = {
        'salespersonid': salesPersonId,
        'companyid': companyid,
        'salespersonname': salespersonname,
        'addedby': userid,
        'user_type': usertype,
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

  Future<List<SalesPersonMasterModel>> fetchSalesPersons(
      BuildContext context,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      print("Company ID is empty");
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/salesperson_fetch.php');
    print("Fetching sales persons for companyid: $companyid");

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
          List<SalesPersonMasterModel> salesPersons = items
              .map((item) => SalesPersonMasterModel.fromJson(item))
              .toList();
          return salesPersons;
        } catch (e) {
          print("JSON decode error: $e");
          return [];
        }
      } else {
        throw Exception('Failed to load sales persons: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      _showError(context, "Error fetching sales persons: $e");
      return [];
    }
  }

  Future<String> deleteSalesPerson(
      BuildContext context,
      String salesPersonId,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/salesperson_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'salespersonid': salesPersonId, 'companyid': companyid},
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



// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/salespersonmaster_model.dart';
// import 'config.dart';
//
// class SalesPersonApiService {
//
//   Future<String> insertSalesPerson({
//     required BuildContext context,
//     required String salespersonname,
//   }) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//     final userid = prefs.getString('id') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return "Failed";
//     }
//
//     var url = Uri.parse('$baseUrl/salesperson_insert.php');
//
//     try {
//       var data = {
//         'companyid': companyid,
//         'salespersonname': salespersonname,
//         'addedby': userid,
//         'activestatus': '1',
//       };
//
//       print("Sending insert request: $data");
//
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: data,
//       );
//
//       print("Insert Response: ${response.body}");
//       return _handleResponse(context, response.body);
//     } catch (e) {
//       print("Insert Error: $e");
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   Future<String> updateSalesPerson({
//     required BuildContext context,
//     required String salesPersonId,
//     required String salespersonname,
//   }) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//     final userid = prefs.getString('id') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return "Failed";
//     }
//
//     var url = Uri.parse('$baseUrl/salesperson_update.php');
//
//     try {
//       var data = {
//         'salespersonid': salesPersonId,
//         'companyid': companyid,
//         'salespersonname': salespersonname,
//         'addedby': userid,
//       };
//
//       print("Sending update request: $data");
//
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: data,
//       );
//
//       print("Update Response: ${response.body}");
//       return _handleResponse(context, response.body);
//     } catch (e) {
//       print("Update Error: $e");
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   Future<List<SalesPersonMasterModel>> fetchSalesPersons(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) {
//       print("Company ID is empty");
//       _showError(context, "Company ID not found. Please login again.");
//       return [];
//     }
//
//     var url = Uri.parse('$baseUrl/salesperson_fetch.php');
//     print("Fetching sales persons for companyid: $companyid");
//
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {'companyid': companyid},
//       );
//
//       print("Fetch Response Status: ${response.statusCode}");
//       print("Fetch Response Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         if (response.body.trim() == "No Data Found." || response.body.trim().isEmpty) {
//           return [];
//         }
//
//         try {
//           List<dynamic> items = json.decode(response.body);
//           print("Decoded items count: ${items.length}");
//           List<SalesPersonMasterModel> salesPersons = items.map((item) =>
//               SalesPersonMasterModel.fromJson(item)
//           ).toList();
//           return salesPersons;
//         } catch (e) {
//           print("JSON decode error: $e");
//           return [];
//         }
//       } else {
//         throw Exception('Failed to load sales persons: ${response.statusCode}');
//       }
//     } catch (e) {
//       print("Fetch Error: $e");
//       _showError(context, "Error fetching sales persons: $e");
//       return [];
//     }
//   }
//
//   Future<String> deleteSalesPerson(BuildContext context, String salesPersonId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return "Failed";
//     }
//
//     var url = Uri.parse('$baseUrl/salesperson_delete.php');
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {
//           'salespersonid': salesPersonId,
//           'companyid': companyid,
//         },
//       );
//
//       print("Delete Response: ${response.body}");
//
//       var message = jsonDecode(response.body);
//       if (message["status"] == "success") {
//         return "Success";
//       } else {
//         _showError(context, message["message"] ?? "Delete failed");
//         return "Failed";
//       }
//     } catch (e) {
//       print("Delete Error: $e");
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   String _handleResponse(BuildContext context, String responseBody) {
//     try {
//       var message = jsonDecode(responseBody);
//       if (message["status"] == "success") {
//         return "Success";
//       } else {
//         _showError(context, message["message"] ?? "Unknown error");
//         return "Failed";
//       }
//     } catch (e) {
//       print("Response Parse Error: $e");
//       print("Raw Response: $responseBody");
//       if (responseBody.toLowerCase().contains("success")) {
//         return "Success";
//       } else {
//         _showError(context, "Server error");
//         return "Failed";
//       }
//     }
//   }
//
//   void _showError(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
// }