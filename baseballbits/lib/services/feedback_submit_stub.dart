import 'package:http/http.dart' as http;

const _feedbackWebAppUrl =
    'https://script.google.com/macros/s/AKfycbwEa8rXX4CGhaDWz8O2fHMOFsjtZI0hY0--mnu1bphK6fUeJsxaD61USVwRNqWNZgsY/exec';

Future<void> submitFeedbackToSheet(String text) async {
  await http.post(
    Uri.parse(_feedbackWebAppUrl),
    headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
    body: 'feedback=${Uri.encodeComponent(text)}',
  );
}
