import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveInvoiceFileImpl({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final saved = await FilePicker.saveFile(
    dialogTitle: 'Save invoice',
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
  return saved != null;
}
