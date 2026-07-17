import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/CustomerMasterModel.dart';
import 'config.dart';

class CustomerApiService {
  // Dropdown data models (unchanged)
  Future<List<Map<String, dynamic>>> fetchAgents(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyid') ?? '';

    if (companyId.isEmpty) {
      return [];
    }

    var url = Uri.parse('$baseUrl/fetch_agent.php');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
            body: json.encode({'companyid': companyId.trim()}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Connection timeout');
            },
          );

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

  Future<List<Map<String, dynamic>>> fetchAreas(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      return [];
    }

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
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchIncharges(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      return [];
    }

    var url = Uri.parse('$baseUrl/fetch_incharge.php');
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

  Future<List<Map<String, dynamic>>> fetchOccupations(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      return [];
    }

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

  Future<List<Map<String, dynamic>>> fetchRefers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      return [];
    }

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
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSalesPersons(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      return [];
    }

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
      return [];
    }
  }

  // Updated insertCustomer with ID fields
  Future<String> insertCustomer({
    required BuildContext context,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String whatsapp,
    required String address,
    required String area,
    required String areaId, // Changed from areaid
    required String gstNo,
    required String refer,
    required String referId,
    required String incharge,
    required String inchargeId,
    required String agent,
    required String agentId,
    required String salesperson,
    required String salespersonId,
    required String occupation,
    String? occupationId,
    String? aadharFile,
    String? photoFile,
    String? aadharFileName,
    String? photoFileName,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted)
        _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/customer_insert1.php');

    if (context.mounted) {
      if (kIsWeb) {
        return _insertCustomerWeb(
          context: context,
          url: url,
          companyid: companyid,
          userid: userid,
          customername: customername,
          mobile1: mobile1,
          mobile2: mobile2,
          whatsapp: whatsapp,
          address: address,
          area: area,
          areaId: areaId,
          gstNo: gstNo,
          refer: refer,
          referId: referId,
          incharge: incharge,
          inchargeId: inchargeId,
          agent: agent,
          agentId: agentId,
          salesperson: salesperson,
          salespersonId: salespersonId,
          occupation: occupation,
          occupationId: occupationId,
          aadharFile: aadharFile,
          photoFile: photoFile,
          aadharFileName: aadharFileName,
          photoFileName: photoFileName,
        );
      } else {
        return _insertCustomerMobile(
          context: context,
          url: url,
          companyid: companyid,
          userid: userid,
          customername: customername,
          mobile1: mobile1,
          mobile2: mobile2,
          whatsapp: whatsapp,
          address: address,
          area: area,
          areaId: areaId,
          gstNo: gstNo,
          refer: refer,
          referId: referId,
          incharge: incharge,
          inchargeId: inchargeId,
          agent: agent,
          agentId: agentId,
          salesperson: salesperson,
          salespersonId: salespersonId,
          occupation: occupation,
          occupationId: occupationId,
          aadharFile: aadharFile,
          photoFile: photoFile,
        );
      }
    } else {
      return '';
    }
  }

  Future<String> _insertCustomerMobile({
    required BuildContext context,
    required Uri url,
    required String companyid,
    required String userid,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String whatsapp,
    required String address,
    required String area,
    required String areaId,
    required String gstNo,
    required String refer,
    required String referId,
    required String incharge,
    required String inchargeId,
    required String agent,
    required String agentId,
    required String salesperson,
    required String salespersonId,
    required String occupation,
    String? occupationId,
    String? aadharFile,
    String? photoFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', url);

      // Add text fields
      request.fields['companyid'] = companyid;
      request.fields['customername'] = customername;
      request.fields['gst_no'] = gstNo;
      request.fields['address'] = address;
      request.fields['area'] = area;
      request.fields['area_id'] = areaId;
      request.fields['mobile1'] = mobile1;
      request.fields['mobile2'] = mobile2;
      request.fields['whatsapp'] = whatsapp;
      request.fields['refer'] = refer;
      request.fields['refer_id'] = referId;
      request.fields['incharge'] = incharge;
      request.fields['incharge_id'] = inchargeId;
      request.fields['agent'] = agent;
      request.fields['agent_id'] = agentId;
      request.fields['salesperson'] = salesperson;
      request.fields['salesperson_id'] = salespersonId;
      request.fields['occupation'] = occupation;
      request.fields['occupation_id'] = occupationId ?? '';
      request.fields['addedby'] = userid;
      request.fields['activestatus'] = '1';

      // Add Aadhar file if exists
      if (aadharFile != null && aadharFile.isNotEmpty) {
        var file = File(aadharFile);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'aadharfile',
              aadharFile,
              filename: 'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        }
      }

      // Add Photo file if exists
      if (photoFile != null && photoFile.isNotEmpty) {
        var file = File(photoFile);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photofile',
              photoFile,
              filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (context.mounted) {
        return _handleResponse(context, responseBody);
      } else {
        return '';
      }
    } catch (e) {
      if (context.mounted) _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<String> _insertCustomerWeb({
    required BuildContext context,
    required Uri url,
    required String companyid,
    required String userid,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String whatsapp,
    required String address,
    required String area,
    required String areaId,
    required String gstNo,
    required String refer,
    required String referId,
    required String incharge,
    required String inchargeId,
    required String agent,
    required String agentId,
    required String salesperson,
    required String salespersonId,
    required String occupation,
    String? occupationId,
    String? aadharFile,
    String? photoFile,
    String? aadharFileName,
    String? photoFileName,
  }) async {
    try {
      var data = {
        'companyid': companyid,
        'customername': customername,
        'gst_no': gstNo,
        'address': address,
        'area': area,
        'area_id': areaId,
        'mobile1': mobile1,
        'mobile2': mobile2,
        'whatsapp': whatsapp,
        'refer': refer,
        'refer_id': referId,
        'incharge': incharge,
        'incharge_id': inchargeId,
        'agent': agent,
        'agent_id': agentId,
        'salesperson': salesperson,
        'salesperson_id': salespersonId,
        'occupation': occupation,
        'occupation_id': occupationId ?? '',
        'addedby': userid,
        'activestatus': '1',
        'platform': 'web',
      };

      if (aadharFile != null && aadharFile.isNotEmpty) {
        data['aadhar_base64'] = aadharFile;
        data['aadhar_filename'] =
            aadharFileName ??
            'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      if (photoFile != null && photoFile.isNotEmpty) {
        data['photo_base64'] = photoFile;
        data['photo_filename'] =
            photoFileName ??
            'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      var response = await http.post(url, body: data);

      return _handleResponse(context, response.body);
    } catch (e) {
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  // Updated updateCustomer with ID fields
  Future<String> updateCustomer({
    required BuildContext context,
    required String customerId,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String whatsapp,
    required String address,
    required String area,
    required String areaId,
    required String gstNo,
    required String refer,
    required String referId,
    required String incharge,
    required String inchargeId,
    required String agent,
    required String agentId,
    required String salesperson,
    required String salespersonId,
    required String occupation,
    String? occupationId,
    String? aadharFile,
    String? photoFile,
    String? aadharFileName,
    String? photoFileName,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/customer_update1.php');

    if (kIsWeb) {
      return _updateCustomerWeb(
        context: context,
        url: url,
        customerId: customerId,
        companyid: companyid,
        userid: userid,
        customername: customername,
        mobile1: mobile1,
        mobile2: mobile2,
        whatsapp: whatsapp,
        address: address,
        area: area,
        areaId: areaId,
        gstNo: gstNo,
        refer: refer,
        referId: referId,
        incharge: incharge,
        inchargeId: inchargeId,
        agent: agent,
        agentId: agentId,
        salesperson: salesperson,
        salespersonId: salespersonId,
        occupation: occupation,
        occupationId: occupationId,
        aadharFile: aadharFile,
        photoFile: photoFile,
        aadharFileName: aadharFileName,
        photoFileName: photoFileName,
      );
    } else {
      return _updateCustomerMobile(
        context: context,
        url: url,
        customerId: customerId,
        companyid: companyid,
        userid: userid,
        customername: customername,
        mobile1: mobile1,
        mobile2: mobile2,
        whatsapp: whatsapp,
        address: address,
        area: area,
        areaId: areaId,
        gstNo: gstNo,
        refer: refer,
        referId: referId,
        incharge: incharge,
        inchargeId: inchargeId,
        agent: agent,
        agentId: agentId,
        salesperson: salesperson,
        salespersonId: salespersonId,
        occupation: occupation,
        occupationId: occupationId,
        aadharFile: aadharFile,
        photoFile: photoFile,
      );
    }
  }

  Future<String> _updateCustomerMobile({
    required BuildContext context,
    required Uri url,
    required String customerId,
    required String companyid,
    required String userid,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String whatsapp,
    required String address,
    required String area,
    required String areaId,
    required String gstNo,
    required String refer,
    required String referId,
    required String incharge,
    required String inchargeId,
    required String agent,
    required String agentId,
    required String salesperson,
    required String salespersonId,
    required String occupation,
    String? occupationId,
    String? aadharFile,
    String? photoFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', url);

      request.fields['customerid'] = customerId;
      request.fields['companyid'] = companyid;
      request.fields['customername'] = customername;
      request.fields['gst_no'] = gstNo;
      request.fields['address'] = address;
      request.fields['area'] = area;
      request.fields['area_id'] = areaId;
      request.fields['mobile1'] = mobile1;
      request.fields['mobile2'] = mobile2;
      request.fields['whatsapp'] = whatsapp;
      request.fields['refer'] = refer;
      request.fields['refer_id'] = referId;
      request.fields['incharge'] = incharge;
      request.fields['incharge_id'] = inchargeId;
      request.fields['agent'] = agent;
      request.fields['agent_id'] = agentId;
      request.fields['salesperson'] = salesperson;
      request.fields['salesperson_id'] = salespersonId;
      request.fields['occupation'] = occupation;
      request.fields['occupation_id'] = occupationId ?? '';
      request.fields['addedby'] = userid;

      if (aadharFile != null && aadharFile.isNotEmpty) {
        var file = File(aadharFile);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('aadharfile', aadharFile),
          );
        }
      }

      if (photoFile != null && photoFile.isNotEmpty) {
        var file = File(photoFile);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('photofile', photoFile),
          );
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      return _handleResponse(context, responseBody);
    } catch (e) {
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<String> _updateCustomerWeb({
    required BuildContext context,
    required Uri url,
    required String customerId,
    required String companyid,
    required String userid,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String whatsapp,
    required String address,
    required String area,
    required String areaId,
    required String gstNo,
    required String refer,
    required String referId,
    required String incharge,
    required String inchargeId,
    required String agent,
    required String agentId,
    required String salesperson,
    required String salespersonId,
    required String occupation,
    String? occupationId,
    String? aadharFile,
    String? photoFile,
    String? aadharFileName,
    String? photoFileName,
  }) async {
    try {
      var data = {
        'customerid': customerId,
        'companyid': companyid,
        'customername': customername,
        'gst_no': gstNo,
        'address': address,
        'area': area,
        'area_id': areaId,
        'mobile1': mobile1,
        'mobile2': mobile2,
        'whatsapp': whatsapp,
        'refer': refer,
        'refer_id': referId,
        'incharge': incharge,
        'incharge_id': inchargeId,
        'agent': agent,
        'agent_id': agentId,
        'salesperson': salesperson,
        'salesperson_id': salespersonId,
        'occupation': occupation,
        'occupation_id': occupationId ?? '',
        'addedby': userid,
        'platform': 'web',
      };

      if (aadharFile != null && aadharFile.isNotEmpty) {
        data['aadhar_base64'] = aadharFile;
        data['aadhar_filename'] =
            aadharFileName ??
            'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      if (photoFile != null && photoFile.isNotEmpty) {
        data['photo_base64'] = photoFile;
        data['photo_filename'] =
            photoFileName ??
            'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      var response = await http.post(url, body: data);
      return _handleResponse(context, response.body);
    } catch (e) {
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  // Rest of the methods (fetchCustomers, deleteCustomer, etc.) remain the same
  Future<List<CustomerMasterModel>> fetchCustomers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      if (context.mounted)
        _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/customer_fetch.php');

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        if (response.body.trim() == "No Data Found.") {
          return [];
        }

        try {
          List<dynamic> items = json.decode(response.body);

          List<CustomerMasterModel> customers = items
              .map((item) => CustomerMasterModel.fromJson(item))
              .toList();
          return customers;
        } catch (e) {
          return [];
        }
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      //_showError(context, "Error fetching customers: $e");
      return [];
    }
  }

  Future<String> deleteCustomer(BuildContext context, String customerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      _showError(context, "Company ID not found. Please login again.");
      return "Failed";
    }

    var url = Uri.parse('$baseUrl/customer_delete.php');
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'customerid': customerId, 'companyid': companyid},
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

// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/CustomerMasterModel.dart';
// import 'config.dart';
//
// class CustomerApiService {
//
//   Future<String> insertCustomer({
//     required BuildContext context,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String whatsapp,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String incharge,
//     required String agent,
//     required String salesperson,
//     required String occupation,
//     String? aadharFile,
//     String? photoFile,
//     String? aadharFileName,
//     String? photoFileName,
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
//     var url = Uri.parse('$baseUrl/customer_insert.php');
//
//     if (kIsWeb) {
//       return _insertCustomerWeb(
//         context: context,
//         url: url,
//         companyid: companyid,
//         userid: userid,
//         customername: customername,
//         mobile1: mobile1,
//         mobile2: mobile2,
//         whatsapp: whatsapp,
//         address: address,
//         area: area,
//         areaid: areaid,
//         gstNo: gstNo,
//         refer: refer,
//         incharge: incharge,
//         agent: agent,
//         salesperson: salesperson,
//         occupation: occupation,
//         aadharFile: aadharFile,
//         photoFile: photoFile,
//         aadharFileName: aadharFileName,
//         photoFileName: photoFileName,
//       );
//     } else {
//       return _insertCustomerMobile(
//         context: context,
//         url: url,
//         companyid: companyid,
//         userid: userid,
//         customername: customername,
//         mobile1: mobile1,
//         mobile2: mobile2,
//         whatsapp: whatsapp,
//         address: address,
//         area: area,
//         areaid: areaid,
//         gstNo: gstNo,
//         refer: refer,
//         incharge: incharge,
//         agent: agent,
//         salesperson: salesperson,
//         occupation: occupation,
//         aadharFile: aadharFile,
//         photoFile: photoFile,
//       );
//     }
//   }
//
//   Future<String> _insertCustomerMobile({
//     required BuildContext context,
//     required Uri url,
//     required String companyid,
//     required String userid,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String whatsapp,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String incharge,
//     required String agent,
//     required String salesperson,
//     required String occupation,
//     String? aadharFile,
//     String? photoFile,
//   }) async {
//     try {
//       var request = http.MultipartRequest('POST', url);
//
//       // Add text fields
//       request.fields['companyid'] = companyid;
//       request.fields['customername'] = customername;
//       request.fields['gst_no'] = gstNo;
//       request.fields['address'] = address;
//       request.fields['area'] = area;
//       request.fields['areaid'] = areaid;
//       request.fields['mobile1'] = mobile1;
//       request.fields['mobile2'] = mobile2;
//       request.fields['whatsapp'] = whatsapp;
//       request.fields['refer'] = refer;
//       request.fields['incharge'] = incharge;
//       request.fields['agent'] = agent;
//       request.fields['salesperson'] = salesperson;
//       request.fields['occupation'] = occupation;
//       request.fields['addedby'] = userid;
//       request.fields['activestatus'] = '1';
//
//
//
//       // Add Aadhar file if exists
//       if (aadharFile != null && aadharFile.isNotEmpty) {
//         var file = File(aadharFile);
//         if (await file.exists()) {
//           request.files.add(await http.MultipartFile.fromPath(
//             'aadharfile',
//             aadharFile,
//             filename: 'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg',
//           ));
//         }
//       }
//
//       // Add Photo file if exists
//       if (photoFile != null && photoFile.isNotEmpty) {
//         var file = File(photoFile);
//         if (await file.exists()) {
//           request.files.add(await http.MultipartFile.fromPath(
//             'photofile',
//             photoFile,
//             filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
//           ));
//         }
//       }
//
//       var response = await request.send();
//       var responseBody = await response.stream.bytesToString();
//
//
//       return _handleResponse(context, responseBody);
//     } catch (e) {
//
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   Future<String> _insertCustomerWeb({
//     required BuildContext context,
//     required Uri url,
//     required String companyid,
//     required String userid,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String whatsapp,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String incharge,
//     required String agent,
//     required String salesperson,
//     required String occupation,
//     String? aadharFile,
//     String? photoFile,
//     String? aadharFileName,
//     String? photoFileName,
//   }) async {
//     try {
//       var data = {
//         'companyid': companyid,
//         'customername': customername,
//         'gst_no': gstNo,
//         'address': address,
//         'area': area,
//         'areaid': areaid,
//         'mobile1': mobile1,
//         'mobile2': mobile2,
//         'whatsapp': whatsapp,
//         'refer': refer,
//         'incharge': incharge,
//         'agent': agent,
//         'salesperson': salesperson,
//         'occupation': occupation,
//         'addedby': userid,
//         'activestatus': '1',
//         'platform': 'web',
//       };
//
//
//       if (aadharFile != null && aadharFile.isNotEmpty) {
//         data['aadhar_base64'] = aadharFile;
//         data['aadhar_filename'] = aadharFileName ?? 'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       }
//
//       if (photoFile != null && photoFile.isNotEmpty) {
//         data['photo_base64'] = photoFile;
//         data['photo_filename'] = photoFileName ?? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       }
//
//       var response = await http.post(url, body: data);
//
//       return _handleResponse(context, response.body);
//     } catch (e) {
//
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   Future<String> updateCustomer({
//     required BuildContext context,
//     required String customerId,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String whatsapp,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String incharge,
//     required String agent,
//     required String salesperson,
//     required String occupation,
//     String? aadharFile,
//     String? photoFile,
//     String? aadharFileName,
//     String? photoFileName,
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
//     var url = Uri.parse('$baseUrl/customer_update.php');
//
//     if (kIsWeb) {
//       return _updateCustomerWeb(
//         context: context,
//         url: url,
//         customerId: customerId,
//         companyid: companyid,
//         userid: userid,
//         customername: customername,
//         mobile1: mobile1,
//         mobile2: mobile2,
//         whatsapp: whatsapp,
//         address: address,
//         area: area,
//         areaid: areaid,
//         gstNo: gstNo,
//         refer: refer,
//         incharge: incharge,
//         agent: agent,
//         salesperson: salesperson,
//         occupation: occupation,
//         aadharFile: aadharFile,
//         photoFile: photoFile,
//         aadharFileName: aadharFileName,
//         photoFileName: photoFileName,
//       );
//     } else {
//       return _updateCustomerMobile(
//         context: context,
//         url: url,
//         customerId: customerId,
//         companyid: companyid,
//         userid: userid,
//         customername: customername,
//         mobile1: mobile1,
//         mobile2: mobile2,
//         whatsapp: whatsapp,
//         address: address,
//         area: area,
//         areaid: areaid,
//         gstNo: gstNo,
//         refer: refer,
//         incharge: incharge,
//         agent: agent,
//         salesperson: salesperson,
//         occupation: occupation,
//         aadharFile: aadharFile,
//         photoFile: photoFile,
//       );
//     }
//   }
//
//   Future<String> _updateCustomerMobile({
//     required BuildContext context,
//     required Uri url,
//     required String customerId,
//     required String companyid,
//     required String userid,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String whatsapp,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String incharge,
//     required String agent,
//     required String salesperson,
//     required String occupation,
//     String? aadharFile,
//     String? photoFile,
//   }) async {
//     try {
//       var request = http.MultipartRequest('POST', url);
//
//       request.fields['customerid'] = customerId;
//       request.fields['companyid'] = companyid;
//       request.fields['customername'] = customername;
//       request.fields['gst_no'] = gstNo;
//       request.fields['address'] = address;
//       request.fields['area'] = area;
//       request.fields['areaid'] = areaid;
//       request.fields['mobile1'] = mobile1;
//       request.fields['mobile2'] = mobile2;
//       request.fields['whatsapp'] = whatsapp;
//       request.fields['refer'] = refer;
//       request.fields['incharge'] = incharge;
//       request.fields['agent'] = agent;
//       request.fields['salesperson'] = salesperson;
//       request.fields['occupation'] = occupation;
//       request.fields['addedby'] = userid;
//
//       if (aadharFile != null && aadharFile.isNotEmpty) {
//         var file = File(aadharFile);
//         if (await file.exists()) {
//           request.files.add(await http.MultipartFile.fromPath('aadharfile', aadharFile));
//         }
//       }
//
//       if (photoFile != null && photoFile.isNotEmpty) {
//         var file = File(photoFile);
//         if (await file.exists()) {
//           request.files.add(await http.MultipartFile.fromPath('photofile', photoFile));
//         }
//       }
//
//       var response = await request.send();
//       var responseBody = await response.stream.bytesToString();
//       return _handleResponse(context, responseBody);
//     } catch (e) {
//
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   Future<String> _updateCustomerWeb({
//     required BuildContext context,
//     required Uri url,
//     required String customerId,
//     required String companyid,
//     required String userid,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String whatsapp,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String incharge,
//     required String agent,
//     required String salesperson,
//     required String occupation,
//     String? aadharFile,
//     String? photoFile,
//     String? aadharFileName,
//     String? photoFileName,
//   }) async {
//     try {
//       var data = {
//         'customerid': customerId,
//         'companyid': companyid,
//         'customername': customername,
//         'gst_no': gstNo,
//         'address': address,
//         'area': area,
//         'areaid': areaid,
//         'mobile1': mobile1,
//         'mobile2': mobile2,
//         'whatsapp': whatsapp,
//         'refer': refer,
//         'incharge': incharge,
//         'agent': agent,
//         'salesperson': salesperson,
//         'occupation': occupation,
//         'addedby': userid,
//         'platform': 'web',
//       };
//
//       if (aadharFile != null && aadharFile.isNotEmpty) {
//         data['aadhar_base64'] = aadharFile;
//         data['aadhar_filename'] = aadharFileName ?? 'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       }
//
//       if (photoFile != null && photoFile.isNotEmpty) {
//         data['photo_base64'] = photoFile;
//         data['photo_filename'] = photoFileName ?? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       }
//
//       var response = await http.post(url, body: data);
//       return _handleResponse(context, response.body);
//     } catch (e) {
//
//       _showError(context, "Error: $e");
//       return "Failed";
//     }
//   }
//
//   Future<List<CustomerMasterModel>> fetchCustomers(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) {
//
//       _showError(context, "Company ID not found. Please login again.");
//       return [];
//     }
//
//     var url = Uri.parse('$baseUrl/customer_fetch.php');
//
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {'companyid': companyid},
//       );
//
//
//       if (response.statusCode == 200) {
//         if (response.body.trim() == "No Data Found.") {
//           return [];
//         }
//
//         try {
//           List<dynamic> items = json.decode(response.body);
//
//           List<CustomerMasterModel> customers = items.map((item) =>
//               CustomerMasterModel.fromJson(item)
//           ).toList();
//           return customers;
//         } catch (e) {
//
//           return [];
//         }
//       } else {
//         throw Exception('Failed to load customers: ${response.statusCode}');
//       }
//     } catch (e) {
//
//       _showError(context, "Error fetching customers: $e");
//       return [];
//     }
//   }
//
//   Future<String> deleteCustomer(BuildContext context, String customerId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//
//     if (companyid.isEmpty) {
//       _showError(context, "Company ID not found. Please login again.");
//       return "Failed";
//     }
//
//     var url = Uri.parse('$baseUrl/customer_delete.php');
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {
//           'customerid': customerId,
//           'companyid': companyid,
//         },
//       );
//
//
//
//       var message = jsonDecode(response.body);
//       if (message["status"] == "success") {
//         return "Success";
//       } else {
//         _showError(context, message["message"] ?? "Delete failed");
//         return "Failed";
//       }
//     } catch (e) {
//
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
//
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
