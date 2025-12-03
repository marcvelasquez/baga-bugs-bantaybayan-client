import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
      home: const HomePage(),
    );
  }
}
