import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ErrorLogger {
  ErrorLogger._();

  static void log(Object error, [StackTrace? stack, String? context]) {
    final buffer = StringBuffer();
    buffer.writeln('==================== APP ERROR ====================');
    if (context != null) buffer.writeln('context : $context');
    buffer.writeln('error   : $error');
    if (stack != null) {
      buffer.writeln('stack   :');
      buffer.writeln(stack.toString());
    }
    buffer.writeln('===================================================');
    final payload = buffer.toString();

    debugPrint(payload);

    try {
      http
          .post(
            Uri.parse('/api/log'),
            headers: {'Content-Type': 'text/plain'},
            body: payload,
          )
          .catchError((_) => http.Response('', 0));
    } catch (_) {}
  }

  static void installGlobalHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      log(details.exception, details.stack, 'FlutterError');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      log(error, stack, 'Uncaught');
      return true;
    };
  }
}
