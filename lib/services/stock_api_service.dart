import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class StockApiService {
  static const String baseUrl1 = '$baseUrl/api_routes.php';

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl1?endpoint=$endpoint'),
        // headers: {'Content-Type': 'application/json'},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
