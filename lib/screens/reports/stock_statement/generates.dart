import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/services/config.dart';
import 'package:kiruthikfab/services/web_download/web_download.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

void exportPDF({
  required String companyId,
  required String stockStatus,
  required String search,
  required BuildContext context,
}) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Build URL with parameters
    final String baseUrls = '$baseUrl/stock_statement_pdf.php';
    Map<String, String> queryParams = {'companyid': companyId};

    if (stockStatus.isNotEmpty) {
      queryParams['stock_status'] = stockStatus;
    }
    if (search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final Uri uri = Uri.parse(baseUrls).replace(queryParameters: queryParams);
    print('PDF URL: $uri');

    // Download the PDF
    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to download PDF: ${response.statusCode}');
    }

    // Save PDF file
    final String fileName =
        'Stock_Statement_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (kIsWeb) {
      // Web: Download directly
      downloadFileWebImpl(response.bodyBytes, fileName, 'application/pdf');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Android/Windows: Save to local storage
      final String filePath = await _saveFileToDevice(
        response.bodyBytes,
        fileName,
      );

      // Open the file
      await OpenFilex.open(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved at: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void exportExcel({
  required String companyId,
  required String stockStatus,
  required String search,
  required BuildContext context,
}) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Excel...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Build URL with parameters
    final String baseUrls = '$baseUrl/stock_statement_excel.php';
    Map<String, String> queryParams = {'companyid': companyId};

    if (stockStatus.isNotEmpty) {
      queryParams['stock_status'] = stockStatus;
    }
    if (search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final Uri uri = Uri.parse(baseUrls).replace(queryParameters: queryParams);
    print('Excel URL: $uri');

    // Download the Excel file
    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to download Excel: ${response.statusCode}');
    }

    // Save Excel file
    final String fileName =
        'Stock_Statement_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    if (kIsWeb) {
      // Web: Download directly
      downloadFileWebImpl(
        response.bodyBytes,
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Android/Windows: Save to local storage
      final String filePath = await _saveFileToDevice(
        response.bodyBytes,
        fileName,
      );

      // Open the file
      await OpenFilex.open(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel saved at: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void printStatement({
  required String companyId,
  required String stockStatus,
  required String search,
  required BuildContext context,
}) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing print...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Build URL with parameters
    final String baseUrls = '$baseUrl/stock_statement_pdf.php';
    Map<String, String> queryParams = {'companyid': companyId};

    if (stockStatus.isNotEmpty) {
      queryParams['stock_status'] = stockStatus;
    }
    if (search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final Uri uri = Uri.parse(baseUrls).replace(queryParameters: queryParams);
    print('Print URL: $uri');

    if (kIsWeb) {
      // Web: Open PDF in new tab for printing
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening PDF for printing...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Android/Windows: Download and open for printing
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }

      // Save to temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'Stock_Statement_Print_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '${tempDir.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Open file for printing
      await OpenFilex.open(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening file for printing...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Helper function to save file on mobile/desktop
Future<String> _saveFileToDevice(List<int> bytes, String fileName) async {
  Directory? directory;

  if (Platform.isAndroid) {
    // Request storage permission for Android
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      directory = await getExternalStorageDirectory();
    } else {
      // Fallback to app-specific directory
      directory = await getApplicationDocumentsDirectory();
    }
  } else {
    // Windows or other platforms
    directory = await getApplicationDocumentsDirectory();
  }

  if (directory == null) {
    throw Exception('Could not access storage');
  }

  final String filePath = '${directory.path}/$fileName';
  final File file = File(filePath);
  await file.writeAsBytes(bytes);

  return filePath;
}
