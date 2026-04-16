import 'dart:convert';

import 'package:http/http.dart' as http;


import 'config.dart';

class DeliveryManagementApiService {
  Future<void> updateChecklist({
    required String detailId,
    required String isChecked,
  }) async {
    await http.post(
      Uri.parse("$baseUrl/update_delivery.php"),
      body: {"detailid": detailId.toString(), "isChecked": isChecked},
    );
  }

  Future<String> fetchDeliveryDetails({
    required String companyid,
    required String headId,
  }) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/fetch_delivery_details.php"),
          body: {"head_id": headId, "companyid": companyid},
        )
        .timeout(const Duration(seconds: 30));
    return response.body;
  }

  static Future<List<dynamic>> fetchAllInvoiceNo({
    required String companyId,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/fetch_all_invoice_no.php"),
      );

      request.fields["companyid"] = companyId;

      var response = await request.send();

      var responseString = await response.stream.bytesToString();

      final jsonData = jsonDecode(responseString);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData['invoice_no'];
      }

      return [];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// FETCH PRODUCTS BY BILL NO
  static Future<Map<String, dynamic>> fetchProducts({
    required String companyId,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/fetch_delivery_management.php"),
      );

      request.fields["companyid"] = companyId;

      var response = await request.send();

      var responseString = await response.stream.bytesToString();

      final jsonData = jsonDecode(responseString);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Json output : '+ jsonData.toString());
        return jsonData;
      }

      return {};
    } catch (e) {
      throw Exception("Fetch Error : $e");
    }
  }

  Future<Map<String, dynamic>> fetchAllProducts({
    required String companyId,
    required String billNo,
  }) async {
    try {
      var request = await http
          .post(
            Uri.parse("$baseUrl/fetch_all_delivery_management.php"),
            body: {"companyid": companyId, "invoice_no": billNo},
          )
          .timeout(const Duration(seconds: 30));

      var responseString = request.body;

      final jsonData = jsonDecode(responseString);

      if (jsonData["status"] == "success") {
        // List<Map<String, dynamic>> data = jsonData["delivery_items"] ?? [];

        return jsonData;
      }

      return {};
    } catch (e) {
      throw Exception("Fetch Error : $e");
    }
  }

  Future<Map<String, dynamic>> getAllProducts({
    required String companyId,
  }) async {
    try {
      var request = await http
          .post(
            Uri.parse("$baseUrl/get_all_delivery_management.php"),
            body: {"companyid": companyId},
          )
          .timeout(const Duration(seconds: 30));

      var responseString = request.body;
      final jsonData = jsonDecode(responseString);

      if (jsonData["status"] == "success") {
        // List<Map<String, dynamic>> data = jsonData["delivery_items"] ?? [];

        return jsonData;
      }

      return {};
    } catch (e) {
      throw Exception("Fetch Error : $e");
    }
  }

  /// COMPLETE DELIVERY
  static Future<Map<String, dynamic>> completeDelivery({
    required String companyId,
    required String billNo,
    required String entryNoController,
  }) async {
    try {
      var request = await http
          .post(
            Uri.parse("$baseUrl/create_delivery.php"),
            body: {
              "companyid": companyId,
              "invoiceno": billNo,
              "entry_no": entryNoController,
            },
          )
          .timeout(const Duration(seconds: 30));

      return jsonDecode(request.body);
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  /// UPDATE DELIVERY STATUS
  static Future<Map<String, dynamic>> updateDelivery({
    required String companyId,
    required String headId,
    required String status,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/update_delivery_management.php"),
      );

      request.fields["companyid"] = companyId;
      request.fields["headid"] = headId;
      request.fields["status"] = status;

      var response = await request.send();

      var responseString = await response.stream.bytesToString();

      return jsonDecode(responseString);
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  /// CANCEL DELIVERY
  // static Future<Map<String, dynamic>> deleteDelivery({
  //   required String companyId,
  //   required String headId,
  // }) async {
  //   try {
  //     var request = http.MultipartRequest(
  //       "POST",
  //       Uri.parse("$baseUrl/delete_delivery_management.php"),
  //     );
  //
  //     request.fields["companyid"] = companyId;
  //     request.fields["headid"] = headId;
  //
  //     var response = await request.send();
  //
  //     var responseString = await response.stream.bytesToString();
  //
  //     return jsonDecode(responseString);
  //   } catch (e) {
  //     return {"status": "error", "message": e.toString()};
  //   }
  // }
}
