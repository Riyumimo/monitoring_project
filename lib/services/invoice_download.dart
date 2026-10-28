import 'dart:typed_data';

import 'invoice_download_io.dart'
    if (dart.library.js_interop) 'invoice_download_web.dart';

/// Saves an invoice PDF using the platform's normal download flow.
///
/// Returns `true` when the download was started (or the file was saved), and
/// `false` when the user cancelled the save dialog.
Future<bool> saveInvoiceFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  return saveInvoiceFileImpl(
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
}
