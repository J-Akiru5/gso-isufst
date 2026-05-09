import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/tokens/app_colors.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.statusPending.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_outlined,
                  size: 44,
                  color: AppColors.statusPending,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Account Pending Approval',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your registration has been received. An administrator will review and activate your account shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Steps
              _StepItem(
                icon: Icons.check_circle_outline,
                color: AppColors.statusCompleted,
                title: 'Registration Submitted',
                subtitle: 'Your details have been recorded',
              ),
              const SizedBox(height: 12),
              _StepItem(
                icon: Icons.pending_outlined,
                color: AppColors.statusPending,
                title: 'Admin Review',
                subtitle: 'Usually within 1 business day',
              ),
              const SizedBox(height: 12),
              _StepItem(
                icon: Icons.notifications_outlined,
                color: AppColors.primary,
                title: 'Account Activated',
                subtitle: "You'll receive a notification when approved",
              ),

              const SizedBox(height: 40),

              Text(
                'For urgent access, contact the GSO Office.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StepItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
