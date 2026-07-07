import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/ProductBasedSalesReportModel.dart';

Future<void> generatePdf(
  List<ProductBasedSalesReportModel> reportData,
  BuildContext context, {
  String? title,
  String? fromDate,
  String? toDate,
}) async {
  if (reportData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No records available to export")),
    );
    return;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final companyname = prefs.getString('companyname') ?? 'Company Name';
  final companyAddress = prefs.getString('companyaddress') ?? '';
  final companyPhone = prefs.getString('companyphone') ?? '';
  final companyEmail = prefs.getString('companyemail') ?? '';
  final logourl = prefs.getString('logourl') ?? '';

  final pdf = pw.Document();

  // Calculate totals
  int totalQty = 0;
  double totalAmount = 0.0;
  for (var item in reportData) {
    totalQty += int.tryParse(item.qty) ?? 0;
    totalAmount += double.tryParse(item.total) ?? 0.0;
  }
  final tamilFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoSansTamil-Regular.ttf"),
  );

  final tamilBold = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoSansTamil-Bold.ttf"),
  );
  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: tamilFont, bold: tamilBold),
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      header: (context) {
        return pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyname,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  if (companyAddress.isNotEmpty)
                    pw.Text(
                      companyAddress,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  if (companyPhone.isNotEmpty || companyEmail.isNotEmpty)
                    pw.Text(
                      '${companyPhone.isNotEmpty ? 'Tel: $companyPhone' : ''}${companyPhone.isNotEmpty && companyEmail.isNotEmpty ? ' | ' : ''}${companyEmail.isNotEmpty ? 'Email: $companyEmail' : ''}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    title ?? 'Product Based Sales Report',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  if (fromDate != null && toDate != null)
                    pw.Text(
                      'Period: $fromDate to $toDate',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      footer: (context) {
        return pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Printed on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        );
      },
      build: (context) {
        return [
          // Summary Cards
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                  'Total Records',
                  reportData.length.toString(),
                  PdfColors.blue700,
                ),
                _buildSummaryCard(
                  'Total Quantity',
                  totalQty.toString(),
                  PdfColors.green700,
                ),
                _buildSummaryCard(
                  'Total Amount',
                  '₹${NumberFormat('#,##0.00').format(totalAmount)}',
                  PdfColors.orange700,
                ),
              ],
            ),
          ),

          // Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.center,
            headers: const [
              'S.No',
              'Invoice No',
              'Sales Date',
              'Source Name',
              'Products',
              'Sales Person',
              'Qty',
              'Amount',
            ],
            data: List.generate(reportData.length, (index) {
              final item = reportData[index];
              final amount = double.tryParse(item.total) ?? 0.0;

              return [
                '${index + 1}',
                item.invoiceNo,
                DateFormat('dd/MM/yyyy').format(DateTime.parse(item.salesDate)),
                item.sourceName,
                item.products,
                item.salesPerson,
                item.qty.toString(),
                '₹${NumberFormat('#,##0.00').format(amount)}',
              ];
            }),
          ),

          // Footer summary
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total Records: ${reportData.length}  |  Total Qty: $totalQty  |  Total Amount: ₹${NumberFormat('#,##0.00').format(totalAmount)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    ),
  );

  final Uint8List bytes = await pdf.save();
  final fileName =
      'Product_Sales_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => bytes,
    name: fileName,
  );
}

pw.Widget _buildSummaryCard(String label, String value, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}

// Alternative: Direct print without preview
Future<void> generatePdfAndPrint(
  List<ProductBasedSalesReportModel> reportData,
  BuildContext context, {
  String? title,
  String? fromDate,
  String? toDate,
}) async {
  if (reportData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No records available to export")),
    );
    return;
  }

  try {
    final pdfBytes = await _generatePdfBytes(
      reportData,
      title: title,
      fromDate: fromDate,
      toDate: toDate,
    );

    // Get printer with null check
    final printer = await Printing.pickPrinter(context: context);
    if (printer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No printer selected")));
      return;
    }

    await Printing.directPrintPdf(
      printer: printer, // Now this is non-nullable
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Product_Sales_Report_${DateTime.now().millisecondsSinceEpoch}',
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Failed to print: $e")));
  }
}

Future<Uint8List> _generatePdfBytes(
  List<ProductBasedSalesReportModel> reportData, {
  String? title,
  String? fromDate,
  String? toDate,
}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final companyname = prefs.getString('companyname') ?? 'Company Name';
  final companyAddress = prefs.getString('companyaddress') ?? '';
  final companyPhone = prefs.getString('companyphone') ?? '';
  final companyEmail = prefs.getString('companyemail') ?? '';

  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => [
        // Your page content here (similar to above)
      ],
    ),
  );

  return await pdf.save();
}
