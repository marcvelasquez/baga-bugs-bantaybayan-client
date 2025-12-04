import 'package:flutter/material.dart';

/// Theme Provider for managing theme (always dark mode)
class ThemeProvider with ChangeNotifier {
  // Always use dark mode
  ThemeMode get themeMode => ThemeMode.dark;
  
  // Always return true for dark mode
  bool get isDarkMode => true;
}
