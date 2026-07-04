import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/source_followup_report_model.dart';

Future<void> generatePdf(
  List<SourceFollowupReportModel> reportData,
  BuildContext context,
) async {
  if (reportData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No records available to export")),
    );
    return;
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();

  final companyname = prefs.getString('companyname') ?? '';
  // final logourl = prefs.getString('logourl') ?? '';
  final pdf = pw.Document();
  final tamilFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoSansTamil-Regular.ttf"),
  );

  final tamilBold = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoSansTamil-Bold.ttf"),
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),

      build: (context) => [
        pw.SizedBox(height: 20),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              companyname,
              style: pw.TextStyle(fontSize: 18, font: tamilBold),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            'Source Follow up  Report',
            style: pw.TextStyle(fontSize: 18, font: tamilBold),
          ),
        ),

        pw.SizedBox(height: 20),

        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(),
          headerStyle: pw.TextStyle(font: tamilBold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: pw.TextStyle(fontSize: 9, font: tamilFont),
          headers: const [
            'S.No',
            'Source No',
            'Source Name',
            'Mobile',
            'Sales Person',
            'Entry No',
            'Date',
            'Followup Date',
            'Interest',
          ],
          data: List.generate(reportData.length, (index) {
            final item = reportData[index];

            return [
              '${index + 1}',

              item.sourceNo,
              item.sourceName,
              item.mobile,
              item.salesPersonName,
              item.entryNo,
              // DateFormat('dd/MM/yyyy').format(DateTime.parse(item.date)),
              item.date,
              // DateFormat(
              //   'dd/MM/yyyy',
              // ).format(DateTime.parse(item.followupDate)),
              item.followupDate,
              item.interest.interest,
            ];
          }),
        ),
      ],
    ),
  );

  final Uint8List bytes = await pdf.save();

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => bytes,
    name: "Product_Based_Sales_Report_${DateTime.now().millisecondsSinceEpoch}",
  );
}
