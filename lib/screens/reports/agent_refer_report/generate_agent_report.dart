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

// ===================== AGENT SPECIFIC FUNCTIONS =====================

/// Print/Save Agent Report PDF for a specific agent
Future<void> printAgentReportAgent({
  required String companyId,
  required String agentId,
  String fromDate = '',
  String toDate = '',
  required BuildContext context,
}) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing agent report for printing...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Build URL with parameters
    final String baseUrlPath = '$baseUrl/agent_refer_report_agent_pdf.php';
    Map<String, String> queryParams = {
      'companyid': companyId,
      'agent_id': agentId,
    };

    if (fromDate.isNotEmpty) {
      queryParams['from_date'] = fromDate;
    }
    if (toDate.isNotEmpty) {
      queryParams['to_date'] = toDate;
    }

    final Uri uri = Uri.parse(
      baseUrlPath,
    ).replace(queryParameters: queryParams);

    if (kIsWeb) {
      // Web: Open PDF in new tab for printing
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening agent report for printing...'),
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
        name: 'Agent_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
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

        // Optionally open the PDF for printing
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
      // Mobile (Android/iOS): Download and open for printing
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }

      // Save to temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'Agent_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '${tempDir.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Open file for printing
      await OpenFilex.open(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening agent report for printing...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing agent report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Export Agent Report for a specific agent (PDF or Excel)
Future<void> exportAgentReportAgent(
  String format, {
  required String companyId,
  required String agentId,
  String fromDate = '',
  String toDate = '',
  required BuildContext context,
}) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting agent report as ${format.toUpperCase()}...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Determine which endpoint to use
    String endpoint = '';
    String fileExtension = '';
    String contentType = '';

    if (format.toLowerCase() == 'pdf') {
      endpoint = 'agent_refer_report_agent_pdf.php';
      fileExtension = 'pdf';
      contentType = 'application/pdf';
    } else if (format.toLowerCase() == 'excel' ||
        format.toLowerCase() == 'xlsx') {
      endpoint = 'agent_refer_report_agent_excel.php';
      fileExtension = 'xlsx';
      contentType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else {
      throw Exception('Unsupported format: $format. Use "pdf" or "excel"');
    }

    // Build URL with parameters
    final String baseUrlPath = '$baseUrl/$endpoint';
    Map<String, String> queryParams = {
      'companyid': companyId,
      'agent_id': agentId,
    };

    if (fromDate.isNotEmpty) {
      queryParams['from_date'] = fromDate;
    }
    if (toDate.isNotEmpty) {
      queryParams['to_date'] = toDate;
    }

    final Uri uri = Uri.parse(
      baseUrlPath,
    ).replace(queryParameters: queryParams);

    // Download the file
    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to download $format: ${response.statusCode}');
    }

    // Save file
    final String fileName =
        'Agent_Report_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

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
    } else if (isDesktop) {
      // Desktop: Ask user where to save
      String? savePath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: response.bodyBytes,
        fileExtension: fileExtension,
        customMimeType: contentType,
      );

      if (savePath.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${format.toUpperCase()} saved at: $savePath'),
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
              content: Text('${format.toUpperCase()} saved at: $filePath'),
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
          content: Text('Error exporting $format: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ===================== CONVENIENCE METHODS =====================

/// Export Agent Report as PDF for a specific agent
void exportAgentReportAgentPDF({
  required String companyId,
  required String agentId,
  String fromDate = '',
  String toDate = '',
  required BuildContext context,
}) {
  exportAgentReportAgent(
    'pdf',
    companyId: companyId,
    agentId: agentId,
    fromDate: fromDate,
    toDate: toDate,
    context: context,
  );
}

/// Export Agent Report as Excel for a specific agent
void exportAgentReportAgentExcel({
  required String companyId,
  required String agentId,
  String fromDate = '',
  String toDate = '',
  required BuildContext context,
}) {
  exportAgentReportAgent(
    'excel',
    companyId: companyId,
    agentId: agentId,
    fromDate: fromDate,
    toDate: toDate,
    context: context,
  );
}

// ===================== HELPER FUNCTIONS =====================

/// Helper function to save file on mobile
Future<String> _saveFileToDevice(
  List<int> bytes,
  String fileName,
  BuildContext context,
) async {
  Directory? directory;

  if (Platform.isAndroid) {
    // Request storage permission for Android (Android 12 and below)
    if (await Permission.storage.isGranted) {
      directory = await getExternalStorageDirectory();
    } else {
      // Request permission
      PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) {
        directory = await getExternalStorageDirectory();
      } else {
        // Fallback to app-specific directory
        directory = await getApplicationDocumentsDirectory();
      }
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

  final String filePath = '${directory.path}/$fileName';
  final File file = File(filePath);
  await file.writeAsBytes(bytes);

  return filePath;
}

/// Alternative method to save file using Android Download Manager (for Android)
// Future<bool> _saveFileUsingDownloadManager(
//     List<int> bytes,
//     String fileName,
//     ) async {
//   // This would require additional implementation using android_intent_plus
//   // or other plugins for download manager support
//   // For simplicity, we're using the file_saver approach above
//   return false;
// }
