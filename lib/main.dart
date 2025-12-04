import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/home_page.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables first
  await dotenv.load(fileName: '.env');

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const BantayBayanApp(),
    ),
  );
}

class BantayBayanApp extends StatelessWidget {
  const BantayBayanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Force dark mode system UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1a1621),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'BantayBayan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
