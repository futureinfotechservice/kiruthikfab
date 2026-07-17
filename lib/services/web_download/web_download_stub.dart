// Stub implementation used on all non-web platforms (Android, iOS, Windows, etc.)
// This file must NOT import dart:html.

void downloadFileWebImpl(List<int> bytes, String fileName, String contentType) {
  // No-op: this code path is only ever reached when kIsWeb is true,
  // so on non-web platforms this stub is never actually called.
}
