import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/source_master_model.dart';
import 'config.dart';

class SourceApiService {
  // Fetch Districts
  Future<List<Map<String, dynamic>>> fetchDistricts(
      BuildContext context,
      ) async {
    var url = Uri.parse('$baseUrl/fetch_districts.php');
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
      print("Error fetching districts: $e");
      return [];
    }
  }

  // Fetch Sourcing Modes
  Future<List<Map<String, dynamic>>> fetchSourcingModes(
      BuildContext context,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_sourcingmode.php');
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
      print("Error fetching sourcing modes: $e");
      return [];
    }
  }

  // Fetch Entry Persons
  Future<List<Map<String, dynamic>>> fetchEntryPersons(
      BuildContext context,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_salesperson.php');
    try {
      var response = await http.post(url, body: {'companyid': companyid});
      if (response.statusCode == 200 || response.statusCode == 200) {
        var data = json.decode(response.body);
        print(data);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print("Error fetching entry persons: $e");
      return [];
    }
  }

  // Fetch Areas (reusing existing)
  Future<List<Map<String, dynamic>>> fetchAreas(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_area.php');
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
      print("Error fetching areas: $e");
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
      print("Error fetching occupations: $e");
      return [];
    }
  }

  // Fetch Refers (reusing existing)
  Future<List<Map<String, dynamic>>> fetchRefers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_refer.php');
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
      print("Error fetching refers: $e");
      return [];
    }
  }

  // Fetch Agents (reusing existing)
  Future<List<Map<String, dynamic>>> fetchAgents(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_agent.php');
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
      print("Error fetching agents: $e");
      return [];
    }
  }

  // Fetch Sales Persons (reusing existing)
  Future<List<Map<String, dynamic>>> fetchSalesPersons(
      BuildContext context,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return [];

    var url = Uri.parse('$baseUrl/fetch_salesperson.php');
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
      print("Error fetching sales persons: $e");
      return [];
    }
  }

  // Insert Source
  Future<String> insertSource({
    required BuildContext context,
    required String sourceDate,
    required String branch,
    required String name,
    required String companyName,
    required String mobileNo,
    required String contactNo,
    required String whatsappNo,
    required String area,
    required String areaId,
    required String address,
    required String occupation,
    String? occupationId,
    required String referBy,
    String? referById,
    required String agent,
    String? agentId,
    required String sourcingMode,
    required String sourcingModeId,
    required String entryPerson,
    String? entryPersonId,
    required String backgroundNetwork,
    required String customerInterest,
    required String notes,
    required String salesPerson,
    String? salesPersonId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/source_insert.php');

    try {
      var data = {
        'companyid': companyid,
        'source_date': sourceDate,
        'branch': branch,
        'name': name,
        'company_name': companyName,
        'mobile_no': mobileNo,
        'contact_no': contactNo,
        'whatsapp_no': whatsappNo,
        'area': area,
        'area_id': areaId,
        'address': address,
        'occupation': occupation,
        'occupation_id': occupationId ?? '',
        'refer_by': referBy,
        'refer_by_id': referById ?? '',
        'agent': agent,
        'agent_id': agentId ?? '',
        'sourcing_mode': sourcingMode,
        'sourcing_mode_id': sourcingModeId,
        'entry_person': entryPerson,
        'entry_person_id': entryPersonId ?? '',
        'background_network': backgroundNetwork,
        'customer_interest': customerInterest,
        'notes': notes,
        'sales_person': salesPerson,
        'sales_person_id': salesPersonId ?? '',
        'addedby': userid,
        'activestatus': '1',
      };

      var response = await http.post(url, body: data);
      print("Insert Response: ${response.body}");
      return _handleResponse(context, response.body);
    } catch (e) {
      print("Insert Error: $e");
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  // Update Source
  Future<String> updateSource({
    required BuildContext context,
    required String sourceId,
    required String sourceDate,
    required String branch,
    required String name,
    required String companyName,
    required String mobileNo,
    required String contactNo,
    required String whatsappNo,
    required String area,
    required String areaId,
    required String address,
    required String occupation,
    String? occupationId,
    required String referBy,
    String? referById,
    required String agent,
    String? agentId,
    required String sourcingMode,
    required String sourcingModeId,
    required String entryPerson,
    String? entryPersonId,
    required String backgroundNetwork,
    required String customerInterest,
    required String notes,
    required String salesPerson,
    String? salesPersonId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/source_update.php');

    try {
      var data = {
        'source_id': sourceId,
        'companyid': companyid,
        'source_date': sourceDate,
        'branch': branch,
        'name': name,
        'company_name': companyName,
        'mobile_no': mobileNo,
        'contact_no': contactNo,
        'whatsapp_no': whatsappNo,
        'area': area,
        'area_id': areaId,
        'address': address,
        'occupation': occupation,
        'occupation_id': occupationId ?? '',
        'refer_by': referBy,
        'refer_by_id': referById ?? '',
        'agent': agent,
        'agent_id': agentId ?? '',
        'sourcing_mode': sourcingMode,
        'sourcing_mode_id': sourcingModeId,
        'entry_person': entryPerson,
        'entry_person_id': entryPersonId ?? '',
        'background_network': backgroundNetwork,
        'customer_interest': customerInterest,
        'notes': notes,
        'sales_person': salesPerson,
        'sales_person_id': salesPersonId ?? '',
        'addedby': userid,
      };

      var response = await http.post(url, body: data);
      print("Update Response: ${response.body}");
      return _handleResponse(context, response.body);
    } catch (e) {
      print("Update Error: $e");
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<SourceResponse> fetchSources1(
      BuildContext context, {
        required int page,
        required int limit,
        String search = '',
      }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");

      return SourceResponse(
        page: 1,
        limit: 0,
        total: 0,
        hasMore: false,
        data: [],
      );
    }

    var url = Uri.parse('$baseUrl/source_fetch1.php');

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "companyid": companyid,
          "page": page.toString(),
          "limit": limit.toString(),
          "search": search,
        },
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return SourceResponse(
            page: page,
            limit: limit,
            total: 0,
            hasMore: false,
            data: [],
          );
        }

        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);

          return SourceResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint("JSON Decode Error: $e");

          return SourceResponse(
            page: page,
            limit: limit,
            total: 0,
            hasMore: false,
            data: [],
          );
        }
      } else {
        throw Exception('Failed to load sources: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");

      _showError(context, "Error fetching sources: $e");

      return SourceResponse(
        page: page,
        limit: limit,
        total: 0,
        hasMore: false,
        data: [],
      );
    }
  }

  // // Fetch Sources
  // Future<List<SourceMasterModel>> fetchSources(
  //   BuildContext context, {
  //   required int page,
  //   required int limit,
  //   String search = '',
  // }) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final companyid = prefs.getString('companyid') ?? '';
  //
  //   if (companyid.isEmpty) {
  //     _showError(context, "Company ID not found. Please login again.");
  //     return [];
  //   }
  //
  //   var url = Uri.parse('$baseUrl/source_fetch1.php');
  //
  //   try {
  //     var response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  //       body: {
  //         "companyid": companyid,
  //         "page": page,
  //         "limit": limit,
  //         "search": search,
  //       },
  //     );
  //
  //     // print("Fetch Response: ${response.body}");
  //
  //     if (response.statusCode == 200) {
  //       if (response.body.trim().isEmpty || response.body.trim() == "[]") {
  //         return [];
  //       }
  //
  //       try {
  //         List<dynamic> items = json.decode(response.body);
  //         List<SourceMasterModel> sources = items
  //             .map((item) => SourceMasterModel.fromJson(item))
  //             .toList();
  //         return sources;
  //       } catch (e) {
  //         print("JSON decode error: $e");
  //         return [];
  //       }
  //     } else {
  //       throw Exception('Failed to load sources: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print("Fetch Error: $e");
  //     _showError(context, "Error fetching sources: $e");
  //     return [];
  //   }
  // }
  Future<List<SourceMasterModel>> fetchSources(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/source_fetch.php');

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
          List<SourceMasterModel> sources = items
              .map((item) => SourceMasterModel.fromJson(item))
              .toList();
          return sources;
        } catch (e) {
          print("JSON decode error: $e");
          return [];
        }
      } else {
        throw Exception('Failed to load sources: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      _showError(context, "Error fetching sources: $e");
      return [];
    }
  }

  // Delete Source
  Future<String> deleteSource(BuildContext context, String sourceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/source_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'source_id': sourceId, 'companyid': companyid},
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

  // Get Next Source Number
  Future<String> getNextSourceNumber(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) return "SRC-000001";

    var url = Uri.parse('$baseUrl/get_next_sourcenumber.php');
    try {
      var response = await http.post(url, body: {'companyid': companyid});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['source_no'];
        }
      }
      return "SRC-000001";
    } catch (e) {
      print("Error getting next source number: $e");
      return "SRC-000001";
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
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/source_master_model.dart';
// import 'config.dart';
//
// class SourceApiService {
//   // Fetch Districts
//   Future<List<Map<String, dynamic>>> fetchDistricts(BuildContext context) async {
//     var url = Uri.parse('$baseUrl/fetch_districts.php');
//     try {
//       var response = await http.post(url);
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return List<Map<String, dynamic>>.from(data['data']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print("Error fetching districts: $e");
//       return [];
//     }
//   }
//
//   // Fetch Sourcing Modes
//   Future<List<Map<String, dynamic>>> fetchSourcingModes(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) return [];
//
//     var url = Uri.parse('$baseUrl/fetch_sourcingmode.php');
//     try {
//       var response = await http.post(url, body: {'companyid': companyid});
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return List<Map<String, dynamic>>.from(data['data']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print("Error fetching sourcing modes: $e");
//       return [];
//     }
//   }
//
//   // Fetch Entry Persons
//   Future<List<Map<String, dynamic>>> fetchEntryPersons(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) return [];
//
//     var url = Uri.parse('$baseUrl/fetch_entryperson.php');
//     try {
//       var response = await http.post(url, body: {'companyid': companyid});
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return List<Map<String, dynamic>>.from(data['data']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print("Error fetching entry persons: $e");
//       return [];
//     }
//   }
//
//   // Fetch Areas (reusing existing)
//   Future<List<Map<String, dynamic>>> fetchAreas(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) return [];
//
//     var url = Uri.parse('$baseUrl/fetch_area.php');
//     try {
//       var response = await http.post(url, body: {'companyid': companyid});
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return List<Map<String, dynamic>>.from(data['data']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print("Error fetching areas: $e");
//       return [];
//     }
//   }
//
//   // Fetch Occupations (reusing existing)
//   Future<List<Map<String, dynamic>>> fetchOccupations(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) return [];
//
//     var url = Uri.parse('$baseUrl/fetch_occupation.php');
//     try {
//       var response = await http.post(url, body: {'companyid': companyid});
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return List<Map<String, dynamic>>.from(data['data']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print("Error fetching occupations: $e");
//       return [];
//     }
//   }
//
//   // Fetch Refers (reusing existing)
//   Future<List<Map<String, dynamic>>> fetchRefers(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) return [];
//
//     var url = Uri.parse('$baseUrl/fetch_refer.php');
//     try {
//       var response = await http.post(url, body: {'companyid': companyid});
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return List<Map<String, dynamic>>.from(data['data']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print("Error fetching refers: $e");
//       return [];
//     }
//   }
//
//   // Fetch Agents (reusing existing)
//   Future<List<Map<String, dynamic>>> fetchAgents(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) return [];
//
//     var url = Uri.parse('$baseUrl/fetch_agent.php');
//     try {
//       var response = await http.post(url, body: {'companyid': companyid});
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return List<Map<String, dynamic>>.from(data['data']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print("Error fetching agents: $e");
//       return [];
//     }
//   }
//
//   // Fetch Sales Persons (reusing existing)
//   Future<List<Map<String, dynamic>>> fetchSalesPersons(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) return [];
//
//     var url = Uri.parse('$baseUrl/fetch_salesperson.php');
//     try {
//       var response = await http.post(url, body: {'companyid': companyid});
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return List<Map<String, dynamic>>.from(data['data']);
//         }
//       }
//       return [];
//     } catch (e) {
//       print("Error fetching sales persons: $e");
//       return [];
//     }
//   }
//
//   // Insert Source
//   Future<String> insertSource({
//     required BuildContext context,
//     required String sourceDate,
//     required String branch,
//     required String name,
//     required String companyName,
//     required String mobileNo,
//     required String contactNo,
//     required String whatsappNo,
//     required String area,
//     required String areaId,
//     required String address,
//     required String occupation,
//     String? occupationId,
//     required String referBy,
//     String? referById,
//     required String agent,
//     String? agentId,
//     required String sourcingMode,
//     required String sourcingModeId,
//     required String entryPerson,
//     String? entryPersonId,
//     required String backgroundNetwork,
//     required String customerInterest,
//     required String notes,
//     required String salesPerson,
//     String? salesPersonId,
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
//     var url = Uri.parse('$baseUrl/source_insert.php');
//
//     try {
//       var data = {
//         'companyid': companyid,
//         'source_date': sourceDate,
//         'branch': branch,
//         'name': name,
//         'company_name': companyName,
//         'mobile_no': mobileNo,
//         'contact_no': contactNo,
//         'whatsapp_no': whatsappNo,
//         'area': area,
//         'area_id': areaId,
//         'address': address,
//         'occupation': occupation,
//         'occupation_id': occupationId ?? '',
//         'refer_by': referBy,
//         'refer_by_id': referById ?? '',
//         'agent': agent,
//         'agent_id': agentId ?? '',
//         'sourcing_mode': sourcingMode,
//         'sourcing_mode_id': sourcingModeId,
//         'entry_person': entryPerson,
//         'entry_person_id': entryPersonId ?? '',
//         'background_network': backgroundNetwork,
//         'customer_interest': customerInterest,
//         'notes': notes,
//         'sales_person': salesPerson,
//         'sales_person_id': salesPersonId ?? '',
//         'addedby': userid,
//         'activestatus': '1',
//       };
//
//       var response = await http.post(url, body: data);
//       print("Insert Response: ${response.body}");
//       return _handleResponse(context, response.body);
//     } catch (e) {
//       print("Insert Error: $e");
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   // Update Source
//   Future<String> updateSource({
//     required BuildContext context,
//     required String sourceId,
//     required String sourceDate,
//     required String branch,
//     required String name,
//     required String companyName,
//     required String mobileNo,
//     required String contactNo,
//     required String whatsappNo,
//     required String area,
//     required String areaId,
//     required String address,
//     required String occupation,
//     String? occupationId,
//     required String referBy,
//     String? referById,
//     required String agent,
//     String? agentId,
//     required String sourcingMode,
//     required String sourcingModeId,
//     required String entryPerson,
//     String? entryPersonId,
//     required String backgroundNetwork,
//     required String customerInterest,
//     required String notes,
//     required String salesPerson,
//     String? salesPersonId,
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
//     var url = Uri.parse('$baseUrl/source_update.php');
//
//     try {
//       var data = {
//         'source_id': sourceId,
//         'companyid': companyid,
//         'source_date': sourceDate,
//         'branch': branch,
//         'name': name,
//         'company_name': companyName,
//         'mobile_no': mobileNo,
//         'contact_no': contactNo,
//         'whatsapp_no': whatsappNo,
//         'area': area,
//         'area_id': areaId,
//         'address': address,
//         'occupation': occupation,
//         'occupation_id': occupationId ?? '',
//         'refer_by': referBy,
//         'refer_by_id': referById ?? '',
//         'agent': agent,
//         'agent_id': agentId ?? '',
//         'sourcing_mode': sourcingMode,
//         'sourcing_mode_id': sourcingModeId,
//         'entry_person': entryPerson,
//         'entry_person_id': entryPersonId ?? '',
//         'background_network': backgroundNetwork,
//         'customer_interest': customerInterest,
//         'notes': notes,
//         'sales_person': salesPerson,
//         'sales_person_id': salesPersonId ?? '',
//         'addedby': userid,
//       };
//
//       var response = await http.post(url, body: data);
//       print("Update Response: ${response.body}");
//       return _handleResponse(context, response.body);
//     } catch (e) {
//       print("Update Error: $e");
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   // Fetch Sources
//   Future<List<SourceMasterModel>> fetchSources(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return [];
//     }
//
//     var url = Uri.parse('$baseUrl/source_fetch.php');
//
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {'companyid': companyid},
//       );
//
//       print("Fetch Response: ${response.body}");
//
//       if (response.statusCode == 200) {
//         if (response.body.trim().isEmpty || response.body.trim() == "[]") {
//           return [];
//         }
//
//         try {
//           List<dynamic> items = json.decode(response.body);
//           List<SourceMasterModel> sources = items.map((item) =>
//               SourceMasterModel.fromJson(item)
//           ).toList();
//           return sources;
//         } catch (e) {
//           print("JSON decode error: $e");
//           return [];
//         }
//       } else {
//         throw Exception('Failed to load sources: ${response.statusCode}');
//       }
//     } catch (e) {
//       print("Fetch Error: $e");
//       _showError(context, "Error fetching sources: $e");
//       return [];
//     }
//   }
//
//   // Delete Source
//   Future<String> deleteSource(BuildContext context, String sourceId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return "Failed";
//     }
//
//     var url = Uri.parse('$baseUrl/source_delete.php');
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {
//           'source_id': sourceId,
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
//   // Get Next Source Number
//   Future<String> getNextSourceNumber(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) return "SRC-000001";
//
//     var url = Uri.parse('$baseUrl/get_next_sourcenumber.php');
//     try {
//       var response = await http.post(url, body: {'companyid': companyid});
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           return data['source_no'];
//         }
//       }
//       return "SRC-000001";
//     } catch (e) {
//       print("Error getting next source number: $e");
//       return "SRC-000001";
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