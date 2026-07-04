import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/call_register_model.dart';
import '../models/source_call_history_model.dart';
import 'config.dart';

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
    required String date,
    required String from,
    required String to,
    required String feedback,
    required String notes,
    required String followupDate,
    required String interest,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_call_register.php'),
      body: {
        'id': id.toString(),
        'source_id': sourceId.toString(),
        'call_by_id': callById.toString(),
        'date': date,
        'from': from,
        'to': to,
        'feedback': feedback,
        'notes': notes,
        'followup_date': followupDate.toString(),
        'interest': interest,
      },
    );

    return jsonDecode(response.body);
  }

  Future<CallRegisterResponse> fetchRecordsLimit(
    int companyId, {
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
    String? callById,
  }) async {
    const String url = "$baseUrl/get_call_registers1_limit.php";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          "companyid": companyId.toString(),
          "page": page.toString(),
          "limit": limit.toString(),
          "search": search,
          "from_date": fromDate ?? '',
          "to_date": toDate ?? '',
          "call_by_id": callById ?? '',
        },
      );

      final jsonData = jsonDecode(response.body);

      return CallRegisterResponse(
        total: jsonData['total'] ?? 0,
        hasMore: jsonData['hasMore'] ?? false,
        data: (jsonData['data'] as List)
            .map((e) => CallRegisterModel.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return CallRegisterResponse(total: 0, hasMore: false, data: []);
    }
  }

  Future<List<SourceCallHistoryModel>> fetchCallHistory(
    String companyId,
    String id,
  ) async {
    const String url = "$baseUrl/fetch_source_call_history.php";
    final response = await http.post(
      Uri.parse(url),
      body: {"companyid": companyId, "id": id},
    );

    final json = jsonDecode(response.body);

    return (json['data'] as List)
        .map((e) => SourceCallHistoryModel.fromJson(e))
        .toList();
  }

  Future<List<CallRegisterModel>> fetchRecordsByCallById(
    int companyId,
    String callById,
  ) async {
    const String url = "$baseUrl/get_call_registers_by_call_id.php";
    final response = await http.post(
      Uri.parse(url),
      body: {"companyid": companyId.toString(), "call_by_id": callById},
    );

    final json = jsonDecode(response.body);

    return (json['data'] as List)
        .map((e) => CallRegisterModel.fromJson(e))
        .toList();
  }

  Future<CallRegisterResponse> fetchRecordsByCallByIdLimit(
    int companyId,
    String callById, {
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
  }) async {
    const String url = "$baseUrl/get_call_registers_by_call_id_limit.php";
    final response = await http.post(
      Uri.parse(url),
      body: {
        "companyid": companyId.toString(),
        "call_by_id": callById,
        "page": page.toString(),
        "limit": limit.toString(),
        "search": search,
        "from_date": fromDate ?? '',
        "to_date": toDate ?? '',
      },
    );

    final jsonData = jsonDecode(response.body);

    return CallRegisterResponse(
      total: jsonData['total'] ?? 0,
      hasMore: jsonData['hasMore'] ?? false,
      data: (jsonData['data'] as List)
          .map((e) => CallRegisterModel.fromJson(e))
          .toList(),
    );
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
    required String followupDate,
    required String from,
    required String to,
    required String feedback,
    required String notes,
    required String interest,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/insert_call_register1.php'),
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
        'followup_date': followupDate.toString(),
        'interest': interest,
      },
    );

    return jsonDecode(response.body);
  }
}
