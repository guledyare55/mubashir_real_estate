import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'customer/screens/customer_layout.dart';
import 'customer/screens/splash_screen.dart';
import 'customer/screens/modern_auth_screen.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize Firebase (Safely)
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Firebase initialization skipped or failed: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const CustomerApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => SplashScreen()),
    GoRoute(path: '/home', builder: (context, state) => CustomerLayout()),
    GoRoute(
      path: '/auth',
      builder: (context, state) =>
          ModernAuthScreen(onLoginSuccess: () => context.go('/home')),
    ),
  ],
);

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp.router(
      title: 'Mubashir Real Estate',
      theme: ThemeManager.lightTheme,
      darkTheme: ThemeManager.darkTheme,
      themeMode: themeManager.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
