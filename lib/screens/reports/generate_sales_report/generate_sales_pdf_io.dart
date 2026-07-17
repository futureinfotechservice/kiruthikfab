import 'dart:io' as io;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/services/config.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'dart:io' show File;

typedef File = io.File;

class SalesReportService {
  // Generate PDF - IO Platform
  static Future<File?> generatePdf({
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

      if (response.statusCode == 200) {
        print('_savePdf first');
        return await _savePdf(response.bodyBytes);
      } else {
        throw Exception('Failed to generate report: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Save PDF for IO platforms
  static Future<File?> _savePdf(Uint8List pdfBytes) async {
    try {
      Directory directory;
      print('_savePdf comming');
      print(Platform.isAndroid || Platform.isIOS);
      if (Platform.isAndroid || Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop platforms
        directory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      print(directory);
      final filePath =
          '${directory.path}/Product_Based_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      // Write the PDF bytes to file
      final a = await file.writeAsBytes(pdfBytes);
      print(a);
      if (await a.exists()) {
        ScaffoldMessenger(child: Text("File Stored in $filePath"));
      }
      return file;
    } catch (e) {
      return null;
    }
  }

  // Get downloads directory for desktop
  static Future<Directory?> getDownloadsDirectory() async {
    try {
      if (Platform.isWindows) {
        // Windows downloads folder
        final userDir = await getApplicationDocumentsDirectory();
        final downloadsPath = '${userDir.path}\\Downloads';
        final dir = Directory(downloadsPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      } else if (Platform.isLinux || Platform.isMacOS) {
        // Linux/Mac downloads folder
        final homeDir = Platform.environment['HOME'] ?? '';
        final downloadsPath = '$homeDir/Downloads';
        final dir = Directory(downloadsPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Open PDF - IO Platform
  static Future<void> openPdf(File file) async {
    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Could not open PDF');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Share PDF - IO Platform
  static Future<void> sharePdf(File file) async {
    try {
      final xFile = XFile(file.path);
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Product Based Sales Report',
          subject: 'Sales Report PDF',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete PDF file
  static Future<void> deletePdf(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Check if file exists
  static Future<bool> fileExists(File file) async {
    try {
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
