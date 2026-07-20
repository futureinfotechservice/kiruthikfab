import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_based_sales_report_model.dart';
import 'config.dart';

class ProductBasedSalesReportService {
  Future<ProductBasedSalesReportResponse> fetchCall({
    int page = 1,
    int limit = 100,
    String search = '',
    String? fromDate,
    String? toDate,
    String? source,
    String? product,
    String? salesPerson,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    if (companyid.isEmpty) {
      return ProductBasedSalesReportResponse(
        status: false,
        message: 'Company ID not found',
        data: [],
        page: 1,
        limit: limit,
        total: 0,
        hasMore: false,
      );
    }

    var url = Uri.parse('$baseUrl/product_based_sales_report.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'page': page.toString(),
          'limit': limit.toString(),
          'search': search,
          'from_date': fromDate ?? '',
          'to_date': toDate ?? '',
          'source': source ?? '',
          'product': product ?? '',
          'salesPerson': salesPerson ?? '',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Check if the response has status field
        if (data['status'] == false) {
          return ProductBasedSalesReportResponse(
            status: false,
            message: data['message'] ?? 'Failed to fetch data',
            data: [],
            page: page,
            limit: limit,
            total: 0,
            hasMore: false,
          );
        }

        // Extract data from response
        final invoiceList = data['data'] as List? ?? [];
        final total = data['total'] as int? ?? 0;
        final hasMore = data['hasMore'] as bool? ?? false;
        final currentPage = data['page'] as int? ?? page;
        final currentLimit = data['limit'] as int? ?? limit;

        return ProductBasedSalesReportResponse(
          status: true,
          message: 'Success',
          data: invoiceList
              .map((e) => ProductBasedSalesReportModel.fromJson(e))
              .toList(),
          page: currentPage,
          limit: currentLimit,
          total: total,
          hasMore: hasMore,
        );
      } else {
        return ProductBasedSalesReportResponse(
          status: false,
          message: 'Server error: ${response.statusCode}',
          data: [],
          page: page,
          limit: limit,
          total: 0,
          hasMore: false,
        );
      }
    } catch (e) {
      return ProductBasedSalesReportResponse(
        status: false,
        message: 'Error: $e',
        data: [],
        page: page,
        limit: limit,
        total: 0,
        hasMore: false,
      );
    }
  }
}
