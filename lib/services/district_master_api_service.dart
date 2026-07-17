import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/district_master.dart';
import 'config.dart';

class DistrictApiService {
  Future<String> insertDistrict({
    required BuildContext context,
    required String districtName,
    required String state,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    // final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/district_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'district_name': districtName,
        'state': state,
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

  Future<String> updateDistrict({
    required BuildContext context,
    required String districtId,
    required String districtName,
    required String state,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    // final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/district_update.php');

    try {
      var data = {
        'districtid': districtId,
        'companyid': companyid,
        'district_name': districtName,
        "state": state,
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

  Future<List<DistrictMasterModel>> fetchDistricts(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return [];
    }

    var url = Uri.parse('$baseUrl/district_fetch1.php');

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
          List<DistrictMasterModel> districts = items
              .map((item) => DistrictMasterModel.fromJson(item))
              .toList();
          return districts;
        } catch (e) {
          return [];
        }
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) _showError(context, "Error fetching districts: $e");
      return [];
    }
  }

  Future<String> deleteDistrict(BuildContext context, String districtId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted) {
        _showError(context, "Company ID not found. Please login again.");
      }
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/district_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'districtid': districtId, 'companyid': companyid},
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

// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../models/district_master.dart';
// import 'config.dart';
//
// class DistrictApiService {
//   Future<String> insertDistrict({
//     required BuildContext context,
//     required String districtName,
//     required String state,
//   }) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//     // final userid = prefs.getString('id') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return "Failed";
//     }
//
//     var url = Uri.parse('$baseUrl/district_insert.php');
//
//     try {
//       var data = {
//         'companyid': companyid,
//         'district_name': districtName,
//         'state': state,
//       };
//
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: data,
//       );
//
//       return _handleResponse(context, response.body);
//     } catch (e) {
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   Future<String> updateDistrict({
//     required BuildContext context,
//     required String districtId,
//     required String district_name,
//     required String state,
//   }) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//     // final userid = prefs.getString('id') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return "Failed";
//     }
//
//     var url = Uri.parse('$baseUrl/district_update.php');
//
//     try {
//       var data = {
//         'districtid': districtId,
//         'companyid': companyid,
//         'district_name': district_name,
//         "state": state,
//       };
//
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: data,
//       );
//
//       return _handleResponse(context, response.body);
//     } catch (e) {
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   Future<List<DistrictMasterModel>> fetchDistricts(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) {
//       if (context.mounted)
//         _showError(context, "Company ID not found. Please login again.");
//       return [];
//     }
//
//     var url = Uri.parse('$baseUrl/district_fetch.php');
//
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {'companyid': companyid},
//       );
//
//       if (response.statusCode == 200) {
//         if (response.body.trim() == "No Data Found." ||
//             response.body.trim().isEmpty) {
//           return [];
//         }
//
//         try {
//           List<dynamic> items = json.decode(response.body);
//           List<DistrictMasterModel> districts = items
//               .map((item) => DistrictMasterModel.fromJson(item))
//               .toList();
//           return districts;
//         } catch (e) {
//           return [];
//         }
//       } else {
//         throw Exception('Failed to load districts: ${response.statusCode}');
//       }
//     } catch (e) {
//       //_showError(context, "Error fetching districts: $e");
//       return [];
//     }
//   }
//
//   Future<String> deleteDistrict(BuildContext context, String districtId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return "Failed";
//     }
//
//     var url = Uri.parse('$baseUrl/district_delete.php');
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {'districtid': districtId, 'companyid': companyid},
//       );
//
//       var message = jsonDecode(response.body);
//
//       if (message["status"] == "success") {
//         return "Success";
//       } else {
//         _showError(context, message["message"] ?? "Delete failed");
//         return "Failed";
//       }
//     } catch (e) {
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
