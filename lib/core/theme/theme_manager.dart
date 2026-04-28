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
    colors: const FlexSchemeColor(
      primary: Color(0xFFF59E0B), // Brand Gold
      primaryContainer: Color(0xFFD97706),
      secondary: Color(0xFFF8FAFC), // Off-white for Text/Icons
      secondaryContainer: Color(0xFF94A3B8),
      tertiary: Color(0xFF3B82F6),
      tertiaryContainer: Color(0xFF2563EB),
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 0, // CRITICAL: Set to 0 to prevent muddy/brownish blending
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 0,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      inputDecoratorRadius: 16.0,
      inputDecoratorUnfocusedHasBorder: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    scaffoldBackground: const Color(0xFF0F172A), // Deep Midnight Navy
  ).copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardColor: const Color(0xFF1E293B),
    dialogBackgroundColor: const Color(0xFF1E293B),
    canvasColor: const Color(0xFF0F172A),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E293B),
      modalBackgroundColor: Color(0xFF1E293B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      surfaceTintColor: Colors.transparent,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFF8FAFC),
      surface: Color(0xFF1E293B),
      background: Color(0xFF0F172A),
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
  );
}
