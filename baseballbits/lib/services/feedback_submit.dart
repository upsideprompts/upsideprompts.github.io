import 'feedback_submit_stub.dart'
    if (dart.library.js_interop) 'feedback_submit_web.dart' as impl;

Future<void> submitFeedbackToSheet(String text) {
  return impl.submitFeedbackToSheet(text);
}
