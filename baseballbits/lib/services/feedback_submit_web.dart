import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart';

const _feedbackWebAppUrl =
    'https://script.google.com/macros/s/AKfycbwEa8rXX4CGhaDWz8O2fHMOFsjtZI0hY0--mnu1bphK6fUeJsxaD61USVwRNqWNZgsY/exec';

/// Posts feedback to the Google Apps Script web app.
///
/// Uses `text/plain` JSON (no CORS preflight). Apps Script still redirects the
/// response, so we also send a `no-cors` form POST as a fallback matching the
/// original HTML sample (`feedback=...`).
Future<void> submitFeedbackToSheet(String text) async {
  final payload = jsonEncode({'feedback': text});

  // Preferred: JSON body for doPost(e) → JSON.parse(e.postData.contents)
  try {
    final headers = Headers();
    headers.set('Content-Type', 'text/plain;charset=utf-8');
    final init = RequestInit(
      method: 'POST',
      mode: 'cors',
      headers: headers,
      body: payload.toJS,
    );
    await window.fetch(_feedbackWebAppUrl.toJS, init).toDart;
    return;
  } catch (_) {
    // GAS redirects to googleusercontent; browsers often throw a CORS error
    // even when doPost already ran. Fall through to the HTML-style post.
  }

  // Fallback: same as the HTML page (e.parameter.feedback)
  final formHeaders = Headers();
  formHeaders.set('Content-Type', 'application/x-www-form-urlencoded');
  final formInit = RequestInit(
    method: 'POST',
    mode: 'no-cors',
    headers: formHeaders,
    body: 'feedback=${Uri.encodeComponent(text)}'.toJS,
  );
  await window.fetch(_feedbackWebAppUrl.toJS, formInit).toDart;
}
