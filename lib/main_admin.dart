import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'package:window_manager/window_manager.dart';
import 'admin/screens/login_screen.dart';
import 'admin/screens/dashboard_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  // Supabase initialization
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Mubashir Admin Portal',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
  });

  runApp(const AdminApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp.router(
          title: 'Admin Platform',
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
              defaultRadius: 12.0,
              elevatedButtonRadius: 12.0,
              outlinedButtonRadius: 12.0,
              inputDecoratorRadius: 8.0, // Tighter corners for admin forms
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
              defaultRadius: 12.0,
              elevatedButtonRadius: 12.0,
              outlinedButtonRadius: 12.0,
              inputDecoratorRadius: 8.0,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            useMaterial3: true,
          ),
          themeMode: currentMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
