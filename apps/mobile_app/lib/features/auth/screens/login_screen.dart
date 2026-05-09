import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/tokens/app_colors.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error.toString()),
          backgroundColor: AppColors.statusRejected,
        ),
      );
    }
    // GoRouter redirect handles navigation
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── Brand ─────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ISUFST',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Management Portal',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to your account',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),

              const SizedBox(height: 28),

              // ── Form ──────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _emailCtrl,
                      label: 'Institutional Email',
                      hint: 'you@isufst.edu.ph',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w-.]+@[\w-]+\.[\w-.]+$').hasMatch(v)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _passCtrl,
                      label: 'Password',
                      hint: '••••••••',
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.neutral400,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sign In button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Register link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.55),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        'Request access',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
