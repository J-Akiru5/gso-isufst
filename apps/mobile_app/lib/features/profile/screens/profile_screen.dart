import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/tokens/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final rolesAsync = ref.watch(userRolesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const SizedBox();
          final initials = (profile['full_name'] as String? ?? 'U')
              .split(' ')
              .take(2)
              .map((n) => n[0].toUpperCase())
              .join();
          final roles = rolesAsync.valueOrNull ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary,
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  profile['full_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile['email'] ?? '',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.55),
                    fontSize: 14,
                  ),
                ),

                // Role chips
                if (roles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: roles
                        .map((r) => Chip(
                              label: Text(
                                r.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.2)),
                              padding: EdgeInsets.zero,
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // Info cards
                _InfoCard(
                  items: [
                    _InfoRow(icon: Icons.badge_outlined, label: 'ID Number', value: profile['employee_student_id'] ?? '—'),
                    _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: profile['phone'] ?? '—'),
                    _InfoRow(icon: Icons.business_outlined, label: 'Department', value: (profile['departments'] as Map?)?['name'] ?? '—'),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign out
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: AppColors.statusRejected),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.statusRejected),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.statusRejected),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 18, color: AppColors.neutral400),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
}
