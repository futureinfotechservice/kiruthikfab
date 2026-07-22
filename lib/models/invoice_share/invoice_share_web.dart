import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

import '../../services/invoice_apiservice.dart';
import 'invoice_share_common.dart';

// Web sharing function: opens the customer's WhatsApp / WhatsApp Web chat
// with a prefilled message, and downloads the PDF so the user can attach it
// and hit Send themselves.
//
// IMPORTANT: WhatsApp does not expose any API (web or otherwise) that lets
// third-party code attach a file to a chat automatically. This is a hard
// platform restriction, not a bug — the attach step below is always manual.
Future<void> shareOnWeb(
  BuildContext context,
  Uint8List pdf,
  InvoiceModel invoice,
) async {
  print('going');
  final phone = formatIndianMobile(invoice.customerPhone);

  if (phone == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer mobile number is missing or invalid.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  try {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    // 1. Download the PDF so it's ready to attach.
    await _downloadPDFForWeb(pdf, invoice);

    // 2. Open the customer's chat on WhatsApp (app) / WhatsApp Web (desktop)
    // with a prefilled text message. api.whatsapp.com/send is WhatsApp's
    // own documented endpoint and works on both platforms.
    final message = Uri.encodeComponent(buildInvoiceMessage(invoice.invoiceNo));
    final whatsappUrl =
        'https://api.whatsapp.com/send?phone=$phone&text=$message';

    await launchUrl(
      Uri.parse(whatsappUrl),
      mode: LaunchMode.externalApplication,
    );

    if (context.mounted) {
      Navigator.pop(context); // close loading
      _showAttachInstructions(context, invoice);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // close loading if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Shows a short, dismissible dialog reminding the user to attach the
// already-downloaded PDF and press Send inside WhatsApp — since that step
// can't be automated.
void _showAttachInstructions(BuildContext context, InvoiceModel invoice) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('One more step'),
      content: Text(
        'WhatsApp is open with the chat ready.\n\n'
        'Invoice_${invoice.invoiceNo}.pdf has been downloaded — '
        'tap the 📎 attachment icon in WhatsApp, choose "Document", '
        'select that file, and press Send.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

// Download PDF for web
Future<void> _downloadPDFForWeb(Uint8List pdf, InvoiceModel invoice) async {
  try {
    // file_saver 0.4.x: parameter is `fileExtension`, not `ext`.
    // name already carries ".pdf", so includeExtension:false avoids
    // ending up with "Invoice_1.pdf.pdf".
    await FileSaver.instance.saveFile(
      name: 'Invoice_${invoice.invoiceNo}.pdf',
      bytes: pdf,
      fileExtension: 'pdf',
      includeExtension: false,
      mimeType: MimeType.pdf,
    );
  } catch (e) {
    // Fallback to a manual anchor-click download using package:web
    // (the modern replacement for dart:html's AnchorElement).
    final base64 = base64Encode(pdf);
    final pdfDataUri = 'data:application/pdf;base64,$base64';
    final anchor = web.HTMLAnchorElement()
      ..href = pdfDataUri
      ..download = 'Invoice_${invoice.invoiceNo}.pdf';
    anchor.click();
    anchor.remove();
  }
}
