// Shared helper used by both invoice_share_web.dart and invoice_share_stub.dart.

/// Normalizes a customer mobile number to WhatsApp's expected format:
/// digits only, with country code, no leading zeros/plus/spaces/dashes.
/// Defaults to India (+91) if no country code is present, since 10-digit
/// Indian mobile numbers are the common case here.
String? formatIndianMobile(String? rawNumber) {
  if (rawNumber == null || rawNumber.trim().isEmpty) return null;

  var digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;

  // Strip a leading 0 (common in local-format numbers like 09876543210).
  if (digits.startsWith('0') && digits.length > 10) {
    digits = digits.substring(1);
  }

  // Already has a country code (12 digits starting with 91, e.g. India).
  if (digits.length == 12 && digits.startsWith('91')) {
    return digits;
  }

  // Bare 10-digit number: assume India and prepend the country code.
  if (digits.length == 10) {
    return '91$digits';
  }

  // Anything else (already has some other country code, or malformed) —
  // pass it through as-is and let WhatsApp validate it.
  return digits;
}

/// Standard message body used across platforms.
String buildInvoiceMessage(String invoiceNo) {
  return 'Hi, please find your invoice #$invoiceNo. I am attaching the PDF now.';
}
