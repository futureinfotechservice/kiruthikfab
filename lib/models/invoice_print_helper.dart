import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/invoice_apiservice.dart';

class InvoicePrintHelper {
  static Future<void> downloadPDFWeb(Uint8List pdfBytes, String fileName) async {
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
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
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'TAX INVOICE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Bill No: ${invoice.invoiceNo}  Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice.date))}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Bill To Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Customer Name: $customerName'),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Items Table
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
              ),
              child: pw.Column(
                children: [
                  // Table Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: PdfColors.grey300,
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 1, child: pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(flex: 4, child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(flex: 1, child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(flex: 1, child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                  ),

                  // Table Rows - With Product, Model, Size, Unit in Description
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    // Build description with all available details
                    final List<String> descriptionParts = [];

                    // Try different possible field names
                    String productName = item['productName'] ??
                        item['productname'] ??
                        item['product_name'] ??
                        '';
                    if (productName.isNotEmpty) {
                      descriptionParts.add(productName);
                    }

                    String modelName = item['modelName'] ??
                        item['modelname'] ??
                        item['model_name'] ??
                        '';
                    if (modelName.isNotEmpty) {
                      descriptionParts.add('Model: $modelName');
                    }

                    String sizeName = item['sizeName'] ??
                        item['sizename'] ??
                        item['size_name'] ??
                        '';
                    if (sizeName.isNotEmpty) {
                      descriptionParts.add('Size: $sizeName');
                    }

                    String unitName = item['unitName'] ??
                        item['unitname'] ??
                        item['unit_name'] ??
                        '';
                    if (unitName.isNotEmpty) {
                      descriptionParts.add('Unit: $unitName');
                    }

                    // If we have a pre-formatted description, use that instead
                    String description = item['formattedDescription'] ?? '';
                    if (description.isEmpty && descriptionParts.isNotEmpty) {
                      description = descriptionParts.join(' | ');
                    } else if (description.isEmpty) {
                      description = productName.isNotEmpty ? productName : 'Item ${index + 1}';
                    }

                    // Get quantity, rate, amount with fallbacks
                    String quantity = item['quantity']?.toString() ??
                        item['qty']?.toString() ??
                        '0';

                    String rate = item['rate']?.toString() ?? '0';
                    String amount = item['amount']?.toString() ?? '0';

                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(flex: 1, child: pw.Text('${index + 1}')),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(
                              description,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Expanded(flex: 1, child: pw.Text(quantity)),
                          pw.Expanded(flex: 1, child: pw.Text('Rs.${double.tryParse(rate)?.toStringAsFixed(2) ?? '0.00'}')),
                          pw.Expanded(flex: 1, child: pw.Text('Rs.${double.tryParse(amount)?.toStringAsFixed(2) ?? '0.00'}')),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Totals Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 300,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfTotalRow('Subtotal:', 'Rs.$subtotal'),
                      pw.SizedBox(height: 4),
                      _buildPdfTotalRow('Tax ($taxPercentage%):', 'Rs.$taxAmount'),
                      pw.Divider(),
                      _buildPdfTotalRow('Total Amount:', 'Rs.$grandTotal', isBold: true),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Footer
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}