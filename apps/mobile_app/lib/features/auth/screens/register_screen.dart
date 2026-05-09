import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/tokens/app_colors.dart';
import '../widgets/auth_text_field.dart';

const _roles = [
  ('student', 'Student'),
  ('faculty', 'Faculty / Staff'),
  ('technician', 'Technician / Maintenance Worker'),
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _selectedRole = 'student';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
          employeeStudentId: _idCtrl.text.trim(),
          initialRole: _selectedRole,
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
    // GoRouter redirect handles navigation to /pending-approval
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Access'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your account will be reviewed by an administrator before activation.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),

              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'Juan Dela Cruz',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => (v == null || v.length < 3)
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

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
                      controller: _idCtrl,
                      label: 'ID Number',
                      hint: '2024-00001',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'ID number is required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Role selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Role',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(),
                          items: _roles
                              .map((r) => DropdownMenuItem(
                                    value: r.$1,
                                    child: Text(r.$2),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedRole = v ?? 'student'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    AuthTextField(
                      controller: _passCtrl,
                      label: 'Password',
                      hint: 'Min. 8 characters',
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
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Password must be at least 8 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    AuthTextField(
                      controller: _confirmCtrl,
                      label: 'Confirm Password',
                      hint: 'Repeat password',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (v) => v != _passCtrl.text
                          ? "Passwords don't match"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: cs.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16,
                              color: cs.primary.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your account requires admin approval before you can log in.',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.65),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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
                          : const Text('Request Access'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.55),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Sign in',
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
