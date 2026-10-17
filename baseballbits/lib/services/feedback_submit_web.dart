import 'dart:js_interop';

import 'package:web/web.dart';

const _feedbackWebAppUrl =
    'https://script.google.com/macros/s/AKfycbwEa8rXX4CGhaDWz8O2fHMOFsjtZI0hY0--mnu1bphK6fUeJsxaD61USVwRNqWNZgsY/exec';

/// Posts feedback so Apps Script receives it as e.parameter.feedback.
///
/// A JSON body never shows up in e.parameter, which is why the sheet row was
/// blank. The query string is included on the POST that doPost actually runs.
Future<void> submitFeedbackToSheet(String text) async {
  final uri = Uri.parse(_feedbackWebAppUrl).replace(
    queryParameters: {'feedback': text},
  );
  final headers = Headers();
  headers.set('Content-Type', 'application/x-www-form-urlencoded');
  final init = RequestInit(
    method: 'POST',
    mode: 'no-cors',
    headers: headers,
    body: 'feedback=${Uri.encodeQueryComponent(text)}'.toJS,
  );
  await window.fetch(uri.toString().toJS, init).toDart;
}
