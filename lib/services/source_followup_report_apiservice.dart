import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/source_followup_report_model.dart';
import 'config.dart';

class SourceFollowupReportApiservice {
  Future<SourceFollowupResponse> fetchAll({
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyid = prefs.getString('companyid') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/fetch_all_source_followup_report.php'),
      body: {
        "companyid": companyid,
        "page": page.toString(),
        "limit": limit.toString(),
        "search": search,
        "from_date": fromDate ?? '',
        "to_date": toDate ?? '',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      return SourceFollowupResponse(
        total: jsonData['total'] ?? 0,
        hasMore: jsonData['hasMore'] ?? false,
        data: (jsonData['data'] as List)
            .map((e) => SourceFollowupReportModel.fromJson(e))
            .toList(),
      );
    }

    throw Exception("Failed");
  }

  Future<SourceFollowupResponse> fetchAllUser({
    required String id,
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyid = prefs.getString('companyid') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/fetch_all_source_followup_report_by_id.php'),
      body: {
        "companyid": companyid,
        "id": id,
        "page": page.toString(),
        "limit": limit.toString(),
        "search": search,
        "from_date": fromDate ?? '',
        "to_date": toDate ?? '',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      return SourceFollowupResponse(
        total: jsonData['total'] ?? 0,
        hasMore: jsonData['hasMore'] ?? false,
        data: (jsonData['data'] as List)
            .map((e) => SourceFollowupReportModel.fromJson(e))
            .toList(),
      );
    }

    throw Exception("Failed");
  }

  Future<SourceFollowupResponse> fetchAllNotCalled({
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyid = prefs.getString('companyid') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/fetch_all_not_called_source_followup_report.php'),
      body: {
        "companyid": companyid,
        "page": page.toString(),
        "limit": limit.toString(),
        "search": search,
        "from_date": fromDate ?? '',
        "to_date": toDate ?? '',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      return SourceFollowupResponse(
        total: jsonData['total'] ?? 0,
        hasMore: jsonData['hasMore'] ?? false,
        data: (jsonData['data'] as List)
            .map((e) => SourceFollowupReportModel.fromJson(e))
            .toList(),
      );
    }

    throw Exception("Failed");
  }

  Future<SourceFollowupResponse> fetchAllNotCalledUser({
    required String id,
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyid = prefs.getString('companyid') ?? '';

    final response = await http.post(
      Uri.parse(
        '$baseUrl/fetch_all_not_called_source_followup_report_by_id.php',
      ),
      body: {
        "companyid": companyid,
        "id": id,
        "page": page.toString(),
        "limit": limit.toString(),
        "search": search,
        "from_date": fromDate ?? '',
        "to_date": toDate ?? '',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      return SourceFollowupResponse(
        total: jsonData['total'] ?? 0,
        hasMore: jsonData['hasMore'] ?? false,
        data: (jsonData['data'] as List)
            .map((e) => SourceFollowupReportModel.fromJson(e))
            .toList(),
      );
    }

    throw Exception("Failed");
  }

  Future<SourceFollowupResponse> fetchAllCalled({
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyid = prefs.getString('companyid') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/fetch_all_called_source_followup_report.php'),
      body: {
        "companyid": companyid,
        "page": page.toString(),
        "limit": limit.toString(),
        "search": search,
        "from_date": fromDate ?? '',
        "to_date": toDate ?? '',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      return SourceFollowupResponse(
        total: jsonData['total'] ?? 0,
        hasMore: jsonData['hasMore'] ?? false,
        data: (jsonData['data'] as List)
            .map((e) => SourceFollowupReportModel.fromJson(e))
            .toList(),
      );
    }

    throw Exception("Failed");
  }

  Future<SourceFollowupResponse> fetchAllCalledUser({
    required String id,
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyid = prefs.getString('companyid') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/fetch_all_called_source_followup_report_by_id.php'),
      body: {
        "companyid": companyid,
        "id": id,
        "page": page.toString(),
        "limit": limit.toString(),
        "search": search,
        "from_date": fromDate ?? '',
        "to_date": toDate ?? '',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      return SourceFollowupResponse(
        total: jsonData['total'] ?? 0,
        hasMore: jsonData['hasMore'] ?? false,
        data: (jsonData['data'] as List)
            .map((e) => SourceFollowupReportModel.fromJson(e))
            .toList(),
      );
    }

    throw Exception("Failed");
  }
}
