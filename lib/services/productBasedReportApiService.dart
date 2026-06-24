import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/ProductBasedSalesReportModel.dart';
import 'config.dart';

class ProductBasedReportApiService {
  Future<List<ProductBasedSalesReportModel>> fetchCall() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      return [];
    }

    var url = Uri.parse('$baseUrl/product_based_sales_report.php');
    try {
      var response = await http.post(
        url,
        // headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        return (data['invoices'] as List)
            .map((e) => ProductBasedSalesReportModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
