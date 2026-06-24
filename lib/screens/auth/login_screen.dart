import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backend_connection_provider.dart';
import '../../providers/cattle_provider.dart';
import '../../core/utils/helpers.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.read<CattleProvider>().initialize();
      unawaited(context.read<BackendConnectionProvider>().check());

      final l = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
              child: Text(l.welcomeUser(
                  auth.currentUser?.name ?? l.farmer))),
        ]),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
              child: Text(auth.errorMessage ?? context.l10n.loginFailed)),
        ]),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: context.l10n.dismiss,
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.pets, size: 80, color: AppTheme.mutedBlue)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      l.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'IoT-Based Cattle Monitoring System',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: context.secondaryTextColor),
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                    const SizedBox(height: AppTheme.spacingXxl),
                    Container(
                      decoration: AppTheme.glassDecoration(),
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l.login,
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: AppTheme.spacingLg),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: l.email,
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (ValidationUtils.isEmpty(v)) {
                                return 'Email is required';
                              }
                              if (!ValidationUtils.isValidEmail(v!)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l.password,
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => ValidationUtils.isEmpty(v)
                                ? 'Password is required'
                                : null,
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          Consumer<AuthProvider>(
                            builder: (context, auth, child) => ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppTheme.white)))
                                  : Text(l.login),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${l.dontHaveAccount} ',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SignupScreen())),
                                child: Text(l.signUp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: AppTheme.spacingXl),
                    Text(
                      '@Developed by Basit Ali',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
