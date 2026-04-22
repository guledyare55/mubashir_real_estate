import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/theme_manager.dart';

enum AuthMode { login, signup, verifySignup, forgotPassword, verifyRecovery, resetPassword }

class ModernAuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const ModernAuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<ModernAuthScreen> createState() => _ModernAuthScreenState();
}

class _ModernAuthScreenState extends State<ModernAuthScreen> {
  final _supabaseService = SupabaseService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());
  
  AuthMode _mode = AuthMode.login;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _targetEmail = "";

  void _switchMode(AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _errorMessage = null;
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      for (var c in _otpControllers) c.clear();
    });
  }

  String _getOtpValue() => _otpControllers.map((c) => c.text).join();

  String _cleanErrorMessage(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('administrative portal')) return "Admin detected. Please use the Administrative Portal.";
    if (msg.contains('invalid login credentials')) return "Invalid email or password. Please try again.";
    if (msg.contains('user already exists')) return "An account with this email already exists.";
    if (msg.contains('invalid token') || msg.contains('otp')) return "Invalid verification code. Please check your email.";
    return e.toString().replaceAll('Exception:', '').replaceAll('AuthException:', '').trim();
  }

  Future<void> _executeFlow() async {
    if (_mode == AuthMode.login || _mode == AuthMode.signup || _mode == AuthMode.forgotPassword) {
      _targetEmail = _emailCtrl.text.trim();
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      switch (_mode) {
        case AuthMode.login:
          await _supabaseService.signInCustomer(_targetEmail, _passwordCtrl.text);
          widget.onLoginSuccess();
          break;
        case AuthMode.signup:
          if (_nameCtrl.text.isEmpty) throw Exception('Please enter your full name');
          if (_passwordCtrl.text != _confirmPasswordCtrl.text) throw Exception('Passwords do not match');
          await _supabaseService.signUpCustomer(_targetEmail, _passwordCtrl.text, _nameCtrl.text.trim());
          setState(() { _mode = AuthMode.verifySignup; _errorMessage = null; });
          break;
        case AuthMode.verifySignup:
          await _supabaseService.verifyOtp(_targetEmail, _getOtpValue(), type: OtpType.signup);
          widget.onLoginSuccess();
          break;
        case AuthMode.forgotPassword:
          await _supabaseService.sendPasswordResetEmail(_targetEmail);
          setState(() { _mode = AuthMode.verifyRecovery; _errorMessage = null; });
          break;
        case AuthMode.verifyRecovery:
          await _supabaseService.verifyOtp(_targetEmail, _getOtpValue(), type: OtpType.recovery);
          setState(() { _mode = AuthMode.resetPassword; _errorMessage = null; });
          break;
        case AuthMode.resetPassword:
          if (_passwordCtrl.text != _confirmPasswordCtrl.text) throw Exception('Passwords do not match');
          await _supabaseService.updatePassword(_passwordCtrl.text);
          _switchMode(AuthMode.login);
          break;
      }
    } catch (e) {
      setState(() => _errorMessage = _cleanErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Optimized High-Performance Backgrounds
          Positioned(top: -50, right: -50, child: _buildAura(250, theme.primaryColor.withOpacity(isDark ? 0.08 : 0.04))),
          Positioned(bottom: -100, left: -100, child: _buildAura(300, theme.colorScheme.secondary.withOpacity(isDark ? 0.05 : 0.02))),

          SafeArea(
            child: Column(
              children: [
                // Top Action Row (Theme Toggle) - Minimal padding to reduce layout shift
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                        color: theme.colorScheme.secondary.withOpacity(0.3),
                        onPressed: () => themeManager.toggleTheme(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dynamic Header
                        Column(
                          children: [
                            Text('MUBASHIR', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4)),
                            Text('REAL ESTATE', style: TextStyle(color: theme.primaryColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        Text(_getTitle(), style: TextStyle(color: theme.colorScheme.secondary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        Text(_getSubtitle(), textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.5), fontSize: 13)),
                        const SizedBox(height: 20),

                        // Adaptive Auth Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: isDark ? theme.cardColor.withOpacity(0.8) : Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 30, offset: const Offset(0, 10)),
                            ],
                            border: Border.all(color: theme.colorScheme.secondary.withOpacity(isDark ? 0.03 : 0.01)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ..._buildFormFields(theme, isDark),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _buildErrorBox(theme),
                              ],
                              const SizedBox(height: 20),
                              _buildPrimaryButton(theme, isDark),
                              
                              if (_mode == AuthMode.login) ...[
                                const SizedBox(height: 16),
                                _buildDivider(theme),
                                const SizedBox(height: 16),
                                _buildSocialIcons(theme, isDark),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSecondaryActions(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAura(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  String _getTitle() {
    switch (_mode) {
      case AuthMode.login: return "Welcome Back";
      case AuthMode.signup: return "Join the Elite";
      case AuthMode.verifySignup:
      case AuthMode.verifyRecovery: return "Verify Account";
      case AuthMode.forgotPassword: return "Recovery";
      case AuthMode.resetPassword: return "New Password";
    }
  }

  String _getSubtitle() {
    switch (_mode) {
      case AuthMode.login: return "Sign in to access your portfolio";
      case AuthMode.signup: return "Start your luxury journey today";
      case AuthMode.verifySignup:
      case AuthMode.verifyRecovery: return "Enter the code sent to your email";
      case AuthMode.forgotPassword: return "Enter your email for a recovery code";
      case AuthMode.resetPassword: return "Secure your account access";
    }
  }

  List<Widget> _buildFormFields(ThemeData theme, bool isDark) {
    switch (_mode) {
      case AuthMode.login:
        return [
          _buildInput(theme, isDark, controller: _emailCtrl, label: 'Email Address', icon: Icons.alternate_email),
          _buildInput(theme, isDark, controller: _passwordCtrl, label: 'Password', icon: Icons.lock_outline, isPassword: true),
        ];
      case AuthMode.signup:
        return [
          _buildInput(theme, isDark, controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline),
          _buildInput(theme, isDark, controller: _emailCtrl, label: 'Email Address', icon: Icons.alternate_email),
          _buildInput(theme, isDark, controller: _passwordCtrl, label: 'Password', icon: Icons.lock_outline, isPassword: true),
          _buildInput(theme, isDark, controller: _confirmPasswordCtrl, label: 'Confirm Password', icon: Icons.lock_reset, isPassword: true),
        ];
      case AuthMode.verifySignup:
      case AuthMode.verifyRecovery:
        return [_buildOtpInput(theme, isDark)];
      case AuthMode.forgotPassword:
        return [_buildInput(theme, isDark, controller: _emailCtrl, label: 'Email Address', icon: Icons.alternate_email)];
      case AuthMode.resetPassword:
        return [
          _buildInput(theme, isDark, controller: _passwordCtrl, label: 'New Password', icon: Icons.lock_outline, isPassword: true),
          _buildInput(theme, isDark, controller: _confirmPasswordCtrl, label: 'Confirm Password', icon: Icons.lock_reset, isPassword: true),
        ];
    }
  }

  Widget _buildOtpInput(ThemeData theme, bool isDark) {
    final fieldColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Container(
          width: 45, height: 60,
          decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: _otpControllers[index], focusNode: _otpFocusNodes[index],
            textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
            style: TextStyle(color: theme.colorScheme.secondary, fontSize: 24, fontWeight: FontWeight.bold),
            cursorColor: theme.primaryColor,
            decoration: InputDecoration(
              counterText: "", border: InputBorder.none, filled: true, fillColor: fieldColor,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.05))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 2)),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) _otpFocusNodes[index + 1].requestFocus();
              else if (value.isEmpty && index > 0) _otpFocusNodes[index - 1].requestFocus();
              if (_getOtpValue().length == 6) _executeFlow();
            },
          ),
        );
      }),
    );
  }

  Widget _buildInput(ThemeData theme, bool isDark, {required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, TextInputType? keyboardType}) {
    final fieldColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller, obscureText: isPassword && _obscurePassword, keyboardType: keyboardType,
        style: TextStyle(color: theme.colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.w600),
        cursorColor: theme.primaryColor,
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.4), fontSize: 14),
          floatingLabelStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: theme.colorScheme.secondary.withOpacity(0.2), size: 22),
          suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: theme.colorScheme.secondary.withOpacity(0.2), size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
          filled: true, fillColor: fieldColor,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.03))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _executeFlow,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor, foregroundColor: isDark ? theme.colorScheme.secondary : Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text("CONTINUE", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildErrorBox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.1))),
      child: Row(children: [const Icon(Icons.error_outline, color: Colors.red, size: 20), const SizedBox(width: 12), Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)))]),
    );
  }

  Widget _buildSocialIcons(ThemeData theme, bool isDark) {
    final fieldColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In configuration required.'))),
          child: Container(
            height: 56, width: 56, decoration: BoxDecoration(color: fieldColor, shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.05))),
            child: Center(child: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png', height: 26, errorBuilder: (c, e, s) => Text('G', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)))),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) => Row(children: [Expanded(child: Divider(color: theme.colorScheme.secondary.withOpacity(0.05))), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('OR', style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.2), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2))), Expanded(child: Divider(color: theme.colorScheme.secondary.withOpacity(0.05)))]);

  Widget _buildSecondaryActions(ThemeData theme) {
    if (_mode == AuthMode.login) {
      return Column(children: [
        TextButton(onPressed: () => _switchMode(AuthMode.forgotPassword), child: Text('Forgot Password?', style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.5), fontSize: 13))),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _switchMode(AuthMode.signup),
          child: RichText(text: TextSpan(text: "Don't have an account? ", style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.3), fontSize: 13), children: [TextSpan(text: "Join Now", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900))])),
        ),
      ]);
    }
    return TextButton(onPressed: () => _switchMode(AuthMode.login), child: Text('Back to Login', style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.bold)));
  }
}
