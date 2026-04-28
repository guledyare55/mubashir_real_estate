import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/localization/language_provider.dart';

enum AuthMode {
  login,
  signup,
  verifySignup,
  forgotPassword,
  verifyRecovery,
  resetPassword,
}

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
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

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
    if (msg.contains('administrative portal'))
      return "Admin detected. Please use the Administrative Portal.";
    if (msg.contains('invalid login credentials'))
      return "Invalid email or password. Please try again.";
    if (msg.contains('user already exists'))
      return "An account with this email already exists.";
    if (msg.contains('invalid token') || msg.contains('otp'))
      return "Invalid verification code. Please check your email.";
    return e
        .toString()
        .replaceAll('Exception:', '')
        .replaceAll('AuthException:', '')
        .trim();
  }

  Future<void> _executeFlow() async {
    if (_mode == AuthMode.login ||
        _mode == AuthMode.signup ||
        _mode == AuthMode.forgotPassword) {
      _targetEmail = _emailCtrl.text.trim();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (_mode) {
        case AuthMode.login:
          await _supabaseService.signInCustomer(
            _targetEmail,
            _passwordCtrl.text,
          );
          TextInput.finishAutofillContext();
          widget.onLoginSuccess();
          break;
        case AuthMode.signup:
          if (_nameCtrl.text.isEmpty)
            throw Exception('Please enter your full name');
          if (_phoneCtrl.text.isEmpty)
            throw Exception('Please enter your phone number');
          if (_passwordCtrl.text != _confirmPasswordCtrl.text)
            throw Exception('Passwords do not match');
          await _supabaseService.signUpCustomer(
            _targetEmail,
            _passwordCtrl.text,
            _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );
          setState(() {
            _mode = AuthMode.verifySignup;
            _errorMessage = null;
          });
          break;
        case AuthMode.verifySignup:
          await _supabaseService.verifyOtp(
            _targetEmail,
            _getOtpValue(),
            type: OtpType.signup,
          );
          widget.onLoginSuccess();
          break;
        case AuthMode.forgotPassword:
          await _supabaseService.sendPasswordResetEmail(_targetEmail);
          setState(() {
            _mode = AuthMode.verifyRecovery;
            _errorMessage = null;
          });
          break;
        case AuthMode.verifyRecovery:
          await _supabaseService.verifyOtp(
            _targetEmail,
            _getOtpValue(),
            type: OtpType.recovery,
          );
          setState(() {
            _mode = AuthMode.resetPassword;
            _errorMessage = null;
          });
          break;
        case AuthMode.resetPassword:
          if (_passwordCtrl.text != _confirmPasswordCtrl.text)
            throw Exception('Passwords do not match');
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
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _buildAura(
              250,
              theme.primaryColor.withOpacity(isDark ? 0.08 : 0.04),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildAura(
              300,
              theme.colorScheme.secondary.withOpacity(isDark ? 0.05 : 0.02),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          lang.setLanguage(lang.isSomali ? 'en' : 'so');
                        },
                        child: Text(
                          lang.isSomali ? 'ENGLISH' : 'SOOMAALI',
                          style: TextStyle(
                            color: theme.colorScheme.secondary.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                        color: theme.colorScheme.secondary.withOpacity(0.3),
                        onPressed: () => themeManager.toggleTheme(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Spacer(flex: 2),
                                  Column(
                                    children: [
                                      Text(
                                        'MUBASHIR',
                                        style: TextStyle(
                                          color: theme.colorScheme.secondary,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 6,
                                        ),
                                      ),
                                      Text(
                                        'REAL ESTATE',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Text(
                                    _getTitle(lang),
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getSubtitle(lang),
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary.withOpacity(0.4),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 40),
                                  
                                  if (_errorMessage != null) ...[
                                    _buildErrorBox(theme),
                                    const SizedBox(height: 20),
                                  ],
                                  
                                  AutofillGroup(
                                    child: Column(
                                      children: _buildFormFields(theme, isDark, lang),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  _buildPrimaryButton(theme, isDark, lang),
                                  
                                  if (_mode == AuthMode.login) ...[
                                    const SizedBox(height: 20),
                                    _buildDivider(theme),
                                    const SizedBox(height: 20),
                                    _buildSocialIcons(theme, isDark),
                                  ],
                                  
                                  const SizedBox(height: 32),
                                  _buildSecondaryActions(theme, lang),
                                  const Spacer(flex: 3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAura(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
    ),
  );

  String _getTitle(LanguageProvider lang) {
    switch (_mode) {
      case AuthMode.login:
        return lang.translate('login_title');
      case AuthMode.signup:
        return lang.translate('signup_title');
      case AuthMode.verifySignup:
      case AuthMode.verifyRecovery:
        return lang.translate('verify_code');
      case AuthMode.forgotPassword:
        return lang.translate('forgot_password');
      case AuthMode.resetPassword:
        return lang.translate('reset_password');
    }
  }

  String _getSubtitle(LanguageProvider lang) {
    switch (_mode) {
      case AuthMode.login:
        return lang.translate('login_subtitle');
      case AuthMode.signup:
        return lang.translate('signup_subtitle');
      case AuthMode.verifySignup:
      case AuthMode.verifyRecovery:
        return "Enter the code sent to your email";
      case AuthMode.forgotPassword:
        return "Enter your email for a recovery code";
      case AuthMode.resetPassword:
        return "Secure your account access";
    }
  }

  List<Widget> _buildFormFields(
    ThemeData theme,
    bool isDark,
    LanguageProvider lang,
  ) {
    switch (_mode) {
      case AuthMode.login:
        return [
          _buildInput(
            theme,
            isDark,
            controller: _emailCtrl,
            label: lang.translate('email_address'),
            icon: Icons.alternate_email,
            autofillHints: [AutofillHints.email],
          ),
          _buildInput(
            theme,
            isDark,
            controller: _passwordCtrl,
            label: lang.translate('password_label'),
            icon: Icons.lock_outline,
            isPassword: true,
            autofillHints: [AutofillHints.password],
          ),
        ];
      case AuthMode.signup:
        return [
          _buildInput(
            theme,
            isDark,
            controller: _nameCtrl,
            label: lang.translate('full_name'),
            icon: Icons.person_outline,
            autofillHints: [AutofillHints.name],
          ),
          _buildInput(
            theme,
            isDark,
            controller: _phoneCtrl,
            label: lang.translate('phone_number'),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: [AutofillHints.telephoneNumber],
          ),
          _buildInput(
            theme,
            isDark,
            controller: _emailCtrl,
            label: lang.translate('email_address'),
            icon: Icons.alternate_email,
            autofillHints: [AutofillHints.email],
          ),
          _buildInput(
            theme,
            isDark,
            controller: _passwordCtrl,
            label: lang.translate('password_label'),
            icon: Icons.lock_outline,
            isPassword: true,
            autofillHints: [AutofillHints.newPassword],
          ),
          _buildInput(
            theme,
            isDark,
            controller: _confirmPasswordCtrl,
            label: lang.translate('confirm_password'),
            icon: Icons.lock_reset,
            isPassword: true,
            autofillHints: [AutofillHints.newPassword],
          ),
        ];
      case AuthMode.verifySignup:
      case AuthMode.verifyRecovery:
        return [_buildOtpInput(theme, isDark)];
      case AuthMode.forgotPassword:
        return [
          _buildInput(
            theme,
            isDark,
            controller: _emailCtrl,
            label: lang.translate('email_address'),
            icon: Icons.alternate_email,
            autofillHints: [AutofillHints.email],
          ),
        ];
      case AuthMode.resetPassword:
        return [
          _buildInput(
            theme,
            isDark,
            controller: _passwordCtrl,
            label: 'New Password',
            icon: Icons.lock_outline,
            isPassword: true,
            autofillHints: [AutofillHints.newPassword],
          ),
          _buildInput(
            theme,
            isDark,
            controller: _confirmPasswordCtrl,
            label: lang.translate('confirm_password'),
            icon: Icons.lock_reset,
            isPassword: true,
            autofillHints: [AutofillHints.newPassword],
          ),
        ];
    }
  }

  Widget _buildOtpInput(ThemeData theme, bool isDark) {
    final fieldColor = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFF1F5F9);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Container(
          width: 45,
          height: 60,
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: theme.primaryColor,
            decoration: InputDecoration(
              counterText: "",
              border: InputBorder.none,
              filled: true,
              fillColor: fieldColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.secondary.withOpacity(0.05),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5)
                _otpFocusNodes[index + 1].requestFocus();
              else if (value.isEmpty && index > 0)
                _otpFocusNodes[index - 1].requestFocus();
              if (_getOtpValue().length == 6) _executeFlow();
            },
          ),
        );
      }),
    );
  }

  Widget _buildInput(
    ThemeData theme,
    bool isDark, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
  }) {
    final fieldColor = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFF1F5F9);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        style: TextStyle(
          color: theme.colorScheme.secondary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: theme.primaryColor,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.colorScheme.secondary.withOpacity(0.4),
            fontSize: 14,
          ),
          floatingLabelStyle: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(
            icon,
            color: theme.colorScheme.secondary.withOpacity(0.2),
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          filled: true,
          fillColor: fieldColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.secondary.withOpacity(0.03),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    ThemeData theme,
    bool isDark,
    LanguageProvider lang,
  ) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _executeFlow,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: isDark ? theme.colorScheme.secondary : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _mode == AuthMode.login
                    ? lang.translate('login_btn')
                    : lang.translate('signup_btn'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcons(ThemeData theme, bool isDark) {
    final fieldColor = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFF1F5F9);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            print('DEBUG: Google Button Tapped in UI');
            setState(() { _isLoading = true; _errorMessage = null; });
            try {
              await _supabaseService.signInWithGoogle();
              widget.onLoginSuccess();
            } catch (e) {
              print('DEBUG: Google Login Catch block: $e');
              setState(() => _errorMessage = _cleanErrorMessage(e));
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: fieldColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.05),
              ),
            ),
            child: Center(
              child: Image.network(
                'https://img.icons8.com/color/48/000000/google-logo.png',
                height: 26,
                errorBuilder: (c, e, s) => Text(
                  'G',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) => Row(
    children: [
      Expanded(
        child: Divider(color: theme.colorScheme.secondary.withOpacity(0.05)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'OR',
          style: TextStyle(
            color: theme.colorScheme.secondary.withOpacity(0.2),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      Expanded(
        child: Divider(color: theme.colorScheme.secondary.withOpacity(0.05)),
      ),
    ],
  );

  Widget _buildSecondaryActions(ThemeData theme, LanguageProvider lang) {
    if (_mode == AuthMode.login) {
      return Column(
        children: [
          TextButton(
            onPressed: () => _switchMode(AuthMode.forgotPassword),
            child: Text(
              lang.translate('forgot_password'),
              style: TextStyle(
                color: theme.colorScheme.secondary.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _switchMode(AuthMode.signup),
            child: RichText(
              text: TextSpan(
                text: lang.translate('no_account'),
                style: TextStyle(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: lang.translate('switch_signup'),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return TextButton(
      onPressed: () => _switchMode(AuthMode.login),
      child: Text(
        lang.translate('switch_login'),
        style: TextStyle(
          color: theme.colorScheme.secondary.withOpacity(0.5),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
