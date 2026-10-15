import 'dart:js_interop';

import 'package:web/web.dart';

const _feedbackWebAppUrl =
    'https://script.google.com/macros/s/AKfycbwEa8rXX4CGhaDWz8O2fHMOFsjtZI0hY0--mnu1bphK6fUeJsxaD61USVwRNqWNZgsY/exec';

/// Mirrors the HTML page: POST form body with `mode: 'no-cors'`.
Future<void> submitFeedbackToSheet(String text) async {
  final headers = Headers();
  headers.set('Content-Type', 'application/x-www-form-urlencoded');
  final init = RequestInit(
    method: 'POST',
    mode: 'no-cors',
    headers: headers,
    body: 'feedback=${Uri.encodeComponent(text)}'.toJS,
  );
  await window.fetch(_feedbackWebAppUrl.toJS, init).toDart;
}
