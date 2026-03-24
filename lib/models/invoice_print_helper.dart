import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../services/invoice_apiservice.dart';

class InvoicePrintHelper {
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

  static Future<void> printInvoice({
    required BuildContext context,
    required InvoiceModel invoice,
    required List<Map<String, dynamic>> items,
    required String customerName,
    required String subtotal,
    required String taxAmount,
    required String taxPercentage,
    required String grandTotal,
    Company? company,
  }) async {
    try {
      final pdf = await generatePDF(
        invoice: invoice,
        items: items,
        customerName: customerName,
        subtotal: subtotal,
        taxAmount: taxAmount,
        taxPercentage: taxPercentage,
        grandTotal: grandTotal,
        company: company,
      );

      final bool isWeb = identical(0, 0.0);

      if (isWeb) {
        await downloadPDFWeb(
          pdf,
          'Invoice_${invoice.invoiceNo}.pdf',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF downloaded successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => pdf,
        );
      }
    } catch (e) {
      print('Error printing: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<Uint8List> generatePDF({
    required InvoiceModel invoice,
    required List<Map<String, dynamic>> items,
    required String customerName,
    required String subtotal,
    required String taxAmount,
    required String taxPercentage,
    required String grandTotal,
    Company? company,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => [
          _buildInvoiceContent(
            invoice: invoice,
            items: items,
            customerName: customerName,
            subtotal: subtotal,
            taxAmount: taxAmount,
            taxPercentage: taxPercentage,
            grandTotal: grandTotal,
            company: company,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInvoiceContent({
    required InvoiceModel invoice,
    required List<Map<String, dynamic>> items,
    required String customerName,
    required String subtotal,
    required String taxAmount,
    required String taxPercentage,
    required String grandTotal,
    Company? company,
  }) {
    // Helper function to safely get string values
    String getStringValue(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper function to safely get double values
    double getDoubleValue(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    double subtotalValue = getDoubleValue(subtotal);
    double taxAmountValue = getDoubleValue(taxAmount);
    double taxRateValue = getDoubleValue(taxPercentage);
    double grandTotalValue = getDoubleValue(grandTotal);
    double discountValue = 0.0;
    double taxableAmount = subtotalValue - discountValue;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Header - Reduced top space
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                getStringValue(company?.companyName, defaultValue: 'COMPANY NAME'),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 2),
              if (company?.address != null && company!.address.isNotEmpty)
                pw.Text(
                  company.address,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.Text(
                'Phone: ${getStringValue(company?.contactNo)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              if (company?.emailId != null && company!.emailId.isNotEmpty)
                pw.Text(
                  'Email: ${company.emailId}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              if (company?.gstNo != null && company!.gstNo.isNotEmpty)
                pw.Text(
                  'GST No: ${company.gstNo}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),

        // Invoice Title - Reduced spacing
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300),
              bottom: pw.BorderSide(color: PdfColors.grey300),
            ),
          ),
          child: pw.Center(
            child: pw.Text(
              'TAX INVOICE',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),

        pw.SizedBox(height: 12),

        // Bill Information - Reduced fields
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Left column
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Invoice No:', invoice.invoiceNo),
                  pw.SizedBox(height: 4),
                  _buildInfoRow(
                    'Invoice Date:',
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice.date)),
                  ),
                ],
              ),
              // Right column
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Customer Name:', customerName),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // Items Table Header - Separate columns for Product, Model, Size, Unit
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'S.No',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Product',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Model',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Size',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Unit',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Qty',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Rate',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Amount',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Items List - Separate columns
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          // Get product details from different possible field names
          String productName = item['productName'] ?? item['productname'] ?? '';
          String modelName = item['modelName'] ?? item['modelname'] ?? '';
          String sizeName = item['sizeName'] ?? item['sizename'] ?? '';
          String unitName = item['unitName'] ?? item['unitname'] ?? '';

          double quantity = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
          double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
          double amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;

          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    '${index + 1}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    productName,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    modelName,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    sizeName,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    unitName,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    quantity.toStringAsFixed(0),
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    '${rate.toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    '${amount.toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        pw.SizedBox(height: 12),

        // Totals Section with Tax Slab
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildTotalRow(
                'Subtotal:',
                'Rs. ${subtotalValue.toStringAsFixed(2)}',
                fontSize: 9,
              ),
              if (discountValue > 0) ...[
                pw.SizedBox(height: 2),
                _buildTotalRow(
                  'Discount:',
                  '-Rs. ${discountValue.toStringAsFixed(2)}',
                  fontSize: 9,
                ),
              ],
              pw.SizedBox(height: 2),
              _buildTotalRow(
                'Taxable Amount:',
                'Rs. ${taxableAmount.toStringAsFixed(2)}',
                fontSize: 9,
              ),
              pw.SizedBox(height: 4),

              // Tax Slab Box
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 2, bottom: 2),
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Tax Slab (${taxRateValue.toStringAsFixed(0)}%):',
                          style:  pw.TextStyle(
                            fontWeight: pw.FontWeight.normal,
                            fontSize: 9,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Rs. ${taxAmountValue.toStringAsFixed(2)}',
                          style:  pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'CGST (${(taxRateValue / 2)}%):',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Rs. ${(taxAmountValue / 2).toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'SGST (${(taxRateValue / 2)}%):',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Rs. ${(taxAmountValue / 2).toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 2),
              _buildTotalRow(
                'Grand Total:',
                'Rs. ${grandTotalValue.toStringAsFixed(2)}',
                isBold: true,
                fontSize: 11,
              ),
            ],
          ),
        ),

        // Amount in Words
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Row(
            children: [
              pw.Text(
                'Amount in Words: ',
                style:  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              ),
              pw.Expanded(
                child: pw.Text(
                  _convertToWords(grandTotalValue),
                  style:  pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          ),
        ),

        // Notes
        if (invoice.remarks.isNotEmpty)
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColors.yellow50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('📝 ', style: const pw.TextStyle(fontSize: 9)),
                pw.Expanded(
                  child: pw.Text(
                    invoice.remarks,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),

        pw.SizedBox(height: 16),

        // Divider before signature
        pw.Divider(),
        pw.SizedBox(height: 12),

        // Authorized Signature Section
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Left side - Customer Signature
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Customer Signature:',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 0.5,
                  color: PdfColors.grey400,
                ),
              ],
            ),

            // Right side - Authorized Signature
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Authorized Signatory',
                  style:  pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 180,
                  height: 0.5,
                  color: PdfColors.grey400,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '(Authorized Person)',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        // Footer
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'This is a computer generated invoice',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style:  pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style:  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          value.isNotEmpty ? value : '-',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false, double fontSize = 10}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  static String _convertToWords(double amount) {
    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();

    if (rupees == 0 && paise == 0) return 'Zero Rupees Only';

    String rupeesWord = _numberToWords(rupees);
    String result = rupeesWord + ' Rupees';

    if (paise > 0) {
      result += ' and ${_numberToWords(paise)} Paise';
    }

    return result + ' Only';
  }

  static String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    const units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    if (number < 20) return units[number];
    if (number < 100) {
      return tens[number ~/ 10] + (number % 10 != 0 ? ' ${units[number % 10]}' : '');
    }
    if (number < 1000) {
      return units[number ~/ 100] + ' Hundred' + (number % 100 != 0 ? ' ${_numberToWords(number % 100)}' : '');
    }
    if (number < 100000) {
      return _numberToWords(number ~/ 1000) + ' Thousand' + (number % 1000 != 0 ? ' ${_numberToWords(number % 1000)}' : '');
    }
    if (number < 10000000) {
      return _numberToWords(number ~/ 100000) + ' Lakh' + (number % 100000 != 0 ? ' ${_numberToWords(number % 100000)}' : '');
    }
    return _numberToWords(number ~/ 10000000) + ' Crore' + (number % 10000000 != 0 ? ' ${_numberToWords(number % 10000000)}' : '');
  }
}


// import 'dart:html' as html;
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:printing/printing.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:intl/intl.dart';
// import '../../services/invoice_apiservice.dart';
//
// class InvoicePrintHelper {
//   static Future<void> downloadPDFWeb(Uint8List pdfBytes, String fileName) async {
//     final blob = html.Blob([pdfBytes]);
//     final url = html.Url.createObjectUrlFromBlob(blob);
//     final anchor = html.AnchorElement(href: url)
//       ..setAttribute('download', fileName)
//       ..click();
//     html.Url.revokeObjectUrl(url);
//   }
//
//   static Future<void> printInvoice({
//     required BuildContext context,
//     required InvoiceModel invoice,
//     required List<Map<String, dynamic>> items,
//     required String customerName,
//     required String subtotal,
//     required String taxAmount,
//     required String taxPercentage,
//     required String grandTotal,
//     Company? company,
//   }) async {
//     try {
//       final pdf = await generatePDF(
//         invoice: invoice,
//         items: items,
//         customerName: customerName,
//         subtotal: subtotal,
//         taxAmount: taxAmount,
//         taxPercentage: taxPercentage,
//         grandTotal: grandTotal,
//         company: company,
//       );
//
//       final bool isWeb = identical(0, 0.0);
//
//       if (isWeb) {
//         await downloadPDFWeb(
//           pdf,
//           'Invoice_${invoice.invoiceNo}.pdf',
//         );
//
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('PDF downloaded successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else {
//         await Printing.layoutPdf(
//           onLayout: (format) async => pdf,
//         );
//       }
//     } catch (e) {
//       print('Error printing: $e');
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error generating PDF: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   static Future<Uint8List> generatePDF({
//     required InvoiceModel invoice,
//     required List<Map<String, dynamic>> items,
//     required String customerName,
//     required String subtotal,
//     required String taxAmount,
//     required String taxPercentage,
//     required String grandTotal,
//     Company? company,
//   }) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         build: (pw.Context context) {
//           return [
//             // Company Header Section
//             _buildCompanyHeader(company),
//             pw.SizedBox(height: 24),
//
//             // Invoice Title
//             pw.Center(
//               child: pw.Column(
//                 children: [
//                   pw.Text(
//                     'TAX INVOICE',
//                     style: pw.TextStyle(
//                       fontSize: 28,
//                       fontWeight: pw.FontWeight.bold,
//                       color: PdfColors.blue900,
//                     ),
//                   ),
//                   pw.SizedBox(height: 8),
//                   pw.Text(
//                     'Bill No: ${invoice.invoiceNo}  |  Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice.date))}',
//                     style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
//                   ),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 32),
//
//             // Bill To Section
//             pw.Container(
//               padding: const pw.EdgeInsets.all(16),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.grey400),
//                 borderRadius: pw.BorderRadius.circular(8),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Bill To:',
//                     style: pw.TextStyle(
//                       fontWeight: pw.FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   pw.SizedBox(height: 8),
//                   pw.Text('Customer Name: $customerName'),
//                   if (company?.gstNo != null && company!.gstNo.isNotEmpty)
//                     pw.Text('GSTIN/UIN: ${company.gstNo}'),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 32),
//
//             // Items Table
//             pw.Container(
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.grey400),
//                 borderRadius: pw.BorderRadius.circular(4),
//               ),
//               child: pw.Column(
//                 children: [
//                   // Table Header
//                   pw.Container(
//                     padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     color: PdfColors.grey300,
//                     child: pw.Row(
//                       children: [
//                         pw.Expanded(flex: 1, child: pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
//                         pw.Expanded(flex: 4, child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
//                         pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
//                         pw.Expanded(flex: 1, child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
//                         pw.Expanded(flex: 1, child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
//                       ],
//                     ),
//                   ),
//
//                   // Table Rows
//                   ...items.asMap().entries.map((entry) {
//                     final index = entry.key;
//                     final item = entry.value;
//
//                     // Build description with all available details
//                     final List<String> descriptionParts = [];
//
//                     // Try different possible field names
//                     String productName = item['productName'] ??
//                         item['productname'] ??
//                         item['product_name'] ??
//                         '';
//                     if (productName.isNotEmpty) {
//                       descriptionParts.add(productName);
//                     }
//
//                     String modelName = item['modelName'] ??
//                         item['modelname'] ??
//                         item['model_name'] ??
//                         '';
//                     if (modelName.isNotEmpty) {
//                       descriptionParts.add('Model: $modelName');
//                     }
//
//                     String sizeName = item['sizeName'] ??
//                         item['sizename'] ??
//                         item['size_name'] ??
//                         '';
//                     if (sizeName.isNotEmpty) {
//                       descriptionParts.add('Size: $sizeName');
//                     }
//
//                     String unitName = item['unitName'] ??
//                         item['unitname'] ??
//                         item['unit_name'] ??
//                         '';
//                     if (unitName.isNotEmpty) {
//                       descriptionParts.add('Unit: $unitName');
//                     }
//
//                     // If we have a pre-formatted description, use that instead
//                     String description = item['formattedDescription'] ?? '';
//                     if (description.isEmpty && descriptionParts.isNotEmpty) {
//                       description = descriptionParts.join(' | ');
//                     } else if (description.isEmpty) {
//                       description = productName.isNotEmpty ? productName : 'Item ${index + 1}';
//                     }
//
//                     // Get quantity, rate, amount with fallbacks
//                     String quantity = item['quantity']?.toString() ??
//                         item['qty']?.toString() ??
//                         '0';
//
//                     String rate = item['rate']?.toString() ?? '0';
//                     String amount = item['amount']?.toString() ?? '0';
//
//                     // Parse values for formatting
//                     double qtyValue = double.tryParse(quantity) ?? 0;
//                     double rateValue = double.tryParse(rate) ?? 0;
//                     double amountValue = double.tryParse(amount) ?? 0;
//
//                     return pw.Container(
//                       padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: pw.BoxDecoration(
//                         border: pw.Border(
//                           top: pw.BorderSide(color: PdfColors.grey400),
//                         ),
//                       ),
//                       child: pw.Row(
//                         children: [
//                           pw.Expanded(flex: 1, child: pw.Text('${index + 1}')),
//                           pw.Expanded(
//                             flex: 4,
//                             child: pw.Text(
//                               description,
//                               style: const pw.TextStyle(fontSize: 10),
//                             ),
//                           ),
//                           pw.Expanded(
//                             flex: 1,
//                             child: pw.Text(
//                               qtyValue.toStringAsFixed(0),
//                               textAlign: pw.TextAlign.right,
//                             ),
//                           ),
//                           pw.Expanded(
//                             flex: 1,
//                             child: pw.Text(
//                               '${_formatCurrency(rateValue)}',
//                               textAlign: pw.TextAlign.right,
//                             ),
//                           ),
//                           pw.Expanded(
//                             flex: 1,
//                             child: pw.Text(
//                               '${_formatCurrency(amountValue)}',
//                               textAlign: pw.TextAlign.right,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//
//                   // Add empty row for spacing if needed
//                   if (items.length < 5)
//                     pw.SizedBox(height: (5 - items.length) * 40),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 24),
//
//             // Totals Section
//             pw.Row(
//               mainAxisAlignment: pw.MainAxisAlignment.end,
//               children: [
//                 pw.Container(
//                   width: 300,
//                   padding: const pw.EdgeInsets.all(12),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       _buildPdfTotalRow('Subtotal:', _formatCurrency(double.tryParse(subtotal) ?? 0)),
//                       pw.SizedBox(height: 4),
//                       _buildPdfTotalRow('Tax ($taxPercentage%):', _formatCurrency(double.tryParse(taxAmount) ?? 0)),
//                       pw.Divider(thickness: 1),
//                       pw.SizedBox(height: 4),
//                       _buildPdfTotalRow('Total Amount:', _formatCurrency(double.tryParse(grandTotal) ?? 0), isBold: true),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             pw.SizedBox(height: 32),
//
//             // Footer with Terms and Authorized Sign
//             _buildFooter(),
//           ];
//         },
//       ),
//     );
//
//     return pdf.save();
//   }
//
//   static pw.Widget _buildCompanyHeader(Company? company) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(16),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.grey400),
//         borderRadius: pw.BorderRadius.circular(8),
//       ),
//       child: pw.Row(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           // Company Logo Placeholder (if you have logo loading logic)
//           pw.Container(
//             width: 80,
//             height: 80,
//             decoration: pw.BoxDecoration(
//               border: pw.Border.all(color: PdfColors.grey300),
//               borderRadius: pw.BorderRadius.circular(8),
//             ),
//             child: pw.Center(
//               child: pw.Icon(pw.IconData(0xe3c9), size: 40, color: PdfColors.grey600),
//             ),
//           ),
//           pw.SizedBox(width: 16),
//
//           // Company Details
//           pw.Expanded(
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   company?.companyName ?? 'COMPANY NAME',
//                   style: pw.TextStyle(
//                     fontSize: 18,
//                     fontWeight: pw.FontWeight.bold,
//                     color: PdfColors.blue900,
//                   ),
//                 ),
//                 pw.SizedBox(height: 8),
//                 if (company?.address != null && company!.address.isNotEmpty)
//                   pw.Text(
//                     company.address,
//                     style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
//                   ),
//                 pw.SizedBox(height: 4),
//                 if (company?.contactNo != null && company!.contactNo.isNotEmpty)
//                   pw.Text(
//                     'Tel: ${company.contactNo}',
//                     style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
//                   ),
//                 if (company?.emailId != null && company!.emailId.isNotEmpty)
//                   pw.Text(
//                     'Email: ${company.emailId}',
//                     style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
//                   ),
//                 if (company?.gstNo != null && company!.gstNo.isNotEmpty)
//                   pw.Text(
//                     'GST No: ${company.gstNo}',
//                     style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   static pw.Widget _buildFooter() {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: pw.CrossAxisAlignment.end,
//       children: [
//         // Terms and Conditions
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text(
//               'Terms & Conditions:',
//               style: pw.TextStyle(
//                 fontSize: 10,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//             pw.SizedBox(height: 4),
//             pw.Text(
//               '1. Goods once sold will not be taken back\n'
//                   '2. Payment is due within 15 days\n'
//                   '3. Subject to local jurisdiction',
//               style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
//             ),
//           ],
//         ),
//
//         // Authorized Signatory
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.end,
//           children: [
//             pw.Container(
//               width: 200,
//               padding: const pw.EdgeInsets.only(top: 8),
//               child: pw.Column(
//                 children: [
//                   pw.SizedBox(height: 40),
//                   pw.Container(
//                     width: 180,
//                     height: 1,
//                     color: PdfColors.black,
//                   ),
//                   pw.SizedBox(height: 8),
//                   pw.Text(
//                     'Authorized Signatory',
//                     style: pw.TextStyle(
//                       fontSize: 10,
//                       fontWeight: pw.FontWeight.normal,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   static pw.Widget _buildPdfTotalRow(String label, String value, {bool isBold = false}) {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         pw.Text(
//           label,
//           style: pw.TextStyle(
//             fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
//             fontSize: isBold ? 14 : 12,
//           ),
//         ),
//         pw.Text(
//           value,
//           style: pw.TextStyle(
//             fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
//             fontSize: isBold ? 14 : 12,
//           ),
//         ),
//       ],
//     );
//   }
//
//   static String _formatCurrency(double amount) {
//     return 'Rs. ${amount.toStringAsFixed(2)}';
//   }
// }