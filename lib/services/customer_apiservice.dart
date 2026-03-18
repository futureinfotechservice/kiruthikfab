import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/CustomerMasterModel.dart';
import 'config.dart';

class CustomerApiService {

  Future<String> insertCustomer({
    required BuildContext context,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String whatsapp,
    required String address,
    required String area,
    required String areaid,
    required String gstNo,
    required String refer,
    required String incharge,
    required String agent,
    required String salesperson,
    required String occupation,
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

    var url = Uri.parse('$baseUrl/customer_insert.php');

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
        areaid: areaid,
        gstNo: gstNo,
        refer: refer,
        incharge: incharge,
        agent: agent,
        salesperson: salesperson,
        occupation: occupation,
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
        areaid: areaid,
        gstNo: gstNo,
        refer: refer,
        incharge: incharge,
        agent: agent,
        salesperson: salesperson,
        occupation: occupation,
        aadharFile: aadharFile,
        photoFile: photoFile,
      );
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
    required String areaid,
    required String gstNo,
    required String refer,
    required String incharge,
    required String agent,
    required String salesperson,
    required String occupation,
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
      request.fields['areaid'] = areaid;
      request.fields['mobile1'] = mobile1;
      request.fields['mobile2'] = mobile2;
      request.fields['whatsapp'] = whatsapp;
      request.fields['refer'] = refer;
      request.fields['incharge'] = incharge;
      request.fields['agent'] = agent;
      request.fields['salesperson'] = salesperson;
      request.fields['occupation'] = occupation;
      request.fields['addedby'] = userid;
      request.fields['activestatus'] = '1';

      print("Sending mobile request with companyid: $companyid");

      // Add Aadhar file if exists
      if (aadharFile != null && aadharFile.isNotEmpty) {
        var file = File(aadharFile);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'aadharfile',
            aadharFile,
            filename: 'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ));
        }
      }

      // Add Photo file if exists
      if (photoFile != null && photoFile.isNotEmpty) {
        var file = File(photoFile);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'photofile',
            photoFile,
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ));
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print("Mobile Response: $responseBody");

      return _handleResponse(context, responseBody);
    } catch (e) {
      print("Mobile Error: $e");
      _showError(context, "Error: $e");
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
    required String areaid,
    required String gstNo,
    required String refer,
    required String incharge,
    required String agent,
    required String salesperson,
    required String occupation,
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
        'areaid': areaid,
        'mobile1': mobile1,
        'mobile2': mobile2,
        'whatsapp': whatsapp,
        'refer': refer,
        'incharge': incharge,
        'agent': agent,
        'salesperson': salesperson,
        'occupation': occupation,
        'addedby': userid,
        'activestatus': '1',
        'platform': 'web',
      };

      print("Sending web request with companyid: $companyid");

      if (aadharFile != null && aadharFile.isNotEmpty) {
        data['aadhar_base64'] = aadharFile;
        data['aadhar_filename'] = aadharFileName ?? 'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      if (photoFile != null && photoFile.isNotEmpty) {
        data['photo_base64'] = photoFile;
        data['photo_filename'] = photoFileName ?? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      var response = await http.post(url, body: data);
      print("Web Response: ${response.body}");
      return _handleResponse(context, response.body);
    } catch (e) {
      print("Web Error: $e");
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<String> updateCustomer({
    required BuildContext context,
    required String customerId,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String whatsapp,
    required String address,
    required String area,
    required String areaid,
    required String gstNo,
    required String refer,
    required String incharge,
    required String agent,
    required String salesperson,
    required String occupation,
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

    var url = Uri.parse('$baseUrl/customer_update.php');

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
        areaid: areaid,
        gstNo: gstNo,
        refer: refer,
        incharge: incharge,
        agent: agent,
        salesperson: salesperson,
        occupation: occupation,
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
        areaid: areaid,
        gstNo: gstNo,
        refer: refer,
        incharge: incharge,
        agent: agent,
        salesperson: salesperson,
        occupation: occupation,
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
    required String areaid,
    required String gstNo,
    required String refer,
    required String incharge,
    required String agent,
    required String salesperson,
    required String occupation,
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
      request.fields['areaid'] = areaid;
      request.fields['mobile1'] = mobile1;
      request.fields['mobile2'] = mobile2;
      request.fields['whatsapp'] = whatsapp;
      request.fields['refer'] = refer;
      request.fields['incharge'] = incharge;
      request.fields['agent'] = agent;
      request.fields['salesperson'] = salesperson;
      request.fields['occupation'] = occupation;
      request.fields['addedby'] = userid;

      if (aadharFile != null && aadharFile.isNotEmpty) {
        var file = File(aadharFile);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('aadharfile', aadharFile));
        }
      }

      if (photoFile != null && photoFile.isNotEmpty) {
        var file = File(photoFile);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('photofile', photoFile));
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      return _handleResponse(context, responseBody);
    } catch (e) {
      print("Update Error: $e");
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
    required String areaid,
    required String gstNo,
    required String refer,
    required String incharge,
    required String agent,
    required String salesperson,
    required String occupation,
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
        'areaid': areaid,
        'mobile1': mobile1,
        'mobile2': mobile2,
        'whatsapp': whatsapp,
        'refer': refer,
        'incharge': incharge,
        'agent': agent,
        'salesperson': salesperson,
        'occupation': occupation,
        'addedby': userid,
        'platform': 'web',
      };

      if (aadharFile != null && aadharFile.isNotEmpty) {
        data['aadhar_base64'] = aadharFile;
        data['aadhar_filename'] = aadharFileName ?? 'aadhar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      if (photoFile != null && photoFile.isNotEmpty) {
        data['photo_base64'] = photoFile;
        data['photo_filename'] = photoFileName ?? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      var response = await http.post(url, body: data);
      return _handleResponse(context, response.body);
    } catch (e) {
      print("Update Web Error: $e");
      _showError(context, "Error: $e");
      return "Failed";
    }
  }

  Future<List<CustomerMasterModel>> fetchCustomers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      print("Company ID is empty");
      _showError(context, "Company ID not found. Please login again.");
      return [];
    }

    var url = Uri.parse('$baseUrl/customer_fetch.php');
    print("Fetching customers for companyid: $companyid");

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'companyid': companyid},
      );

      print("Fetch Response Status: ${response.statusCode}");
      print("Fetch Response Body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.trim() == "No Data Found.") {
          return [];
        }

        try {
          List<dynamic> items = json.decode(response.body);
          print("Decoded items count: ${items.length}");
          List<CustomerMasterModel> customers = items.map((item) =>
              CustomerMasterModel.fromJson(item)
          ).toList();
          return customers;
        } catch (e) {
          print("JSON decode error: $e");
          return [];
        }
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      _showError(context, "Error fetching customers: $e");
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
        body: {
          'customerid': customerId,
          'companyid': companyid,
        },
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