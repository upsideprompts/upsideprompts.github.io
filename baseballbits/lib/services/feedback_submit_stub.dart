import 'package:http/http.dart' as http;

const _feedbackWebAppUrl =
    'https://script.google.com/macros/s/AKfycbwEa8rXX4CGhaDWz8O2fHMOFsjtZI0hY0--mnu1bphK6fUeJsxaD61USVwRNqWNZgsY/exec';

Future<void> submitFeedbackToSheet(String text) async {
  final uri = Uri.parse(_feedbackWebAppUrl).replace(
    queryParameters: {'feedback': text},
  );
  await http.post(
    uri,
    headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {'feedback': text},
  );
}
