import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/tokens/app_colors.dart';

/// Drawer item model
class _DrawerItem {
  final String label;
  final IconData icon;
  final String path;
  final List<String> allowedRoles; // empty = all authenticated
  final List<String> excludedRoles;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.path,
    this.allowedRoles = const [],
    this.excludedRoles = const [],
  });
}

/// Section model
class _DrawerSection {
  final String? title;
  final List<_DrawerItem> items;
  const _DrawerSection({this.title, required this.items});
}

const _allSections = [
  _DrawerSection(items: [
    _DrawerItem(label: 'Home', icon: Icons.home_outlined, path: '/home'),
  ]),
  _DrawerSection(title: 'Operations', items: [
    _DrawerItem(label: 'Maintenance', icon: Icons.build_outlined, path: '/maintenance'),
    _DrawerItem(
      label: 'Borrowing',
      icon: Icons.assignment_outlined,
      path: '/borrowing',
      excludedRoles: ['driver'],
    ),
    _DrawerItem(
      label: 'Room Bookings',
      icon: Icons.meeting_room_outlined,
      path: '/bookings',
      excludedRoles: ['driver'],
    ),
    _DrawerItem(
      label: 'Travel Requests',
      icon: Icons.directions_car_outlined,
      path: '/travel',
      excludedRoles: ['driver'],
    ),
  ]),
  _DrawerSection(title: 'Driver', items: [
    _DrawerItem(
      label: 'My Trips',
      icon: Icons.route_outlined,
      path: '/driver/trips',
      allowedRoles: ['driver'],
    ),
    _DrawerItem(
      label: 'My Schedule',
      icon: Icons.calendar_month_outlined,
      path: '/driver/schedule',
      allowedRoles: ['driver'],
    ),
    _DrawerItem(
      label: 'My Vehicle',
      icon: Icons.directions_car_filled_outlined,
      path: '/driver/vehicle',
      allowedRoles: ['driver'],
    ),
  ]),
  _DrawerSection(title: 'Management', items: [
    _DrawerItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      path: '/inventory',
      allowedRoles: ['gso_staff', 'super_admin'],
    ),
    _DrawerItem(
      label: 'Borrow Management',
      icon: Icons.manage_accounts_outlined,
      path: '/borrowing/management',
      allowedRoles: ['gso_staff', 'super_admin', 'department_head'],
    ),
    _DrawerItem(
      label: 'Fleet Management',
      icon: Icons.local_shipping_outlined,
      path: '/fleet',
      allowedRoles: ['gso_staff', 'super_admin'],
    ),
    _DrawerItem(
      label: 'Booking Approvals',
      icon: Icons.event_available_outlined,
      path: '/admin/bookings',
      allowedRoles: ['gso_staff', 'super_admin', 'ssc_staff'],
    ),
    _DrawerItem(
      label: 'User Management',
      icon: Icons.group_outlined,
      path: '/admin/users',
      allowedRoles: ['super_admin'],
    ),
  ]),
  _DrawerSection(title: 'Account', items: [
    _DrawerItem(label: 'Notifications', icon: Icons.notifications_outlined, path: '/notifications'),
    _DrawerItem(label: 'Profile & Settings', icon: Icons.manage_accounts_outlined, path: '/profile'),
  ]),
];

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
    final currentPath = GoRouterState.of(context).uri.path;

    return Drawer(
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          _DrawerHeader(profileAsync: profileAsync, roles: roles),

          // ── Navigation Items ──────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final section in _allSections) ...[
                  // Filter items by role
                  Builder(builder: (context) {
                    final visibleItems = section.items.where((item) {
                      if (item.allowedRoles.isNotEmpty) {
                        return item.allowedRoles
                            .any((r) => roles.contains(r));
                      }
                      if (item.excludedRoles.isNotEmpty) {
                        return !item.excludedRoles
                            .any((r) => roles.contains(r));
                      }
                      return true;
                    }).toList();

                    if (visibleItems.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.title != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              section.title!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral400,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        for (final item in visibleItems)
                          _DrawerTile(
                            item: item,
                            isActive: currentPath.startsWith(item.path),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go(item.path);
                            },
                          ),
                      ],
                    );
                  }),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Footer: Sign Out ──────────────────────────────────
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.statusRejected),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.statusRejected,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Drawer Header ────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> profileAsync;
  final List<String> roles;

  const _DrawerHeader({required this.profileAsync, required this.roles});

  @override
  Widget build(BuildContext context) {
    return profileAsync.when(
      loading: () => _buildHeader(context, null, roles),
      error: (_, __) => _buildHeader(context, null, roles),
      data: (profile) => _buildHeader(context, profile, roles),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Map<String, dynamic>? profile,
    List<String> roles,
  ) {
    final fullName = profile?['full_name'] as String? ?? 'User';
    final email = profile?['email'] as String? ?? '';
    final avatarUrl = profile?['avatar_url'] as String?;
    final initials = fullName
        .split(' ')
        .take(2)
        .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
        .join();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: roles
                  .take(3)
                  .map(
                    (r) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        r.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Drawer Tile ───────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final _DrawerItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isActive ? AppColors.primary : AppColors.neutral500,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isActive ? AppColors.primary : null,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }
}
