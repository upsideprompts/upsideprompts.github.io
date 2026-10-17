import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'models/quotes_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => QuotesProvider(),
      child: const BaseballBitsApp(),
    ),
  );
}

class BaseballBitsApp extends StatelessWidget {
  const BaseballBitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baseball QuoteSmash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3C72),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const _SplashScreen(),
    );
  }
}

/// Full-screen splash, then the quote deck. Same idea as the splashscreen
/// package: show the image, then open the home screen after a few seconds.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7EBFDF),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash/baseball_splash.jpg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
