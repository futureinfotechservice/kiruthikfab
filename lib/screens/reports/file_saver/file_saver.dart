// Picks the correct implementation at compile time based on platform:
// - dart.library.io is available on Android/iOS/desktop -> file_saver_io.dart
// - dart.library.html is available on web              -> file_saver_web.dart
// - file_saver_stub.dart is the fallback (should never actually be hit)
export 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart';
