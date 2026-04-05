import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  String? _errorMessage;

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.signInAdmin(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) {
        GoRouter.of(context).go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side: Image/Branding (Hidden on smaller screens)
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=2070&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1E3A8A).withOpacity(0.9), const Color(0xFF1E3A8A).withOpacity(0.4)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'Mubashir\nReal Estate.',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.05,
                            letterSpacing: -1.5,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Admin Portal & Property Management System',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Right side: Login Form
          Expanded(
            flex: 4,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo for mobile view
                        if (MediaQuery.of(context).size.width <= 800)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 48),
                            child: Icon(Icons.real_estate_agent, size: 64, color: Color(0xFF1E3A8A)),
                          ),
                        
                        const Text(
                          'Welcome back',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please enter your credentials to access the dashboard.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 48),
                        
                        // Email Input
                        const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            hintText: 'admin@mubashir.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade100 : Colors.grey.shade900,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Password Input
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade100 : Colors.grey.shade900,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A)),
                            child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          ),
                          
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A), // Deep Blue
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
