import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kiruthikfab/services/config.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesReportExcel {
  // Generate and download report with filters
  Future<bool> generateAndDownloadReport({
    String? fromDate,
    String? toDate,
    String? search,
    String? source,
    String? product,
    String? salesPerson,
    Function(double progress)? onProgress,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyid') ?? '';

      if (companyId.isEmpty) {
        throw Exception('Company ID not found');
      }
      if (kIsWeb) {
        return await _downloadReportWeb(
          companyId: companyId,
          fromDate: fromDate,
          toDate: toDate,
          search: search,
          source: source,
          product: product,
          salesPerson: salesPerson,
        );
      }
      // For mobile/desktop - download to local storage
      else {
        return await _downloadReportNative(
          companyId: companyId,
          fromDate: fromDate,
          toDate: toDate,
          onProgress: onProgress,
          search: search,
          source: source,
          product: product,
          salesPerson: salesPerson,
        );
      }
    } catch (e) {
      debugPrint('Error downloading report: $e');
      return false;
    }
  }

  // Web implementation - opens in new tab
  Future<bool> _downloadReportWeb({
    required String companyId,
    String? fromDate,
    String? toDate,
    String? search,
    String? source,
    String? product,
    String? salesPerson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/product_based_sales_report_all_excel.php')
          .replace(
            queryParameters: {
              'companyid': companyId,
              if (fromDate != null && fromDate.isNotEmpty) 'fromdate': fromDate,
              if (toDate != null && toDate.isNotEmpty) 'todate': toDate,
              if (search != null && search.isNotEmpty) 'search': search,
              if (source != null && source.isNotEmpty) 'source': source,
              if (product != null && product.isNotEmpty) 'product': product,
              if (salesPerson != null && salesPerson.isNotEmpty)
                'salesPerson': salesPerson,
            },
          );

      // FIXED: Use the correct package method
      await _openUrl(uri.toString());
      return true;
    } catch (e) {
      debugPrint('Web download error: $e');
      return false;
    }
  }

  // Native implementation (Android/iOS/Desktop)
  Future<bool> _downloadReportNative({
    required String companyId,
    String? fromDate,
    String? toDate,
    Function(double progress)? onProgress,
    String? search,
    String? source,
    String? product,
    String? salesPerson,
  }) async {
    try {
      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/product_based_sales_report_all_excel.php')
          .replace(
            queryParameters: {
              'companyid': companyId,
              if (fromDate != null && fromDate.isNotEmpty) 'fromdate': fromDate,
              if (toDate != null && toDate.isNotEmpty) 'todate': toDate,
              if (search != null && search.isNotEmpty) 'search': search,
              if (source != null && source.isNotEmpty) 'source': source,
              if (product != null && product.isNotEmpty) 'product': product,
              if (salesPerson != null && salesPerson.isNotEmpty)
                'salesPerson': salesPerson,
            },
          );

      // Download file with progress
      final client = http.Client();
      final request = http.Request('GET', uri);
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception('Failed to download: ${streamedResponse.statusCode}');
      }

      // Get content length for progress
      final contentLength = streamedResponse.contentLength;
      final bytes = <int>[];
      int downloaded = 0;

      // Download with progress
      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;
        if (contentLength != null && onProgress != null) {
          onProgress(downloaded / contentLength);
        }
      }

      // Determine save location
      final filename =
          'Product_Based_Sales_Report_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xlsx';

      Directory saveDir;
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile - use downloads directory
        saveDir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        // For desktop - use downloads directory
        saveDir = await getDownloadsDirectory() ?? Directory.current;
      }

      final file = File('${saveDir.path}/$filename');
      await file.writeAsBytes(bytes);

      // Open the file
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open file');
      }

      return true;
    } catch (e) {
      debugPrint('Native download error: $e');
      return false;
    }
  }

  // FIXED: Helper to open URL on web
  Future<void> _openUrl(String url) async {
    if (kIsWeb) {
      // Use the proper package for opening URLs
      // Make sure you have the 'url_launcher' package in pubspec.yaml
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
// class SalesReportExcel {
//   // Generate and download report with filters
//   Future<bool> generateAndDownloadReport({
//     String? fromDate,
//     String? toDate,
//     String? search,
//     String? source,
//     String? product,
//     String? salesPerson,
//
//     Function(double progress)? onProgress,
//   }) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       final companyId = prefs.getString('companyid') ?? '';
//
//       if (companyId.isEmpty) {
//         throw Exception('Company ID not found');
//       }
//       if (kIsWeb) {
//         return await _downloadReportWeb(
//           companyId: companyId,
//           fromDate: fromDate,
//           toDate: toDate,
//           search: search,
//           source: source,
//           product: product,
//           salesPerson: salesPerson,
//         );
//       }
//       // For mobile/desktop - download to local storage
//       else {
//         return await _downloadReportNative(
//           companyId: companyId,
//           fromDate: fromDate,
//           toDate: toDate,
//           onProgress: onProgress,
//           search: search,
//           source: source,
//           product: product,
//           salesPerson: salesPerson,
//         );
//       }
//     } catch (e) {
//       debugPrint('Error downloading report: $e');
//       return false;
//     }
//   }
//
//   // Web implementation - opens in new tab
//   Future<bool> _downloadReportWeb({
//     required String companyId,
//     String? fromDate,
//     String? toDate,
//     String? search,
//     String? source,
//     String? product,
//     String? salesPerson,
//   }) async {
//     try {
//       final uri = Uri.parse('$baseUrl/product_based_sales_report_all_excel.php')
//           .replace(
//             queryParameters: {
//               'companyid': companyId,
//               if (fromDate != null && fromDate.isNotEmpty) 'fromdate': fromDate,
//               if (toDate != null && toDate.isNotEmpty) 'todate': toDate,
//               if (search != null && search.isNotEmpty) 'search': search,
//               if (source != null && source.isNotEmpty) 'source': source,
//               if (product != null && product.isNotEmpty) 'product': product,
//               if (salesPerson != null && salesPerson.isNotEmpty)
//                 'salesPerson': salesPerson,
//             },
//           );
//
//       await openUrl(uri.toString());
//       return true;
//     } catch (e) {
//       debugPrint('Web download error: $e');
//       return false;
//     }
//   }
//
//   // Native implementation (Android/iOS/Desktop)
//   Future<bool> _downloadReportNative({
//     required String companyId,
//     String? fromDate,
//     String? toDate,
//     Function(double progress)? onProgress,
//     String? search,
//     String? source,
//     String? product,
//     String? salesPerson,
//   }) async {
//     try {
//       // Request storage permission for Android
//       // if (Platform.isAndroid) {
//       //   final status = await Permission.storage.request();
//       //   if (!status.isGranted) {
//       //     throw Exception('Storage permission denied');
//       //   }
//       // }
//
//       // Build URL with query parameters
//       final uri = Uri.parse('$baseUrl/product_based_sales_report_all_excel.php')
//           .replace(
//             queryParameters: {
//               'companyid': companyId,
//               if (fromDate != null && fromDate.isNotEmpty) 'fromdate': fromDate,
//               if (toDate != null && toDate.isNotEmpty) 'todate': toDate,
//               if (search != null && search.isNotEmpty) 'search': search,
//               if (source != null && source.isNotEmpty) 'source': source,
//               if (product != null && product.isNotEmpty) 'product': product,
//               if (salesPerson != null && salesPerson.isNotEmpty)
//                 'salesPerson': salesPerson,
//             },
//           );
//
//       // Download file with progress
//       final client = http.Client();
//       final request = http.Request('GET', uri);
//       final streamedResponse = await client.send(request);
//
//       if (streamedResponse.statusCode != 200) {
//         throw Exception('Failed to download: ${streamedResponse.statusCode}');
//       }
//
//       // Get content length for progress
//       final contentLength = streamedResponse.contentLength;
//       final bytes = <int>[];
//       int downloaded = 0;
//
//       // Download with progress
//       await for (final chunk in streamedResponse.stream) {
//         bytes.addAll(chunk);
//         downloaded += chunk.length;
//         if (contentLength != null && onProgress != null) {
//           onProgress(downloaded / contentLength);
//         }
//       }
//
//       // Determine save location
//       final filename =
//           'Product_Based_Sales_Report_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xlsx';
//
//       Directory saveDir;
//       if (Platform.isAndroid || Platform.isIOS) {
//         // For mobile - use downloads directory
//         saveDir =
//             await getDownloadsDirectory() ??
//             await getApplicationDocumentsDirectory();
//       } else {
//         // For desktop - use downloads directory
//         saveDir = await getDownloadsDirectory() ?? Directory.current;
//       }
//
//       final file = File('${saveDir.path}/$filename');
//       await file.writeAsBytes(bytes);
//
//       // Open the file
//       final result = await OpenFilex.open(file.path);
//       if (result.type != ResultType.done) {
//         throw Exception('Failed to open file');
//       }
//
//       return true;
//     } catch (e) {
//       debugPrint('Native download error: $e');
//       return false;
//     }
//   }
//
//   // Helper to open URL on web
//   Future<void> openUrl(String url) async {
//     if (kIsWeb) {
//       openUrl(url);
//     }
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column;
//
// import '../../../models/ProductBasedSalesReportModel.dart';
// import 'file_saver/file_saver.dart';
//
// Future<void> generateSalesExcel(
//   List<ProductBasedSalesReportModel> reportData,
//   BuildContext context, {
//   String? title,
//   String? fromDate,
//   String? toDate,
// }) async {
//   if (reportData.isEmpty) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("No records available")));
//     return;
//   }
//
//   final prefs = await SharedPreferences.getInstance();
//
//   final companyName = prefs.getString("companyname") ?? "Company Name";
//   final companyAddress = prefs.getString("companyaddress") ?? "";
//   final companyPhone = prefs.getString("companyphone") ?? "";
//   final companyEmail = prefs.getString("companyemail") ?? "";
//
//   final workbook = Workbook();
//
//   // Force Indian culture so number/date formats aren't reinterpreted
//   // by a different regional format when opened in Excel.
//   workbook.culture = 'en-IN';
//
//   final sheet = workbook.worksheets[0];
//   sheet.name = "Sales Report";
//
//   sheet.pageSetup.orientation = ExcelPageOrientation.landscape;
//   sheet.pageSetup.paperSize = ExcelPaperSize.paperA4;
//   sheet.pageSetup.leftMargin = 0.3;
//   sheet.pageSetup.rightMargin = 0.3;
//   sheet.pageSetup.topMargin = 0.4;
//   sheet.pageSetup.bottomMargin = 0.4;
//   sheet.showGridlines = false;
//
//   // ---------- Totals ----------
//   int totalQty = 0;
//   double totalAmount = 0;
//   for (final item in reportData) {
//     totalQty += int.tryParse(item.qty) ?? 0;
//     totalAmount += double.tryParse(item.total) ?? 0;
//   }
//
//   // ---------- Safe date parser ----------
//   // Handles the common "yyyy-MM-dd HH:mm:ss" format from your API,
//   // and falls back gracefully instead of throwing if the string is malformed.
//   DateTime? _safeParseDate(String? raw) {
//     if (raw == null || raw.trim().isEmpty) return null;
//     try {
//       return DateTime.parse(raw.trim());
//     } catch (_) {
//       try {
//         // Fallback for dd/MM/yyyy or dd-MM-yyyy style strings
//         final cleaned = raw.trim().replaceAll('-', '/');
//         final parts = cleaned.split('/');
//         if (parts.length == 3) {
//           final day = int.tryParse(parts[0]);
//           final month = int.tryParse(parts[1]);
//           final year = int.tryParse(parts[2]);
//           if (day != null && month != null && year != null) {
//             return DateTime(year, month, day);
//           }
//         }
//       } catch (_) {}
//       return null;
//     }
//   }
//
//   // ---------- Styles ----------
//   Style companyStyle = workbook.styles.add("companyStyle");
//   companyStyle.bold = true;
//   companyStyle.fontSize = 16;
//   companyStyle.fontColor = "#1A3A6B";
//   companyStyle.hAlign = HAlignType.left;
//   companyStyle.vAlign = VAlignType.center;
//
//   Style titleStyle = workbook.styles.add("titleStyle");
//   titleStyle.bold = true;
//   titleStyle.fontSize = 14;
//   titleStyle.hAlign = HAlignType.right;
//   titleStyle.vAlign = VAlignType.center;
//
//   Style greyLeftStyle = workbook.styles.add("greyLeftStyle");
//   greyLeftStyle.fontSize = 9;
//   greyLeftStyle.fontColor = "#595959";
//   greyLeftStyle.hAlign = HAlignType.left;
//
//   Style greyRightStyle = workbook.styles.add("greyRightStyle");
//   greyRightStyle.fontSize = 9;
//   greyRightStyle.fontColor = "#595959";
//   greyRightStyle.hAlign = HAlignType.right;
//
//   Style borderLineStyle = workbook.styles.add("borderLineStyle");
//   borderLineStyle.borders.bottom.lineStyle = LineStyle.thin;
//   borderLineStyle.borders.bottom.color = "#BFBFBF";
//
//   Style summaryPanelStyle = workbook.styles.add("summaryPanelStyle");
//   summaryPanelStyle.backColor = "#F2F2F2";
//
//   Style summaryLabelStyle = workbook.styles.add("summaryLabelStyle");
//   summaryLabelStyle.backColor = "#F2F2F2";
//   summaryLabelStyle.fontSize = 9;
//   summaryLabelStyle.fontColor = "#595959";
//   summaryLabelStyle.hAlign = HAlignType.center;
//
//   Style summaryValueStyle = workbook.styles.add("summaryValueStyle");
//   summaryValueStyle.backColor = "#F2F2F2";
//   summaryValueStyle.bold = true;
//   summaryValueStyle.fontSize = 14;
//   summaryValueStyle.hAlign = HAlignType.center;
//
//   Style headerStyle = workbook.styles.add("headerStyle");
//   headerStyle.backColor = "#1F4E78";
//   headerStyle.fontColor = "#FFFFFF";
//   headerStyle.bold = true;
//   headerStyle.fontSize = 10;
//   headerStyle.hAlign = HAlignType.center;
//   headerStyle.vAlign = VAlignType.center;
//   headerStyle.borders.all.lineStyle = LineStyle.thin;
//   headerStyle.borders.all.color = "#BFBFBF";
//
//   Style cellStyle = workbook.styles.add("cellStyle");
//   cellStyle.fontSize = 9;
//   cellStyle.vAlign = VAlignType.center;
//   cellStyle.borders.all.lineStyle = LineStyle.thin;
//   cellStyle.borders.all.color = "#BFBFBF";
//
//   Style altCellStyle = workbook.styles.add("altCellStyle");
//   altCellStyle.fontSize = 9;
//   altCellStyle.vAlign = VAlignType.center;
//   altCellStyle.backColor = "#F8F9FA";
//   altCellStyle.borders.all.lineStyle = LineStyle.thin;
//   altCellStyle.borders.all.color = "#BFBFBF";
//
//   Style totalStyle = workbook.styles.add("totalStyle");
//   totalStyle.bold = true;
//   totalStyle.fontSize = 10;
//   totalStyle.backColor = "#D9EAD3";
//   totalStyle.borders.all.lineStyle = LineStyle.thick;
//
//   // ---------- Currency format ----------
//   // Literal ₹ quoted so Excel treats it as text, not a format token.
//   const String rupeeFormat = '"₹"#,##0.00';
//   const String dateFormatPattern = "dd/MM/yyyy";
//   const String totalRupeeFormat = '"₹"#,##0.00';
//
//   // IMPORTANT: Syncfusion XlsIO named styles (workbook.styles.add) are
//   // SHARED objects. If you assign `cellStyle`/`altCellStyle` to a whole
//   // row range and later set `.numberFormat` on a single cell within that
//   // range, XlsIO mutates the shared style itself — so every other cell
//   // using that same named style (i.e. every row) silently picks up the
//   // same number format. That was why ALL columns ended up showing the
//   // rupee format instead of just the Amount column.
//   //
//   // Fix: give the date and amount columns their OWN dedicated named
//   // styles (with the format baked in), separate from the shared
//   // row style, so mutating one never leaks into other columns.
//   Style dateCellStyle = workbook.styles.add("dateCellStyle");
//   dateCellStyle.fontSize = 9;
//   dateCellStyle.vAlign = VAlignType.center;
//   dateCellStyle.borders.all.lineStyle = LineStyle.thin;
//   dateCellStyle.borders.all.color = "#BFBFBF";
//   dateCellStyle.numberFormat = dateFormatPattern;
//
//   Style altDateCellStyle = workbook.styles.add("altDateCellStyle");
//   altDateCellStyle.fontSize = 9;
//   altDateCellStyle.vAlign = VAlignType.center;
//   altDateCellStyle.backColor = "#F8F9FA";
//   altDateCellStyle.borders.all.lineStyle = LineStyle.thin;
//   altDateCellStyle.borders.all.color = "#BFBFBF";
//   altDateCellStyle.numberFormat = dateFormatPattern;
//
//   Style amountCellStyle = workbook.styles.add("amountCellStyle");
//   amountCellStyle.fontSize = 9;
//   amountCellStyle.vAlign = VAlignType.center;
//   amountCellStyle.borders.all.lineStyle = LineStyle.thin;
//   amountCellStyle.borders.all.color = "#BFBFBF";
//   amountCellStyle.numberFormat = rupeeFormat;
//
//   Style altAmountCellStyle = workbook.styles.add("altAmountCellStyle");
//   altAmountCellStyle.fontSize = 9;
//   altAmountCellStyle.vAlign = VAlignType.center;
//   altAmountCellStyle.backColor = "#F8F9FA";
//   altAmountCellStyle.borders.all.lineStyle = LineStyle.thin;
//   altAmountCellStyle.borders.all.color = "#BFBFBF";
//   altAmountCellStyle.numberFormat = rupeeFormat;
//
//   Style totalAmountStyle = workbook.styles.add("totalAmountStyle");
//   totalAmountStyle.bold = true;
//   totalAmountStyle.fontSize = 10;
//   totalAmountStyle.backColor = "#D9EAD3";
//   totalAmountStyle.borders.all.lineStyle = LineStyle.thick;
//   totalAmountStyle.numberFormat = totalRupeeFormat;
//
//   int row = 1;
//
//   final headers = [
//     "S.No",
//     "Invoice No",
//     "Sales Date",
//     "Source Name",
//     "Products",
//     "Sales Person",
//     "Qty",
//     "Amount",
//   ];
//
//   for (int i = 0; i < headers.length; i++) {
//     final cell = sheet.getRangeByIndex(row, i + 1);
//     cell.setText(headers[i]);
//     cell.cellStyle = headerStyle;
//   }
//   row++;
//
//   final dataStartRow = row;
//
//   for (int i = 0; i < reportData.length; i++) {
//     final item = reportData[i];
//     final rowStyle = i.isEven ? cellStyle : altCellStyle;
//     final dateStyle = i.isEven ? dateCellStyle : altDateCellStyle;
//     final amountStyle = i.isEven ? amountCellStyle : altAmountCellStyle;
//
//     sheet.getRangeByIndex(row, 1).setNumber((i + 1).toDouble());
//     sheet.getRangeByIndex(row, 2).setText(item.invoiceNo);
//
//     final parsedDate = _safeParseDate(item.salesDate);
//     if (parsedDate != null) {
//       sheet.getRangeByIndex(row, 3).setDateTime(parsedDate);
//     } else {
//       // Fallback: show raw text rather than crashing the export
//       sheet.getRangeByIndex(row, 3).setText(item.salesDate);
//     }
//
//     sheet.getRangeByIndex(row, 4).setText(item.sourceName);
//     sheet.getRangeByIndex(row, 5).setText(item.products);
//     sheet.getRangeByIndex(row, 6).setText(item.salesPerson);
//     sheet
//         .getRangeByIndex(row, 7)
//         .setNumber((int.tryParse(item.qty) ?? 0).toDouble());
//
//     final amount = double.tryParse(item.total) ?? 0;
//     sheet.getRangeByIndex(row, 8).setNumber(amount);
//
//     // Apply the plain shared row style to the whole row first...
//     sheet.getRangeByName("A$row:H$row").cellStyle = rowStyle;
//
//     // ...then overwrite ONLY the date and amount cells with their own
//     // dedicated (non-shared-with-other-columns) styles. This avoids
//     // ever calling `.numberFormat =` directly on a cell that carries the
//     // shared rowStyle, which is what caused the style-wide corruption.
//     if (parsedDate != null) {
//       sheet.getRangeByIndex(row, 3).cellStyle = dateStyle;
//     }
//     sheet.getRangeByIndex(row, 8).cellStyle = amountStyle;
//
//     row++;
//   }
//
//   // ---------- Totals row ----------
//   sheet.getRangeByIndex(row, 1).setText("TOTAL");
//   sheet.getRangeByName("A$row:F$row").merge();
//   sheet.getRangeByIndex(row, 7).setNumber(totalQty.toDouble());
//   sheet.getRangeByIndex(row, 8).setNumber(totalAmount);
//   sheet.getRangeByName("A$row:H$row").cellStyle = totalStyle;
//   // Dedicated style for the amount cell only — same reasoning as above.
//   sheet.getRangeByIndex(row, 8).cellStyle = totalAmountStyle;
//
//   final lastRow = row;
//   sheet.getRangeByIndex(1, 1).columnWidth = 8;
//   sheet.getRangeByIndex(1, 2).columnWidth = 18;
//   sheet.getRangeByIndex(1, 3).columnWidth = 15;
//   sheet.getRangeByIndex(1, 4).columnWidth = 25;
//   sheet.getRangeByIndex(1, 5).columnWidth = 35;
//   sheet.getRangeByIndex(1, 6).columnWidth = 22;
//   sheet.getRangeByIndex(1, 7).columnWidth = 10;
//   sheet.getRangeByIndex(1, 8).columnWidth = 18;
//
//   sheet.getRangeByIndex(6, 1, 7, 8).rowHeight = 20;
//
//   sheet.getRangeByIndex(dataStartRow, 2).freezePanes();
//   sheet.autoFilters.filterRange = sheet.getRangeByName(
//     "A${dataStartRow - 1}:H$lastRow",
//   );
//
//   row += 2;
//
//   sheet.pageSetup.printArea = "A1:H$row";
//   sheet.pageSetup.fitToPagesWide = 1;
//   sheet.pageSetup.fitToPagesTall = 0;
//   sheet.pageSetup.isCenterHorizontally = true;
//
//   final List<int> bytes = workbook.saveAsStream();
//   workbook.dispose();
//
//   // ---------- Save & open (works on web, Android, iOS, desktop) ----------
//   final fileName =
//       'Product_Sales_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
//
//   if (context.mounted) {
//     await saveAndOpenExcel(bytes, fileName, context);
//   }
// }
