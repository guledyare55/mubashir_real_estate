import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'customer/screens/customer_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Mock initialization or real if provided
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const CustomerApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CustomerLayout(),
    ),
  ],
);

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Customer Properties',
      theme: FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: Color(0xFF1E3A8A), // Deep Blue
          primaryContainer: Color(0xFFD0E4FF),
          secondary: Color(0xFFF59E0B), // Gold
          secondaryContainer: Color(0xFFFFDCC0),
          tertiary: Color(0xFF006875),
          tertiaryContainer: Color(0xFF95F0FF),
          appBarColor: Color(0xFFF59E0B),
          error: Color(0xFFB00020),
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          defaultRadius: 16.0,
          elevatedButtonRadius: 16.0,
          outlinedButtonRadius: 16.0,
          inputDecoratorRadius: 12.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xFF1E3A8A), // Deep Blue
          primaryContainer: Color(0xFFD0E4FF),
          secondary: Color(0xFFF59E0B), // Gold
          secondaryContainer: Color(0xFFFFDCC0),
          tertiary: Color(0xFF006875),
          tertiaryContainer: Color(0xFF95F0FF),
          appBarColor: Color(0xFFF59E0B),
          error: Color(0xFFB00020),
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          defaultRadius: 16.0,
          elevatedButtonRadius: 16.0,
          outlinedButtonRadius: 16.0,
          inputDecoratorRadius: 12.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
