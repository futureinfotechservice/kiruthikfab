// invoice_print_helper_stub.dart
import 'dart:typed_data';

class InvoicePrintHelperWeb {
  // Stub implementation for non-web platforms
  static Future<void> downloadPDFWeb(Uint8List pdfBytes, String fileName) async {
    // This method should never be called on non-web platforms
    throw UnsupportedError('downloadPDFWeb is only supported on web platform');
  }
}