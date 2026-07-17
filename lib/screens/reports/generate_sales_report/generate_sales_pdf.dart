import 'generate_sales_pdf_io.dart'
    if (dart.library.html) 'generate_sales_pdf_web.dart'
    as impl;

export 'generate_sales_pdf_io.dart'
    if (dart.library.html) 'generate_sales_pdf_web.dart';

typedef File = impl.File;

class SalesReportService {
  // Generate PDF - Cross Platform
  static Future<File?> generatePdf({
    String? fromDate,
    String? toDate,
    String? search,
    String? source,
    String? product,
    String? salesPerson,
  }) {
    return impl.SalesReportService.generatePdf(
      fromDate: fromDate,
      toDate: toDate,
      search: search,
      source: source,
      product: product,
      salesPerson: salesPerson,
    );
  }

  // Open PDF - Cross Platform
  static Future<void> openPdf(File file) {
    return impl.SalesReportService.openPdf(file);
  }

  // Share PDF - Cross Platform
  static Future<void> sharePdf(File file) {
    return impl.SalesReportService.sharePdf(file);
  }

  // Delete PDF file
  static Future<void> deletePdf(File file) {
    return impl.SalesReportService.deletePdf(file);
  }

  // Check if file exists
  static Future<bool> fileExists(File file) {
    return impl.SalesReportService.fileExists(file);
  }
}

