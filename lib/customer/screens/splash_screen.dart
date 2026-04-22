import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/theme_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic)),
    );

    _controller.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Elegant dwell time
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final isLoggedIn = _supabaseService.isUserLoggedIn;

    if (mounted) {
      context.go(isLoggedIn ? '/home' : '/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use the theme for the splash background to ensure a smooth transition
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeManager>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Typography Logo
                Text(
                  'MUBASHIR',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'REAL ESTATE',
                  style: TextStyle(
                    color: const Color(0xFFF59E0B), // Brand Gold
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Subtle tag line
                Text(
                  'ELITE SANCTUARY',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF0F172A).withOpacity(0.2),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 48),
                
                // Minimalist Progress
                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: (isDark ? Colors.white : const Color(0xFF0F172A)).withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    minHeight: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
