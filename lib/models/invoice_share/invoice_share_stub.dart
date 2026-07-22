import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/invoice_apiservice.dart';
import 'invoice_share_common.dart';

const _whatsappChannel = MethodChannel('kiruthikfab/whatsapp_share');

Future<void> shareOnWeb(
  BuildContext context,
  Uint8List pdf,
  InvoiceModel invoice,
) async {
  final phone = formatIndianMobile(invoice.customerPhone);

  if (phone == null) {
    _showError(context, 'Customer mobile number is missing or invalid.');
    return;
  }

  try {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    // Save PDF to temporary directory
    final filePath = await _savePdfLocally(pdf, invoice);
    final message = buildInvoiceMessage(invoice.invoiceNo);

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    // Android: Use native channel to share with WhatsApp
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _whatsappChannel.invokeMethod('shareToWhatsApp', {
          'filePath': filePath,
          'message': message,
          'phone': phone,
        });

        if (result == "FILE_ATTACHED") {
          // Success - file is attached in WhatsApp
          if (context.mounted) {
            _showWhatsAppInstructions(context, invoice, phone);
          }
        }
        return;
      } on PlatformException catch (e) {
        debugPrint(
          'shareToWhatsApp failed: code=${e.code} message=${e.message}',
        );
        if (e.code == 'NOT_INSTALLED') {
          if (context.mounted) {
            _showError(context, 'WhatsApp is not installed on this device.');
          }
          return;
        }
        // Fall through to web-based approach
      } catch (e) {
        debugPrint('shareToWhatsApp unexpected error: $e');
      }
    }

    // iOS / Windows / Web: Use URL launcher
    await _openWhatsAppChat(phone, message);
    if (context.mounted) {
      _showAttachInstructions(context, invoice, filePath);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading if still open
      _showError(context, 'Error sharing: $e');
    }
  }
}

// New method: Show instructions specifically for Android
void _showWhatsAppInstructions(
  BuildContext context,
  InvoiceModel invoice,
  String phone,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('📎 PDF Ready!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice #${invoice.invoiceNo} has been attached to WhatsApp.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Now in WhatsApp:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('1. Select the contact "${invoice.customerName}"'),
          const Text('2. Tap the Send button'),
          const SizedBox(height: 12),
          Text('Contact: $phone', style: const TextStyle(color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}

Future<void> _openWhatsAppChat(String phone, String message) async {
  final url =
      'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}';
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Future<String> _savePdfLocally(Uint8List pdf, InvoiceModel invoice) async {
  final dir = await getTemporaryDirectory();
  final filePath =
      '${dir.path}${Platform.pathSeparator}Invoice_${invoice.invoiceNo}.pdf';
  final file = File(filePath);
  await file.writeAsBytes(pdf, flush: true);
  return filePath;
}

void _showAttachInstructions(
  BuildContext context,
  InvoiceModel invoice,
  String filePath,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('One more step'),
      content: Text(
        'WhatsApp is open with the chat ready.\n\n'
        'Invoice_${invoice.invoiceNo}.pdf has been saved — '
        'tap the 📎 attachment icon in WhatsApp, choose "Document", '
        'select that file, and press Send.',
      ),
      actions: [
        TextButton(
          onPressed: () => OpenFilex.open(filePath),
          child: const Text('Open PDF'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

void _showError(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
}

// Talks to native Android code (see MainActivity.kt) that launches WhatsApp
// specifically via an explicit Intent, with the PDF and message pre-loaded.
// Used on Android, iOS, and Windows (everything except web).
//
// IMPORTANT: no platform lets an outside app pick a WhatsApp contact for
// the user — that choice always happens inside WhatsApp itself.
//   - Android: an explicit Intent targeted at WhatsApp's package
//     (com.whatsapp) opens WhatsApp directly — skipping the generic share
//     sheet — with the PDF and message already loaded. The user picks the
//     contact/chat inside WhatsApp and taps Send.
//   - iOS: Apple's share sheet has no way to target one specific app, and
//     WhatsApp exposes no API for this on iOS. Falls back to opening the
//     chat with prefilled text; the file is attached manually.
//   - Windows: WhatsApp Desktop doesn't participate in any OS share
//     contract either, so it uses the same manual-attach fallback.
// if (defaultTargetPlatform == TargetPlatform.android) {
//   try {
//     await _whatsappChannel.invokeMethod('shareToWhatsApp', {
//       'filePath': filePath,
//       'message': message,
//       'phone': phone,
//     });
//     return; // WhatsApp opened directly with file + message pre-loaded.
//   } on PlatformException catch (e) {
//     debugPrint(
//       'shareToWhatsApp failed: code=${e.code} message=${e.message} details=${e.details}',
//     );
//     if (e.code == 'NOT_INSTALLED') {
//       _showError(context, 'WhatsApp is not installed on this device.');
//       return;
//     }
//     // Any other native failure: fall through to the manual-attach flow.
//   } catch (e) {
//     debugPrint('shareToWhatsApp unexpected error: $e');
//   }
// }
// In your Dart code, handle the "OPENED_CHAT" response
