import 'dart:convert';

import 'package:web/web.dart' as web;

Future<bool> downloadCsv(String filename, String content) async {
  final uri = Uri.dataFromString(
    content,
    mimeType: 'text/csv',
    encoding: utf8,
  );
  web.HTMLAnchorElement()
    ..href = uri.toString()
    ..download = filename
    ..click();
  return true;
}
