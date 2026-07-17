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

void printLedger({
  required String companyId,
  required String inventoryId,
  required String fromDate,
  required String toDate,
  required BuildContext context,
}) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing ledger for printing...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Build URL with parameters
    final String baseUrls = '$baseUrl/stock_ledger_pdf.php';
    Map<String, String> queryParams = {
      'companyid': companyId,
      'inventoryid': inventoryId,
    };

    if (fromDate.isNotEmpty) {
      queryParams['from_date'] = fromDate;
    }
    if (toDate.isNotEmpty) {
      queryParams['to_date'] = toDate;
    }

    final Uri uri = Uri.parse(baseUrls).replace(queryParameters: queryParams);
    print('Print URL: $uri');

    if (kIsWeb) {
      // Web: Open PDF in new tab for printing
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening ledger for printing...'),
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
          'Stock_Ledger_Print_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '${tempDir.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Open file for printing
      await OpenFilex.open(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening ledger for printing...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing ledger: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void exportLedger(
  String format, {
  required String companyId,
  required String inventoryId,
  required String fromDate,
  required String toDate,
  required BuildContext context,
}) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ledger as ${format.toUpperCase()}...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Determine which endpoint to use
    String endpoint = '';
    String fileExtension = '';
    String contentType = '';

    if (format.toLowerCase() == 'pdf') {
      endpoint = 'stock_ledger_pdf.php';
      fileExtension = 'pdf';
      contentType = 'application/pdf';
    } else if (format.toLowerCase() == 'excel' ||
        format.toLowerCase() == 'xlsx') {
      endpoint = 'stock_ledger_excel.php';
      fileExtension = 'xlsx';
      contentType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else {
      throw Exception('Unsupported format: $format. Use "pdf" or "excel"');
    }

    // Build URL with parameters
    final String baseUrls = '$baseUrl/$endpoint';
    Map<String, String> queryParams = {
      'companyid': companyId,
      'inventoryid': inventoryId,
    };

    if (fromDate.isNotEmpty) {
      queryParams['from_date'] = fromDate;
    }
    if (toDate.isNotEmpty) {
      queryParams['to_date'] = toDate;
    }

    final Uri uri = Uri.parse(baseUrls).replace(queryParameters: queryParams);
    print('Export $format URL: $uri');

    // Download the file
    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to download $format: ${response.statusCode}');
    }

    // Save file
    final String fileName =
        'Stock_Ledger_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    if (kIsWeb) {
      // Web: Download directly
      downloadFileWebImpl(response.bodyBytes, fileName, contentType);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${format.toUpperCase()} downloaded successfully!'),
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
            content: Text('${format.toUpperCase()} saved at: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting $format: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Convenience methods
void exportLedgerPDF({
  required String companyId,
  required String inventoryId,
  required String fromDate,
  required String toDate,
  required BuildContext context,
}) {
  exportLedger(
    'pdf',
    companyId: companyId,
    inventoryId: inventoryId,
    fromDate: fromDate,
    toDate: toDate,
    context: context,
  );
}

void exportLedgerExcel({
  required String companyId,
  required String inventoryId,
  required String fromDate,
  required String toDate,
  required BuildContext context,
}) {
  exportLedger(
    'excel',
    companyId: companyId,
    inventoryId: inventoryId,
    fromDate: fromDate,
    toDate: toDate,
    context: context,
  );
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
