import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/auth_service.dart';
import 'screens/home_page.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Update system UI overlay based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeProvider.isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: themeProvider.isDarkMode
            ? Colors.black
            : Colors.white,
        systemNavigationBarIconBrightness: themeProvider.isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'BantayBayan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthCheckWidget(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class AuthCheckWidget extends StatelessWidget {
  const AuthCheckWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B6B),
              ),
            ),
          );
        }

        if (authService.isLoggedIn) {
          return const HomePage();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
