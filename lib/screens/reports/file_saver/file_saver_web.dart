import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Future<void> saveAndOpenExcel(
  List<int> bytes,
  String fileName,
  BuildContext context,
) async {
  try {
    final base64Data = base64Encode(bytes);
    const mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    final anchor = web.HTMLAnchorElement()
      ..href = 'data:$mimeType;base64,$base64Data'
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    web.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Downloaded $fileName")));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save Excel file: $e")));
    }
  }
}
