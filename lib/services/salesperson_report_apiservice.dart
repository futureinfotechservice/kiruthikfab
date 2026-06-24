import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class SalespersonReportApiService {
  Future<List<dynamic>> fetchAllSalesPerson({required String companyId}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/fetch_salesperson_data.php"),
      body: {"companyid": companyId},
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final jsonData = jsonDecode(res.body);
      if (jsonData["status"] == "success") {
        List<dynamic> data = jsonData["data"] ?? [];

        return data;
      }
    }
    return [];
  }

  Future<List<dynamic>> fetchAllSalesPersonBetweenDates({
    required String companyId,
    required String fromDate,
    required String toDate,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/fetch_salesperson_data_between_dates.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "companyid": companyId,
        "fromDate": fromDate,
        "toDate": toDate,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final jsonData = jsonDecode(res.body);
      if (jsonData["status"] == "success") {
        List<dynamic> data = jsonData["data"] ?? [];

        return data;
      }
    }
    return [];
  }
}
