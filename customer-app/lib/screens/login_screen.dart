import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  bool _createAccount = false;
  bool _working = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _working = true);
    try {
      if (_createAccount) {
        await AuthService.instance.register(
          name: _name.text.trim(),
          mobile: _mobile.text.trim(),
          password: _password.text,
        );
      } else {
        await AuthService.instance.login(
          mobile: _mobile.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      final raw = error.toString();
      final message = raw.contains('ACCOUNT_EXISTS')
          ? 'An account already exists for this mobile number.'
          : raw.contains('INVALID_LOGIN')
              ? 'Mobile number or password is incorrect.'
              : 'Could not continue. Check your connection and try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 42, 24, 30),
            children: [
              const Center(child: BrandLogo(size: 76)),
              const SizedBox(height: 24),
              Text(
                _createAccount ? 'Create your account' : 'Welcome back',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _createAccount
                    ? 'Sign up once with your mobile number—no OTP needed.'
                    : 'Login with your mobile number and password.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.body, fontSize: 12.5),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_createAccount) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: _dec(
                          'Full Name',
                          Icons.person_outline_rounded,
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 15),
                    ],
                    TextFormField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _dec(
                        'Mobile Number',
                        Icons.phone_outlined,
                        prefix: '+91  ',
                      ),
                      validator: (value) => (value ?? '').length != 10
                          ? 'Enter a valid 10-digit mobile number'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      decoration: _dec(
                        'Password',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.body,
                          ),
                        ),
                      ),
                      validator: (value) => (value ?? '').length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _working ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.brand.withValues(alpha: 0.55),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: _working
                            ? const SizedBox(
                                height: 21,
                                width: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _createAccount ? 'CREATE ACCOUNT' : 'LOGIN',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _createAccount
                        ? 'Already have an account?'
                        : "Don't have an account?",
                    style:
                        const TextStyle(color: AppColors.body, fontSize: 12.5),
                  ),
                  TextButton(
                    onPressed: _working
                        ? null
                        : () => setState(() {
                              _createAccount = !_createAccount;
                              _formKey.currentState?.reset();
                            }),
                    child: Text(_createAccount ? 'Login' : 'Create ID'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _dec(
  String label,
  IconData icon, {
  String? prefix,
}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.brand),
      prefixText: prefix,
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
      ),
    );
