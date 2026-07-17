import 'dart:js_interop';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

/// Web implementation using browser APIs
class InvoicePrintHelper {
  /// Download PDF on web using browser download
  static Future<void> downloadPDF(Uint8List pdfBytes, String fileName) async {
    try {
      final blob = web.Blob(
        [pdfBytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/pdf'),
      );

      final url = web.URL.createObjectURL(blob);
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = fileName;

      // Append to body, click, and remove
      web.document.body?.appendChild(anchor);
      anchor.click();
      web.document.body?.removeChild(anchor);

      web.URL.revokeObjectURL(url);
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  /// Open PDF in new tab (Web only)
  static Future<void> openPDF(Uint8List pdfBytes) async {
    try {
      final blob = web.Blob(
        [pdfBytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/pdf'),
      );

      final url = web.URL.createObjectURL(blob);
      web.window.open(url, '_blank')?.focus();

      // Revoke URL after a delay to allow the tab to open
      Future.delayed(const Duration(seconds: 2), () {
        web.URL.revokeObjectURL(url);
      });
    } catch (e) {
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Share PDF using Web Share API if available
  // static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
  //   try {
  //     final blob = web.Blob(
  //       [pdfBytes.toJS].toJS,
  //       web.BlobPropertyBag(type: 'application/pdf'),
  //     );
  //
  //     // Check if Web Share API is available
  //     final file = web.File(
  //       [blob].toJS,
  //       fileName,
  //       // web.FilePropertyBag(type: 'application/pdf'),
  //     );
  //
  //     final shareData = web.ShareData(title: 'Share PDF', files: [file].toJS);
  //
  //     final canShare = web.window.navigator.canShare(shareData);
  //     if (canShare) {
  //       await web.window.navigator.share(shareData).toDart;
  //     } else {
  //       await downloadPDF(pdfBytes, fileName);
  //     }
  //   } catch (e) {
  //     // If user cancels share, don't throw
  //     if (e.toString().contains('AbortError') ||
  //         e.toString().contains('cancel')) {
  //       return;
  //     }
  //     // Fallback to download
  //     await downloadPDF(pdfBytes, fileName);
  //   }
  // }
  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      final xFile = XFile.fromData(
        pdfBytes,
        name: fileName,
        mimeType: 'application/pdf',
      );

      final result = await SharePlus.instance.share(
        ShareParams(files: [xFile], title: 'Share PDF'),
      );

      // If share wasn't available or completed, fall back to download
      if (result.status == ShareResultStatus.unavailable) {
        await downloadPDF(pdfBytes, fileName);
      }
    } catch (e) {
      // If user cancels share, don't throw or fall back
      if (e.toString().contains('AbortError') ||
          e.toString().contains('cancel')) {
        return;
      }
      // Fallback to download for any other failure
      await downloadPDF(pdfBytes, fileName);
    }
  }

  /// Delete PDF not applicable for web (files are in-memory)
  static Future<void> deletePDF(String fileName) async {
    // Web doesn't have persistent file storage, so this is a no-op
    // Files are downloaded and exist in browser's download folder
    // which the user manages
    print(
      'Delete PDF not applicable on web - files are downloaded via browser',
    );
  }

  /// Check if file exists not applicable for web
  static Future<bool> fileExists(String fileName) async {
    // Web doesn't have persistent file storage
    return false;
  }

  /// Get file not applicable for web
  static Future<Uint8List?> getFile(String fileName) async {
    // Web doesn't have persistent file storage
    return null;
  }

  /// Download and open PDF in one flow (Web)
  static Future<void> downloadAndOpenPDF(
    Uint8List pdfBytes,
    String fileName, {
    bool shareAfterOpen = false,
  }) async {
    await downloadPDF(pdfBytes, fileName);
    if (shareAfterOpen) {
      await sharePDF(pdfBytes, fileName);
    }
  }

  /// Cleanup old PDFs not applicable for web
  static Future<void> cleanupOldPDFs({int olderThanDays = 7}) async {
    // No-op for web
    print('Cleanup old PDFs not applicable on web');
  }
}
