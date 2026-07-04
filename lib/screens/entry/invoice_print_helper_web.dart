// invoice_print_helper_web.dart
import 'dart:html' as html;
import 'dart:typed_data';

class InvoicePrintHelperWeb {
  static Future<void> downloadPDFWeb(Uint8List pdfBytes, String fileName) async {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}