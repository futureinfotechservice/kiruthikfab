import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../services/invoice_apiservice.dart';
import '../screens/entry/invoice_print_helper/invoice_print_helper.dart'
    as invoice_print_helper;

class InvoicePrintHelper {
  static Future<void> printInvoice({
    required BuildContext context,
    required InvoiceModel invoice,
    required List<Map<String, dynamic>> items,
    required String customerName,
    required String subtotal,
    required String taxAmount,
    required String taxPercentage,
    required String grandTotal,
    required String packingAmount,
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
        packingAmount: packingAmount,
      );

      if (kIsWeb) {
        // Use the web-specific implementation
        await invoice_print_helper.InvoicePrintHelper.downloadPDF(
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
        // For Android and other non-web platforms
        await Printing.layoutPdf(onLayout: (format) async => pdf);
      }
    } catch (e) {
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
    required String packingAmount,
    Company? company,
  }) async {
    final pdf = pw.Document();
    final tamilFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSansTamil-Regular.ttf"),
    );

    final tamilBold = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSansTamil-Bold.ttf"),
    );
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: tamilFont, bold: tamilBold),

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
            packingAmount: packingAmount,
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
    required String packingAmount,
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
    pw.Widget term(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '• ',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.Expanded(
              child: pw.Text(
                text,
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.grey700,
                  lineSpacing: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Company Name
            pw.Text(
              getStringValue(
                company?.companyName,
                defaultValue: 'COMPANY NAME',
              ).toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),

            pw.SizedBox(height: 6),

            // Address
            if (company?.address.isNotEmpty ?? false)
              pw.Text(
                company!.address,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),

            pw.SizedBox(height: 6),

            // Contact Information
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (company!.contactNo.isNotEmpty)
                  pw.Text(
                    'Contact No: ${company.contactNo}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),

                pw.SizedBox(width: 15),

                if (company.showEmailId.isNotEmpty)
                  pw.Text(
                    'Email: ${company.showEmailId}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),

                pw.SizedBox(width: 15),

                if (company.website.isNotEmpty)
                  pw.Text(
                    'Website: ${company.website}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
            if (company.gstNo.isNotEmpty && company.gstNo != '0') ...[
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'GSTIN : ${company.gstNo}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
            ],
          ],
        ),

        pw.SizedBox(height: 8),

        // Invoice Title
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

        // Bill Information - UPDATED with Full Customer Details
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Left column - Invoice Details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Invoice No:', invoice.invoiceNo),
                  pw.SizedBox(height: 4),
                  _buildInfoRow(
                    'Invoice Date:',
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(invoice.date)),
                  ),
                  pw.SizedBox(height: 4),
                  if (invoice.customerPhone.isNotEmpty)
                    pw.Text(
                      'Phone: ${invoice.customerPhone}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                ],
              ),

              // Right column - Customer Details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Bill To:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          invoice.customerName,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ],
                    ),

                    if (invoice.customerAddress.isNotEmpty)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          invoice.customerAddress,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    if (invoice.customerArea.isNotEmpty)
                      pw.Text(
                        invoice.customerArea,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    if (invoice.customerGstNo.isNotEmpty)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                          'GSTIN/UIN: ${invoice.customerGstNo}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.normal,
                            color: PdfColors.blue800,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // Items Table Header
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
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Product',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Model',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Size',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Unit',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Qty',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Rate',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Amount',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Items List
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          // Get product details from different possible field names
          String productName = item['productName'] ?? item['productname'] ?? '';
          String modelName = item['modelName'] ?? item['modelname'] ?? '';
          String sizeName = item['sizeName'] ?? item['sizename'] ?? '';
          String unitName = item['unitName'] ?? item['unitname'] ?? '';

          double quantity =
              double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
          double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
          double amount =
              double.tryParse(item['amount']?.toString() ?? '0') ?? 0;

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
                    rate.toStringAsFixed(2),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    amount.toStringAsFixed(2),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          );
        }),

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
              pw.SizedBox(height: 2),
              _buildTotalRow(
                'Packing Amount:',
                'Rs. $packingAmount.00',
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
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.normal,
                            fontSize: 9,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Rs. ${taxAmountValue.toStringAsFixed(2)}',
                          style: pw.TextStyle(
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
                          'CGST (${(taxRateValue / 2).toStringAsFixed(2)}%):',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Rs. ${(taxAmountValue / 2).toStringAsFixed(2)}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'SGST (${(taxRateValue / 2).toStringAsFixed(2)}%):',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Rs. ${(taxAmountValue / 2).toStringAsFixed(2)}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
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
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  _convertToWords(grandTotalValue),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                  ),
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
                // pw.Text('📝 ', style: const pw.TextStyle(fontSize: 9)),
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
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Container(width: 150, height: 0.5, color: PdfColors.grey400),
              ],
            ),

            // Right side - Authorized Signature
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Authorized Signatory',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(width: 180, height: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 2),
                pw.Text(
                  '(Authorized Person)',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        // Footer
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Terms & Conditions',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Divider(color: PdfColors.grey400),

              term(
                'Damaged, defective, or incorrect products must be reported within 48 hours of delivery along with clear photographs and order details.',
              ),

              term(
                'Exchanges can be requested within 5 days from the date of delivery.',
              ),

              term(
                'Products must be unused, unwashed, and in their original condition with all tags intact.',
              ),

              term(
                'Items must be returned with their original packaging and all accessories.',
              ),

              // _term(
              //   'Products are not refundable. Only exchanges are permitted, subject to approval.',
              // ),
              term(
                'Return shipping charges must be borne by the customer unless the error is from our side.',
              ),

              term(
                'Items that are stained, damaged, altered, washed, or show signs of use will not be accepted.',
              ),

              term(
                'Orders will be processed and dispatched only after full payment has been received.',
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'This is a computer generated invoice',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
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
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          value.isNotEmpty ? value : '-',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
  }) {
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
    String result = '$rupeesWord Rupees';

    if (paise > 0) {
      result += ' and ${_numberToWords(paise)} Paise';
    }

    return '$result Only';
  }

  static String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    const units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];

    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (number < 20) return units[number];
    if (number < 100) {
      return tens[number ~/ 10] +
          (number % 10 != 0 ? ' ${units[number % 10]}' : '');
    }
    if (number < 1000) {
      return '${units[number ~/ 100]} Hundred${number % 100 != 0 ? ' ${_numberToWords(number % 100)}' : ''}';
    }
    if (number < 100000) {
      return '${_numberToWords(number ~/ 1000)} Thousand${number % 1000 != 0 ? ' ${_numberToWords(number % 1000)}' : ''}';
    }
    if (number < 10000000) {
      return '${_numberToWords(number ~/ 100000)} Lakh${number % 100000 != 0 ? ' ${_numberToWords(number % 100000)}' : ''}';
    }
    return '${_numberToWords(number ~/ 10000000)} Crore${number % 10000000 != 0 ? ' ${_numberToWords(number % 10000000)}' : ''}';
  }
}
