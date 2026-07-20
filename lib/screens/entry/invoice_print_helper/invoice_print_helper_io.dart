import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// IO implementation for Android, iOS, Windows, macOS, Linux
class InvoicePrintHelper {
  /// Download/Save PDF to local storage
  static Future<File> downloadPDF(Uint8List pdfBytes, String fileName) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Write bytes to file
      await file.writeAsBytes(pdfBytes);
      return file;
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  /// Open PDF with default viewer
  static Future<void> openPDF(File file) async {
    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open PDF: ${result.message}');
      }
    } catch (e) {
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Share PDF via share sheet
  static Future<void> sharePDF(File file) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Check out this PDF document',
        ),
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  /// Delete PDF file
  static Future<void> deletePDF(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete PDF: $e');
    }
  }

  /// Check if file exists
  static Future<bool> fileExists(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file from storage by name
  static Future<File?> getFile(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download, open, and optionally share PDF in one flow
  static Future<void> downloadAndOpenPDF(
    Uint8List pdfBytes,
    String fileName, {
    bool shareAfterOpen = false,
  }) async {
    final file = await downloadPDF(pdfBytes, fileName);
    await openPDF(file);
    if (shareAfterOpen) {
      await sharePDF(file);
    }
  }

  /// Clean up old PDFs older than specified days
  static Future<void> cleanupOldPDFs({int olderThanDays = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Silent fail for cleanup
      debugPrint('Failed to cleanup old PDFs: $e');
    }
  }
}
