import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadFileWebImpl(List<int> bytes, String fileName, String contentType) {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: contentType),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;

  anchor.click();

  web.URL.revokeObjectURL(url);
}
