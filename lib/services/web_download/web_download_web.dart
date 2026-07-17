// Web-only implementation. Only compiled in when targeting web.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileWebImpl(List<int> bytes, String fileName, String contentType) {
  final blob = html.Blob([bytes], contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
