import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class ThemeManager with ChangeNotifier {
  static const String _themeKey = "theme_mode";
  bool _isDarkMode = false;

  ThemeManager() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  // Elite Sanctuary Light Theme - Premium & Airy
  static ThemeData get lightTheme => FlexThemeData.light(
    scheme: FlexScheme.mandyRed,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      inputDecoratorRadius: 16.0,
      inputDecoratorUnfocusedHasBorder: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    primary: const Color(0xFFF59E0B), // Brand Gold
    secondary: const Color(0xFF0F172A), // Deep Navy for Text/Icons
    scaffoldBackground: const Color(0xFFF8FAFC),
  );

  // Elite Sanctuary Dark Theme - High-Contrast & Luxurious
  static ThemeData get darkTheme => FlexThemeData.dark(
    scheme: FlexScheme.mandyRed,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      inputDecoratorRadius: 16.0,
      inputDecoratorUnfocusedHasBorder: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    primary: const Color(0xFFF59E0B), // Brand Gold
    // CRITICAL: In Dark Mode, 'secondary' must be light to remain visible
    secondary: const Color(0xFFF8FAFC), // Off-white for Text/Icons
    scaffoldBackground: const Color(0xFF0F172A), // Deep Midnight Navy
    surface: const Color(0xFF1E293B), // Card/Surface Color
  );
}