// import 'dart:io';
// import 'dart:js_interop';
//
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:kiruthikfab/services/config.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class SalesReportService {
//   // Generate PDF - Cross Platform
//   static Future<File?> generatePdf({
//     String? fromDate,
//     String? toDate,
//     String? search,
//     String? source,
//     String? product,
//     String? salesPerson,
//   }) async {
//     try {
//       // Get company ID from SharedPreferences
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       final companyId = prefs.getString('companyid') ?? '';
//
//       if (companyId.isEmpty) {
//         throw Exception('Company ID not found');
//       }
//
//       // Build URL with query parameters
//       var url = Uri.parse('$baseUrl/product_based_sales_report_all_pdf.php')
//           .replace(
//             queryParameters: fromDate == null && toDate == null
//                 ? {'companyid': companyId}
//                 : {
//                     'companyid': companyId,
//                     'fromdate': fromDate ?? '',
//                     'todate': toDate ?? '',
//                     'search': search ?? '',
//                     'source': source ?? '',
//                     'product': product ?? '',
//                     'salesperson': salesPerson ?? '',
//                   },
//           );
//
//       // Make GET request
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         if (kIsWeb) {
//           // Web platform - download and return file
//           return await _savePdfWeb(response.bodyBytes);
//         } else {
//           // Mobile/Desktop platforms
//           return await _savePdfMobile(response.bodyBytes);
//         }
//       } else {
//         throw Exception('Failed to generate report: ${response.statusCode}');
//       }
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Save PDF for Web platform
//   static Future<File?> _savePdfWeb(Uint8List pdfBytes) async {
//     try {
//       final fileName =
//           'Product_Based_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
//
//       final blob = web.Blob(
//         [pdfBytes.toJS].toJS,
//         web.BlobPropertyBag(type: 'application/pdf'),
//       );
//
//       final url = web.URL.createObjectURL(blob);
//
//       final anchor = web.HTMLAnchorElement()
//         ..href = url
//         ..download = fileName;
//
//       anchor.click();
//
//       web.URL.revokeObjectURL(url);
//
//       // For web, we'll create a temporary file
//       return await _createTempFileWeb(pdfBytes, fileName);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Create temp file for web
//   static Future<File?> _createTempFileWeb(
//     Uint8List pdfBytes,
//     String fileName,
//   ) async {
//     try {
//       final blob = web.Blob(
//         [pdfBytes.toJS].toJS,
//         web.BlobPropertyBag(type: 'application/pdf'),
//       );
//
//       final url = web.URL.createObjectURL(blob);
//
//       return File.fromUri(Uri.parse(url));
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Save PDF for Mobile/Desktop platforms
//   static Future<File?> _savePdfMobile(Uint8List pdfBytes) async {
//     try {
//       Directory directory;
//
//       if (Platform.isAndroid || Platform.isIOS) {
//         // Mobile platforms
//         directory = await getApplicationDocumentsDirectory();
//       } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//         // Desktop platforms
//         directory =
//             await getDownloadsDirectory() ??
//             await getApplicationDocumentsDirectory();
//       } else {
//         directory = await getApplicationDocumentsDirectory();
//       }
//
//       final filePath =
//           '${directory.path}/Product_Based_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final file = File(filePath);
//
//       // Write the PDF bytes to file
//       await file.writeAsBytes(pdfBytes);
//
//       return file;
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Get downloads directory for desktop
//   static Future<Directory?> getDownloadsDirectory() async {
//     try {
//       if (Platform.isWindows) {
//         // Windows downloads folder
//         final userDir = await getApplicationDocumentsDirectory();
//         final downloadsPath = '${userDir.path}\\Downloads';
//         final dir = Directory(downloadsPath);
//         if (!await dir.exists()) {
//           await dir.create(recursive: true);
//         }
//         return dir;
//       } else if (Platform.isLinux || Platform.isMacOS) {
//         // Linux/Mac downloads folder
//         final homeDir = Platform.environment['HOME'] ?? '';
//         final downloadsPath = '$homeDir/Downloads';
//         final dir = Directory(downloadsPath);
//         if (!await dir.exists()) {
//           await dir.create(recursive: true);
//         }
//         return dir;
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Open PDF - Cross Platform
//   static Future<void> openPdf(File file) async {
//     if (kIsWeb) {
//       // For web, open in new tab
//       final url = file.path;
//       web.window.open(url, '_blank');
//     } else {
//       // For mobile/desktop, use open_file package
//       try {
//         final result = await OpenFile.open(file.path);
//         if (result.type != ResultType.done) {
//           throw Exception('Could not open PDF');
//         }
//       } catch (e) {
//         rethrow;
//       }
//     }
//   }
//
//   // Share PDF - Cross Platform
//   static Future<void> sharePdf(File file) async {
//     try {
//       if (kIsWeb) {
//         // For web, share using Web Share API
//         try {
//           final bytes = await file.readAsBytes();
//           final blob = web.Blob(
//             [bytes.toJS].toJS,
//             web.BlobPropertyBag(type: 'application/pdf'),
//           );
//           final fileObj = web.File(
//             [blob].toJS,
//             'Product_Based_Sales_Report.pdf',
//           );
//
//           final canShare = web.window.navigator.canShare(
//             web.ShareData(files: [fileObj].toJS),
//           );
//
//           if (canShare) {
//             web.window.navigator.share(
//               web.ShareData(
//                 title: 'Product Based Sales Report',
//                 files: [fileObj].toJS,
//               ),
//             );
//             return;
//           }
//         } catch (e) {
//           final bytes = await file.readAsBytes();
//           final blob = web.Blob(
//             [bytes.toJS].toJS,
//             web.BlobPropertyBag(type: 'application/pdf'),
//           );
//
//           final url = web.URL.createObjectURL(blob);
//           final anchor = web.HTMLAnchorElement()
//             ..href = url
//             ..setAttribute('download', 'Product_Based_Sales_Report.pdf');
//           // html.AnchorElement(href: url)
//           //   ..setAttribute('download', 'Product_Based_Sales_Report.pdf')
//           //   ..click();
//           anchor.click();
//
//           Future.delayed(const Duration(seconds: 1), () {
//             web.URL.revokeObjectURL(url);
//           });
//         }
//       } else {
//         // For mobile/desktop, use share_plus package
//         try {
//           final xFile = XFile(file.path);
//           await SharePlus.instance.share(
//             ShareParams(
//               files: [xFile],
//               text: 'Product Based Sales Report',
//               subject: 'Sales Report PDF',
//             ),
//           );
//         } catch (e) {
//           rethrow;
//         }
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   // Delete PDF file
//   static Future<void> deletePdf(File file) async {
//     if (await file.exists()) {
//       await file.delete();
//     }
//   }
//
//   // Check if file exists
//   static Future<bool> fileExists(File file) async {
//     try {
//       return await file.exists();
//     } catch (e) {
//       return false;
//     }
//   }
// }
//
// //   Future<void> generatePdf(
// //   List<ProductBasedSalesReportModel> reportData,
// //   BuildContext context, {
// //   String? title,
// //   String? fromDate,
// //   String? toDate,
// // }) async {
// //
// //   if (reportData.isEmpty) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text("No records available to export")),
// //     );
// //     return;
// //   }
// //
// //   SharedPreferences prefs = await SharedPreferences.getInstance();
// //   final companyname = prefs.getString('companyname') ?? 'Company Name';
// //   final companyAddress = prefs.getString('companyaddress') ?? '';
// //   final companyPhone = prefs.getString('companyphone') ?? '';
// //   final companyEmail = prefs.getString('companyemail') ?? '';
// //   final logourl = prefs.getString('logourl') ?? '';
// //
// //   final pdf = pw.Document();
// //
// //   // Calculate totals
// //   int totalQty = 0;
// //   double totalAmount = 0.0;
// //   for (var item in reportData) {
// //     totalQty += int.tryParse(item.qty) ?? 0;
// //     totalAmount += double.tryParse(item.total) ?? 0.0;
// //   }
// //   final tamilFont = pw.Font.ttf(
// //     await rootBundle.load("assets/fonts/NotoSansTamil-Regular.ttf"),
// //   );
// //
// //   final tamilBold = pw.Font.ttf(
// //     await rootBundle.load("assets/fonts/NotoSansTamil-Bold.ttf"),
// //   );
// //   pdf.addPage(
// //     pw.MultiPage(
// //       theme: pw.ThemeData.withFont(base: tamilFont, bold: tamilBold),
// //       pageFormat: PdfPageFormat.a4.landscape,
// //       margin: const pw.EdgeInsets.all(20),
// //       header: (context) {
// //         return pw.Container(
// //           padding: const pw.EdgeInsets.only(bottom: 10),
// //           decoration: const pw.BoxDecoration(
// //             border: pw.Border(
// //               bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
// //             ),
// //           ),
// //           child: pw.Row(
// //             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
// //             children: [
// //               pw.Column(
// //                 crossAxisAlignment: pw.CrossAxisAlignment.start,
// //                 children: [
// //                   pw.Text(
// //                     companyname,
// //                     style: pw.TextStyle(
// //                       fontSize: 16,
// //                       fontWeight: pw.FontWeight.bold,
// //                       color: PdfColors.blue900,
// //                     ),
// //                   ),
// //                   if (companyAddress.isNotEmpty)
// //                     pw.Text(
// //                       companyAddress,
// //                       style: pw.TextStyle(
// //                         fontSize: 9,
// //                         color: PdfColors.grey700,
// //                       ),
// //                     ),
// //                   if (companyPhone.isNotEmpty || companyEmail.isNotEmpty)
// //                     pw.Text(
// //                       '${companyPhone.isNotEmpty ? 'Tel: $companyPhone' : ''}${companyPhone.isNotEmpty && companyEmail.isNotEmpty ? ' | ' : ''}${companyEmail.isNotEmpty ? 'Email: $companyEmail' : ''}',
// //                       style: pw.TextStyle(
// //                         fontSize: 9,
// //                         color: PdfColors.grey700,
// //                       ),
// //                     ),
// //                 ],
// //               ),
// //               pw.Column(
// //                 crossAxisAlignment: pw.CrossAxisAlignment.end,
// //                 children: [
// //                   pw.Text(
// //                     title ?? 'Product Based Sales Report',
// //                     style: pw.TextStyle(
// //                       fontSize: 14,
// //                       fontWeight: pw.FontWeight.bold,
// //                     ),
// //                   ),
// //                   pw.Text(
// //                     'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
// //                     style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
// //                   ),
// //                   if (fromDate != null && toDate != null)
// //                     pw.Text(
// //                       'Period: $fromDate to $toDate',
// //                       style: pw.TextStyle(
// //                         fontSize: 9,
// //                         color: PdfColors.grey700,
// //                       ),
// //                     ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //       footer: (context) {
// //         return pw.Container(
// //           padding: const pw.EdgeInsets.only(top: 10),
// //           decoration: const pw.BoxDecoration(
// //             border: pw.Border(
// //               top: pw.BorderSide(color: PdfColors.grey400, width: 1),
// //             ),
// //           ),
// //           child: pw.Row(
// //             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
// //             children: [
// //               pw.Text(
// //                 'Page ${context.pageNumber} of ${context.pagesCount}',
// //                 style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
// //               ),
// //               pw.Text(
// //                 'Printed on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
// //                 style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //       build: (context) {
// //         return [
// //           // Summary Cards
// //           pw.Container(
// //             margin: const pw.EdgeInsets.only(bottom: 15),
// //             padding: const pw.EdgeInsets.all(10),
// //             decoration: pw.BoxDecoration(
// //               color: PdfColors.grey100,
// //               borderRadius: pw.BorderRadius.circular(5),
// //             ),
// //             child: pw.Row(
// //               mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
// //               children: [
// //                 _buildSummaryCard(
// //                   'Total Records',
// //                   reportData.length.toString(),
// //                   PdfColors.blue700,
// //                 ),
// //                 _buildSummaryCard(
// //                   'Total Quantity',
// //                   totalQty.toString(),
// //                   PdfColors.green700,
// //                 ),
// //                 _buildSummaryCard(
// //                   'Total Amount',
// //                   '₹${NumberFormat('#,##0.00').format(totalAmount)}',
// //                   PdfColors.orange700,
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           // Table
// //           pw.TableHelper.fromTextArray(
// //             border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
// //             headerStyle: pw.TextStyle(
// //               fontWeight: pw.FontWeight.bold,
// //               fontSize: 10,
// //               color: PdfColors.white,
// //             ),
// //             headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
// //             cellStyle: const pw.TextStyle(fontSize: 9),
// //             cellAlignment: pw.Alignment.centerLeft,
// //             headerAlignment: pw.Alignment.center,
// //             headers: const [
// //               'S.No',
// //               'Invoice No',
// //               'Sales Date',
// //               'Source Name',
// //               'Products',
// //               'Sales Person',
// //               'Qty',
// //               'Amount',
// //             ],
// //             data: List.generate(reportData.length, (index) {
// //               final item = reportData[index];
// //               final amount = double.tryParse(item.total) ?? 0.0;
// //
// //               return [
// //                 '${index + 1}',
// //                 item.invoiceNo,
// //                 DateFormat('dd/MM/yyyy').format(DateTime.parse(item.salesDate)),
// //                 item.sourceName,
// //                 item.products,
// //                 item.salesPerson,
// //                 item.qty.toString(),
// //                 '₹${NumberFormat('#,##0.00').format(amount)}',
// //               ];
// //             }),
// //           ),
// //
// //           // Footer summary
// //           pw.SizedBox(height: 10),
// //           pw.Container(
// //             padding: const pw.EdgeInsets.all(8),
// //             decoration: pw.BoxDecoration(
// //               color: PdfColors.grey100,
// //               borderRadius: pw.BorderRadius.circular(5),
// //             ),
// //             child: pw.Row(
// //               mainAxisAlignment: pw.MainAxisAlignment.end,
// //               children: [
// //                 pw.Text(
// //                   'Total Records: ${reportData.length}  |  Total Qty: $totalQty  |  Total Amount: ₹${NumberFormat('#,##0.00').format(totalAmount)}',
// //                   style: pw.TextStyle(
// //                     fontSize: 10,
// //                     fontWeight: pw.FontWeight.bold,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ];
// //       },
// //     ),
// //   );
// //
// //   final Uint8List bytes = await pdf.save();
// //   final fileName =
// //       'Product_Sales_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
// //
// //   await Printing.layoutPdf(
// //     onLayout: (PdfPageFormat format) async => bytes,
// //     name: fileName,
// //   );
// // }
// //
// // pw.Widget _buildSummaryCard(String label, String value, PdfColor color) {
// //   return pw.Column(
// //     crossAxisAlignment: pw.CrossAxisAlignment.center,
// //     children: [
// //       pw.Text(
// //         label,
// //         style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
// //       ),
// //       pw.SizedBox(height: 4),
// //       pw.Text(
// //         value,
// //         style: pw.TextStyle(
// //           fontSize: 14,
// //           fontWeight: pw.FontWeight.bold,
// //           color: color,
// //         ),
// //       ),
// //     ],
// //   );
// // }
// //
// // // Alternative: Direct print without preview
// // Future<void> generatePdfAndPrint(
// //   List<ProductBasedSalesReportModel> reportData,
// //   BuildContext context, {
// //   String? title,
// //   String? fromDate,
// //   String? toDate,
// // }) async {
// //   if (reportData.isEmpty) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text("No records available to export")),
// //     );
// //     return;
// //   }
// //
// //   try {
// //     final pdfBytes = await _generatePdfBytes(
// //       reportData,
// //       title: title,
// //       fromDate: fromDate,
// //       toDate: toDate,
// //     );
// //
// //     // Get printer with null check
// //     final printer = await Printing.pickPrinter(context: context);
// //     if (printer == null) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text("No printer selected")));
// //       return;
// //     }
// //
// //     await Printing.directPrintPdf(
// //       printer: printer, // Now this is non-nullable
// //       onLayout: (PdfPageFormat format) async => pdfBytes,
// //       name: 'Product_Sales_Report_${DateTime.now().millisecondsSinceEpoch}',
// //     );
// //   } catch (e) {
// //     ScaffoldMessenger.of(
// //       context,
// //     ).showSnackBar(SnackBar(content: Text("Failed to print: $e")));
// //   }
// // }
// //
// // Future<Uint8List> _generatePdfBytes(
// //   List<ProductBasedSalesReportModel> reportData, {
// //   String? title,
// //   String? fromDate,
// //   String? toDate,
// // }) async {
// //   SharedPreferences prefs = await SharedPreferences.getInstance();
// //   final companyname = prefs.getString('companyname') ?? 'Company Name';
// //   final companyAddress = prefs.getString('companyaddress') ?? '';
// //   final companyPhone = prefs.getString('companyphone') ?? '';
// //   final companyEmail = prefs.getString('companyemail') ?? '';
// //
// //   final pdf = pw.Document();
// //
// //   pdf.addPage(
// //     pw.MultiPage(
// //       pageFormat: PdfPageFormat.a4.landscape,
// //       margin: const pw.EdgeInsets.all(20),
// //       build: (context) => [
// //         // Your page content here (similar to above)
// //       ],
// //     ),
// //   );
// //
// //   return await pdf.save();
// // }
