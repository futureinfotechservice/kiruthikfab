// Conditional export: on the web, use the real implementation (which needs
// package:web / dart:js_interop). On every other platform (Windows, macOS,
// Linux, Android, iOS), use the stub so those builds never see web-only
// types like JSObject/JSAny.
//
// Import THIS file from the rest of your app — never import
// invoice_share_web.dart or invoice_share_stub.dart directly.
export 'invoice_share_stub.dart'
    if (dart.library.js_interop) 'invoice_share_web.dart';

// import 'dart:convert';
// import 'dart:js_interop';
// import 'dart:js_interop_unsafe';
// import 'dart:typed_data';
//
// import 'package:file_saver/file_saver.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:web/web.dart' as web;
//
// import '../../services/invoice_apiservice.dart';
//
// // Web sharing function that actually shares
// Future<void> shareOnWeb(
//   BuildContext context,
//   Uint8List pdf,
//   InvoiceModel invoice,
// ) async {
//   try {
//     // Show loading indicator
//     if (context.mounted) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     // Method 1: Using Web Share API (if supported)
//     if (_isWebShareSupported()) {
//       // Create a Blob from the PDF bytes
//       final blob = web.Blob(
//         [pdf.toJS].toJS,
//         web.BlobPropertyBag(type: 'application/pdf'),
//       );
//
//       // Create a File object
//       final file = web.File(
//         [blob].toJS,
//         'Invoice_${invoice.invoiceNo}.pdf',
//         web.FilePropertyBag(type: 'application/pdf'),
//       );
//
//       // Use Web Share API
//       await _shareUsingWebShareAPI(file, invoice);
//
//       // Close loading dialog
//       if (context.mounted) {
//         Navigator.pop(context); // Close loading
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Invoice shared successfully!'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//       return;
//     }
//
//     // Method 2: Save and share via WhatsApp Web
//     await _shareViaWhatsAppWebWithFile(context, pdf, invoice);
//
//     // Close loading dialog
//     if (context.mounted) {
//       Navigator.pop(context); // Close loading
//     }
//   } catch (e) {
//     if (context.mounted) {
//       Navigator.pop(context); // Close loading if open
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error sharing: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }
//
// // Feature-detect the Web Share API. `.has(...)` comes from
// // dart:js_interop_unsafe and checks the property exists on the object,
// // which is safer than calling canShare() with dummy/empty data.
// bool _isWebShareSupported() {
//   final nav = web.window.navigator;
//   return nav.has('share') && nav.has('canShare');
// }
//
// // Share using Web Share API
// Future<void> _shareUsingWebShareAPI(web.File file, InvoiceModel invoice) async {
//   try {
//     final data = web.ShareData(
//       title: 'Invoice ${invoice.invoiceNo}',
//       text: 'Invoice #${invoice.invoiceNo}',
//       files: [file].toJS,
//     );
//
//     // navigator.share() returns a JSPromise; `.toDart` converts it to a
//     // Dart Future so it can be awaited normally.
//     await web.window.navigator.share(data).toDart;
//   } catch (e) {
//     throw Exception('Web Share API failed: $e');
//   }
// }
//
// // Share via WhatsApp Web with the PDF
// Future<void> _shareViaWhatsAppWebWithFile(
//   BuildContext context,
//   Uint8List pdf,
//   InvoiceModel invoice,
// ) async {
//   try {
//     // Open WhatsApp Web
//     const whatsappWebUrl = 'https://web.whatsapp.com/';
//     await launchUrl(
//       Uri.parse(whatsappWebUrl),
//       mode: LaunchMode.externalApplication,
//     );
//
//     // Show sharing instructions with the file ready to share
//     if (context.mounted) {
//       showDialog(
//         context: context,
//         barrierDismissible: true,
//         builder: (context) => AlertDialog(
//           title: Row(
//             children: [
//               Image.network(
//                 'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg',
//                 height: 32,
//                 width: 32,
//                 errorBuilder: (_, __, ___) => const Icon(
//                   Icons.chat_bubble,
//                   color: Colors.green,
//                   size: 32,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text('Share via WhatsApp Web'),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Your invoice PDF is ready to share!',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       '📄 Invoice Details:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Text('Invoice #: ${invoice.invoiceNo}'),
//                     Text('Customer: ${invoice.customerName ?? "N/A"}'),
//                     Text('Total: ${invoice.grandTotal ?? "0"}'),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Follow these steps to share:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text('1. Select your contact or group in WhatsApp Web'),
//               const Text('2. Click the attachment icon (📎)'),
//               const Text('3. Choose "Document" or "PDF"'),
//               const Text('4. Upload the downloaded PDF file'),
//               const Divider(),
//               const Text(
//                 '💡 Tip: The PDF has been downloaded to your computer',
//                 style: TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 // Download the PDF
//                 _downloadPDFForWeb(pdf, invoice);
//               },
//               child: const Text('Download PDF'),
//             ),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pop(context);
//                 // Open WhatsApp Web again
//                 launchUrl(
//                   Uri.parse(whatsappWebUrl),
//                   mode: LaunchMode.externalApplication,
//                 );
//               },
//               icon: const Icon(Icons.open_in_new),
//               label: const Text('Open WhatsApp Web'),
//             ),
//           ],
//         ),
//       );
//     }
//   } catch (e) {
//     // Fallback: Download the PDF
//     await _downloadPDFForWeb(pdf, invoice);
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('PDF downloaded: $e'),
//           backgroundColor: Colors.orange,
//           duration: const Duration(seconds: 4),
//         ),
//       );
//     }
//   }
// }
//
// // Download PDF for web
// Future<void> _downloadPDFForWeb(Uint8List pdf, InvoiceModel invoice) async {
//   try {
//     // file_saver 0.4.x: parameter is `fileExtension`, not `ext`.
//     // name already carries ".pdf", so includeExtension:false avoids
//     // ending up with "Invoice_1.pdf.pdf".
//     await FileSaver.instance.saveFile(
//       name: 'Invoice_${invoice.invoiceNo}.pdf',
//       bytes: pdf,
//       fileExtension: 'pdf',
//       includeExtension: false,
//       mimeType: MimeType.pdf,
//     );
//   } catch (e) {
//     // Fallback to a manual anchor-click download using package:web
//     // (the modern replacement for dart:html's AnchorElement).
//     final base64 = base64Encode(pdf);
//     final pdfDataUri = 'data:application/pdf;base64,$base64';
//     final anchor = web.HTMLAnchorElement()
//       ..href = pdfDataUri
//       ..download = 'Invoice_${invoice.invoiceNo}.pdf';
//     anchor.click();
//     anchor.remove();
//   }
// }
