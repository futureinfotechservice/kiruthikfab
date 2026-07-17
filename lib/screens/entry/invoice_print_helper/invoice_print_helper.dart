// Main entry point - conditional export based on platform
export 'invoice_print_helper_io.dart'
    if (dart.library.html) 'invoice_print_helper_web.dart';
