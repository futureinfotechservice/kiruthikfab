import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../indigator/main.dart';
import '../../models/invoice_print_helper.dart';
import '../../services/invoice_apiservice.dart';

class InvoicePrintPreview extends StatelessWidget {
  final InvoiceModel invoice;
  final List<Map<String, dynamic>> items;
  final String customerName;
  final String subtotal;
  final String taxAmount;
  final String taxPercentage;
  final String grandTotal;
  final String packingAmount;
  final Company? company;

  const InvoicePrintPreview({
    super.key,
    required this.invoice,
    required this.items,
    required this.customerName,
    required this.subtotal,
    required this.taxAmount,
    required this.taxPercentage,
    required this.grandTotal,
    this.company,
    required this.packingAmount, // Make it optional
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print Invoice - ${invoice.invoiceNo}'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          //   onPressed: () async {
          //     showDialog(
          //       context: context,
          //       barrierDismissible: false,
          //       builder: (context) => const Center(
          //         child: CircularProgressIndicator(),
          //       ),
          //     );
          //
          //     try {
          //       final pdf = await InvoicePrintHelper.generatePDF(
          //         invoice: invoice,
          //         items: items,
          //         customerName: customerName,
          //         subtotal: subtotal,
          //         taxAmount: taxAmount,
          //         taxPercentage: taxPercentage,
          //         grandTotal: grandTotal,
          //         company: company, // Pass company to PDF helper
          //       );
          //
          //       if (context.mounted) {
          //         Navigator.of(context).pop();
          //       }
          //
          //       final bool isWeb = identical(0, 0.0);
          //
          //       if (isWeb) {
          //         await InvoicePrintHelper.downloadPDFWeb(
          //           pdf,
          //           'Invoice_${invoice.invoiceNo}.pdf',
          //         );
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
          //       if (context.mounted) {
          //         Navigator.of(context).pop();
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text('Error: $e'),
          //             backgroundColor: Colors.red,
          //           ),
          //         );
          //       }
          //     }
          //   },
          //   tooltip: 'Download PDF',
          // ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularWaveProgress()),
              );

              try {
                final pdf = await InvoicePrintHelper.generatePDF(
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

                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                // Use Printing.layoutPdf directly for non-web platforms
                // For web, you need to handle download differently
                final bool isWeb = identical(0, 0.0);

                if (isWeb && context.mounted) {
                  await InvoicePrintHelper.printInvoice(
                    context: context,
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
                } else {
                  await Printing.layoutPdf(onLayout: (format) async => pdf);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF generated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Download PDF',
          ),
          // IconButton(
          //   icon: const Icon(Icons.print, color: Colors.white),
          //   onPressed: () async {
          //     showDialog(
          //       context: context,
          //       barrierDismissible: false,
          //       builder: (context) => const Center(
          //         child: CircularProgressIndicator(),
          //       ),
          //     );
          //
          //     try {
          //       await InvoicePrintHelper.printInvoice(
          //         context: context,
          //         invoice: invoice,
          //         items: items,
          //         customerName: customerName,
          //         subtotal: subtotal,
          //         taxAmount: taxAmount,
          //         taxPercentage: taxPercentage,
          //         grandTotal: grandTotal,
          //         company: company, // Pass company to print helper
          //       );
          //
          //       if (context.mounted) {
          //         Navigator.of(context).pop();
          //       }
          //     } catch (e) {
          //       if (context.mounted) {
          //         Navigator.of(context).pop();
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text('Error: $e'),
          //             backgroundColor: Colors.red,
          //           ),
          //         );
          //       }
          //     }
          //   },
          //   tooltip: 'Print',
          // ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 800,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Header Section
                _buildCompanyHeader(),

                const SizedBox(height: 24),

                // Invoice Title
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'TAX INVOICE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bill No: ${invoice.invoiceNo}  |  Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(invoice.date))}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bill To Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill To:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Customer Name: $customerName'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Items Table
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Colors.grey.shade100,
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'S.No',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Description',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Qty',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Rate',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Amount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Rows
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        String description = item['formattedDescription'] ?? '';

                        if (description.isEmpty) {
                          final List<String> parts = [];
                          parts.add(
                            item['productName'] ?? item['productname'] ?? '',
                          );

                          final model =
                              item['modelName'] ?? item['modelname'] ?? '';
                          if (model.isNotEmpty) parts.add('Model: $model');

                          final size =
                              item['sizeName'] ?? item['sizename'] ?? '';
                          if (size.isNotEmpty) parts.add('Size: $size');

                          final unit =
                              item['unitName'] ?? item['unitname'] ?? '';
                          if (unit.isNotEmpty) parts.add('Unit: $unit');

                          description = parts.join(' | ');
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 1, child: Text('${index + 1}')),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  description,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  item['quantity']?.toString() ?? '0',
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Rs.${double.tryParse(item['rate']?.toString() ?? '0')?.toStringAsFixed(2)}',
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Rs.${double.tryParse(item['amount']?.toString() ?? '0')?.toStringAsFixed(2)}',
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Totals Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTotalRow('Subtotal:', 'Rs.$subtotal'),
                          const SizedBox(height: 4),
                          _buildTotalRow(
                            'Packing Amount:',
                            'Rs.$packingAmount',
                          ),
                          const SizedBox(height: 4),
                          _buildTotalRow(
                            'Tax ($taxPercentage%):',
                            'Rs.$taxAmount',
                          ),
                          const Divider(color: Colors.grey),
                          _buildTotalRow(
                            'Total Amount:',
                            'Rs.$grandTotal',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Footer with Authorized Sign
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Logo (if available)
          if (company?.logoUrl != null && company!.logoUrl.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 16),
              child: company!.logoUrl.startsWith('http')
                  ? Image.network(company!.logoUrl, fit: BoxFit.contain)
                  : const Icon(Icons.business, size: 50, color: Colors.grey),
            ),

          // Company Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company?.companyName ?? 'Company Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                if (company?.address != null && company!.address.isNotEmpty)
                  Text(
                    company!.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 4),
                if (company?.contactNo != null && company!.contactNo.isNotEmpty)
                  Text(
                    'Contact: ${company!.contactNo}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (company?.emailId != null && company!.emailId.isNotEmpty)
                  Text(
                    'Email: ${company!.emailId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (company?.gstNo != null && company!.gstNo.isNotEmpty)
                  Text(
                    'GST No: ${company!.gstNo}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '1. Goods once sold will not be taken back\n2. Subject to local jurisdiction',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 200,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black)),
              ),
              child: const Text(
                'Authorized Signatory',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
