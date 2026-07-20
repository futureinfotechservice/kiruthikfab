import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/services/config.dart';
import 'package:kiruthikfab/services/web_download/web_download.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// Helper function to determine if running on desktop
bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

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
    } else if (isDesktop) {
      // Desktop: Ask user where to save
      String? savePath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: response.bodyBytes,
        fileExtension: 'pdf',
        customMimeType: 'application/pdf',
      );

      if (savePath.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved at: $savePath'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Open the file
        await OpenFilex.open(savePath);
      } else {
        // User cancelled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Save cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        final String filePath = await _saveFileToDevice(
          response.bodyBytes,
          fileName,
          context,
        );

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
    } else if (isDesktop) {
      // Desktop: Ask user where to save
      String? savePath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: response.bodyBytes,
        fileExtension: 'xlsx',
        customMimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (savePath.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel saved at: $savePath'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Open the file
        await OpenFilex.open(savePath);
      } else {
        // User cancelled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Save cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        final String filePath = await _saveFileToDevice(
          response.bodyBytes,
          fileName,
          context,
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
    } else if (isDesktop) {
      // Desktop: Download and let user choose save location
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }

      String? savePath = await FileSaver.instance.saveFile(
        name:
            'Stock_Statement_Print_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: response.bodyBytes,
        fileExtension: 'pdf',
        customMimeType: 'application/pdf',
      );

      if (savePath.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved at: $savePath'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Open file for printing
        await OpenFilex.open(savePath);
      } else {
        // User cancelled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Save cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      // Mobile: Download and open for printing
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

// Helper function to save file on mobile
Future<String> _saveFileToDevice(
  List<int> bytes,
  String fileName,
  BuildContext context,
) async {
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
  } else if (Platform.isIOS) {
    // iOS uses app-specific directory
    directory = await getApplicationDocumentsDirectory();
  } else {
    // Other platforms
    directory = await getApplicationDocumentsDirectory();
  }

  if (directory == null) {
    throw Exception('Could not access storage');
  }

  // Ensure directory exists
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final String filePath = '${directory.path}/$fileName';
  final File file = File(filePath);
  await file.writeAsBytes(bytes);

  return filePath;
}

// Convenience method to export both PDF and Excel with a single function
void exportStockStatement({
  required String format,
  required String companyId,
  required String stockStatus,
  required String search,
  required BuildContext context,
}) {
  if (format.toLowerCase() == 'pdf') {
    exportPDF(
      companyId: companyId,
      stockStatus: stockStatus,
      search: search,
      context: context,
    );
  } else if (format.toLowerCase() == 'excel' ||
      format.toLowerCase() == 'xlsx') {
    exportExcel(
      companyId: companyId,
      stockStatus: stockStatus,
      search: search,
      context: context,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unsupported format: $format'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Method to get file size and info
Future<Map<String, dynamic>> getFileInfo(String filePath) async {
  try {
    final File file = File(filePath);
    if (await file.exists()) {
      final int sizeInBytes = await file.length();
      final String sizeInKB = (sizeInBytes / 1024).toStringAsFixed(2);
      final String sizeInMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(2);

      return {
        'exists': true,
        'sizeInBytes': sizeInBytes,
        'sizeInKB': '$sizeInKB KB',
        'sizeInMB': '$sizeInMB MB',
        'path': filePath,
        'fileName': filePath.split(Platform.pathSeparator).last,
      };
    }
    return {'exists': false};
  } catch (e) {
    return {'exists': false, 'error': e.toString()};
  }
}
