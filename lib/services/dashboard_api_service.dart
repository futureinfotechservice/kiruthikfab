import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/dashboard_model.dart';
import 'config.dart';

class DashboardApiService {
  Future<DashboardModel> fetchRecords(
    int companyId,
    String type,
    String id,
  ) async {
    const String url = "$baseUrl/get_dashboard.php";

    try {
      // Add timeout to prevent hanging
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "companyid": companyId.toString(),
              "user_type": type,
              "user_id": id,
            }),
          )
          .timeout(Duration(seconds: 30)); // Added timeout

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        if (json.containsKey('status') && json['status'] == 'success') {
          if (json.containsKey('data')) {
            return DashboardModel.fromJson(json['data']);
          } else {
            throw Exception('Data not found in response');
          }
        } else {
          throw Exception(json['message'] ?? 'Failed to fetch data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timeout - server took too long to respond');
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } catch (e) {
      throw Exception('Failed to fetch records: $e');
    }
  }

  Future<List<SalesModel>> fetchAllSalesPerson(
    String companyId,
    String type,
    String id,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/fetch_salesperson_data_dashboard.php"),
      body: {"companyid": companyId, "user_type": type, "user_id": id},
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final jsonData = jsonDecode(res.body);
      if (jsonData["status"] == "success") {
        List<dynamic> data = jsonData["data"] ?? [];

        List<SalesModel> sales = data
            .map((item) => SalesModel.fromJson(item))
            .toList();
        return sales;
      }
    }
    return [];
  }

  Future<List<DeliveryDashboardModel>> fetchDeliveryList(
    String companyId,
    String search,
    String type,
    String id,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/fetch_delivery_management_dashboard.php"),
      body: {
        "companyid": companyId,
        "search": search,
        "user_type": type,
        "user_id": id,
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final jsonData = jsonDecode(res.body);
      if (jsonData["status"] == "success") {
        List<dynamic> data = jsonData["delivery_items"] ?? [];

        List<DeliveryDashboardModel> del = data
            .map((item) => DeliveryDashboardModel.fromJson(item))
            .toList();
        return del;
      }
    }
    return [];
  }

  Future<List<CallDashboardModel>> fetchCallList(
    String companyId,
    String search,
    String type,
    String id,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/fetch_call_register_dashboard.php"),
      body: {
        "companyid": companyId,
        "search": search,
        "user_type": type,
        "user_id": id,
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final jsonData = jsonDecode(res.body);
      if (jsonData["status"] == "success") {
        List<dynamic> data = jsonData["call_register"] ?? [];

        List<CallDashboardModel> call = data
            .map((item) => CallDashboardModel.fromJson(item))
            .toList();
        return call;
      }
    }
    return [];
  }
}
