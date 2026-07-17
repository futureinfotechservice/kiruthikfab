// Conditional export: picks the web implementation only when dart:html
// is available (i.e. when compiling for web), otherwise falls back to
// the stub. This is the correct direction for conditional imports/exports —
// the default (first) URI is the one used unless a condition matches.
export 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';
