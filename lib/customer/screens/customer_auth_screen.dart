import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

class CustomerAuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const CustomerAuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<CustomerAuthScreen> createState() => _CustomerAuthScreenState();
}

class _CustomerAuthScreenState extends State<CustomerAuthScreen> {
  final _supabaseService = SupabaseService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  void _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        if (_nameCtrl.text.isEmpty) throw Exception('Please enter your full name');
        await _supabaseService.signUpCustomer(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
      } else {
        await _supabaseService.signInCustomer(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      }
      
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('Exception:') 
            ? e.toString().split('Exception: ').last 
            : e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Welcome Back', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.home_work_rounded, size: 64, color: Color(0xFF1E3A8A)),
            const SizedBox(height: 24),
            Text(
              _isSignUp ? 'Join to save properties & track inquiries.' : 'Sign in to access your saved properties.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 40),

            if (_isSignUp) ...[
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
              )
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isSignUp ? 'Sign Up' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            
            TextButton(
              onPressed: () => setState(() { _isSignUp = !_isSignUp; _errorMessage = null; }),
              child: Text(
                _isSignUp ? 'Already have an account? Log In' : 'New here? Create an Account',
                style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
      ),
    );
  }
}
