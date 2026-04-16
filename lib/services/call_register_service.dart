import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import '../models/call_register_model.dart';
import 'config.dart';

// const String baseUrl = 'http://localhost:5000';

class CallRegisterService {
  Future<Map<String, dynamic>> deleteCallRegister(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_call_register.php'),
      body: {'id': id.toString()},
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateCallRegister({
    required int id,
    required int sourceId,
    required int callById,
    // required String date,
    // required String from,
    // required String to,
    required String feedback,
    required String notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_call_register.php'),
      body: {
        'id': id.toString(),
        'source_id': sourceId.toString(),
        'call_by_id': callById.toString(),
        // 'date': date,
        // 'from': from,
        // 'to': to,
        'feedback': feedback,
        'notes': notes,
      },
    );

    return jsonDecode(response.body);
  }

  Future<List<CallRegisterModel>> fetchRecords(int companyId) async {
    const String url = "$baseUrl/get_call_registers.php";
    final response = await http.post(
      Uri.parse(url),
      body: {"companyid": companyId.toString()},
    );

    final json = jsonDecode(response.body);

    return (json['data'] as List)
        .map((e) => CallRegisterModel.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> fetchCallRegister() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      return {};
    }

    var url = Uri.parse('$baseUrl/fetch_call_register.php');
    try {
      var response = await http.post(url, body: {'companyid': companyid});

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> insertCallRegister({
    required int companyId,
    required String entryNo,
    required int sourceId,
    required int callById,
    required String date,
    required String from,
    required String to,
    required String feedback,
    required String notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/insert_call_register.php'),
      body: {
        'companyid': companyId.toString(),
        'entry_no': entryNo,
        'source_id': sourceId.toString(),
        'call_by_id': callById.toString(),
        'date': date,
        'from': from,
        'to': to,
        'feedback': feedback,
        'notes': notes,
      },
    );

    return jsonDecode(response.body);
  }
}
