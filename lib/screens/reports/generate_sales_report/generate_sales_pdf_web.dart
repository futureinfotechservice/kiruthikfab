import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/services/config.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

export 'package:web/web.dart' show File;

typedef WFile = web.File;

class SalesReportService {
  // Generate PDF - Web Platform
  static Future<WFile?> generatePdf({
    String? fromDate,
    String? toDate,
    String? search,
    String? source,
    String? product,
    String? salesPerson,
  }) async {
    try {
      // Get company ID from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyid') ?? '';

      if (companyId.isEmpty) {
        throw Exception('Company ID not found');
      }

      // Build URL with query parameters
      var url = Uri.parse('$baseUrl/product_based_sales_report_all_pdf.php')
          .replace(
            queryParameters: fromDate == null && toDate == null
                ? {'companyid': companyId}
                : {
                    'companyid': companyId,
                    'fromdate': fromDate ?? '',
                    'todate': toDate ?? '',
                    'search': search ?? '',
                    'source': source ?? '',
                    'product': product ?? '',
                    'salesperson': salesPerson ?? '',
                  },
          );

      // Make GET request
      final response = await http.get(url);
      print(response.statusCode);
      if (response.statusCode == 200) {
        await _savePdf(response.bodyBytes);
        return null;
      } else {
        throw Exception('Failed to generate report: ${response.statusCode}');
      }
    } catch (e) {
      return null;
    }
  }

  // Save PDF for Web platform
  static Future<WFile?> _savePdf(Uint8List pdfBytes) async {
    try {
      final fileName =
          'Product_Based_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      print(fileName);
      final base64Data = base64Encode(pdfBytes);
      final anchor = web.HTMLAnchorElement()
        ..href = 'data:application/pdf;base64,$base64Data'
        ..download = fileName
        ..style.display = 'none';

      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      return null;
    } catch (e) {
      return null;
    }
  }

  // Open PDF - Web Platform
  static Future<void> openPdf(WFile file) async {
    try {
      // For web, open in new tab using the file's URL
      final url = web.URL.createObjectURL(file);
      web.window.open(url, '_blank');
      // Revoke URL after a delay to allow the tab to open
      Future.delayed(const Duration(seconds: 2), () {
        web.URL.revokeObjectURL(url);
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> sharePdf(WFile file) async {
    try {
      // Read the File's bytes so we can build an XFile for share_plus
      final buffer = await file.arrayBuffer().toDart;
      final bytes = buffer.toDart.asUint8List();

      final xFile = XFile.fromData(
        bytes,
        name: file.name.isNotEmpty
            ? file.name
            : 'Product_Based_Sales_Report.pdf',
        mimeType: 'application/pdf',
      );

      final result = await SharePlus.instance.share(
        ShareParams(files: [xFile], title: 'Product Based Sales Report'),
      );

      // If the platform share sheet wasn't available/used, fall back to download
      if (result.status == ShareResultStatus.unavailable) {
        _downloadFile(file);
      }
    } catch (e) {
      // If share fails for any reason, fallback to download
      try {
        _downloadFile(file);
      } catch (innerError) {
        rethrow;
      }
    }
  }

  // Small helper to avoid duplicating the download logic
  static void _downloadFile(WFile file) {
    final url = web.URL.createObjectURL(file);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..setAttribute('download', 'Product_Based_Sales_Report.pdf');
    anchor.click();

    Future.delayed(const Duration(seconds: 1), () {
      web.URL.revokeObjectURL(url);
    });
  }

  // Share PDF - Web Platform
  // static Future<void> sharePdf(WFile file) async {
  //   try {
  //     // Use Web Share API if available
  //     final canShare = web.window.navigator.canShare(
  //       web.ShareData(files: [file].toJS),
  //     );
  //
  //     if (canShare) {
  //       web.window.navigator.share(
  //         web.ShareData(
  //           title: 'Product Based Sales Report',
  //           files: [file].toJS,
  //         ),
  //       );
  //       return;
  //     }
  //
  //     // Fallback: Download the file
  //     final url = web.URL.createObjectURL(file);
  //     final anchor = web.HTMLAnchorElement()
  //       ..href = url
  //       ..setAttribute('download', 'Product_Based_Sales_Report.pdf');
  //     anchor.click();
  //
  //     Future.delayed(const Duration(seconds: 1), () {
  //       web.URL.revokeObjectURL(url);
  //     });
  //   } catch (e) {
  //     // If share fails, fallback to download
  //     try {
  //       final url = web.URL.createObjectURL(file);
  //       final anchor = web.HTMLAnchorElement()
  //         ..href = url
  //         ..setAttribute('download', 'Product_Based_Sales_Report.pdf');
  //       anchor.click();
  //
  //       Future.delayed(const Duration(seconds: 1), () {
  //         web.URL.revokeObjectURL(url);
  //       });
  //     } catch (innerError) {
  //       rethrow;
  //     }
  //   }
  // }

  // Delete PDF file - Web Platform
  static Future<void> deletePdf(WFile file) async {
    // On web, files are not stored permanently, so we just revoke object URLs
    // The file object will be garbage collected
    try {
      // If the file has a URL associated, revoke it
      final url = web.URL.createObjectURL(file);
      web.URL.revokeObjectURL(url);
    } catch (e) {
      // Ignore errors
    }
  }

  // Check if file exists - Web Platform
  static Future<bool> fileExists(WFile file) async {
    try {
      // On web, we can check if the file has data
      final size = file.size;
      return size > 0;
    } catch (e) {
      return false;
    }
  }
}
