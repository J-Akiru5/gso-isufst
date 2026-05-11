import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/tokens/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

// ── Tab Definition ──────────────────────────────────────────────

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _Tab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}

// Standard 5-tab set (Student, Faculty, HOD, GSO, Technician, SSC, Super Admin)
const _standardTabs = [
  _Tab(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home, path: '/home'),
  _Tab(label: 'Maintenance', icon: Icons.build_outlined, activeIcon: Icons.build, path: '/maintenance'),
  _Tab(label: 'Borrowing', icon: Icons.assignment_outlined, activeIcon: Icons.assignment, path: '/borrowing'),
  _Tab(label: 'Bookings', icon: Icons.meeting_room_outlined, activeIcon: Icons.meeting_room, path: '/bookings'),
  _Tab(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, path: '/profile'),
];

// Driver-specific 5-tab set
const _driverTabs = [
  _Tab(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home, path: '/home'),
  _Tab(label: 'My Trips', icon: Icons.route_outlined, activeIcon: Icons.route, path: '/driver/trips'),
  _Tab(label: 'Schedule', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, path: '/driver/schedule'),
  _Tab(label: 'Vehicle', icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car, path: '/driver/vehicle'),
  _Tab(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, path: '/profile'),
];

// ── HomeShell ────────────────────────────────────────────────────

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDriver = ref.watch(isDriverProvider);
    final rolesAsync = ref.watch(userRolesProvider);
    final unreadCount = ref.watch(_unreadCountProvider);

    // Determine which tab set to use
    final tabs = rolesAsync.when(
      loading: () => _standardTabs,
      error: (_, __) => _standardTabs,
      data: (_) => isDriver ? _driverTabs : _standardTabs,
    );

    final currentPath = GoRouterState.of(context).uri.path;
    final currentIndex = _resolveTabIndex(currentPath, tabs);

    return Scaffold(
      // ── Hamburger Drawer ──────────────────────────────────────
      drawer: const AppDrawer(),

      // ── AppBar ───────────────────────────────────────────────
      appBar: _buildAppBar(context, currentPath, unreadCount),

      // ── Body ─────────────────────────────────────────────────
      body: child,

      // ── Bottom Navigation ────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(context, tabs, currentIndex),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String path,
    int unread,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      // Hamburger icon opens the drawer
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Image.asset('assets/images/gso_logo.png', height: 28, errorBuilder: (_, __, ___) =>
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'GSO Portal',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell with unread badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.statusRejected,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    List<_Tab> tabs,
    int currentIndex,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(tabs[i].path),
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64,
          destinations: tabs
              .asMap()
              .entries
              .map(
                (e) => NavigationDestination(
                  icon: Icon(e.value.icon, size: 22),
                  selectedIcon: Icon(
                    e.value.activeIcon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  label: e.value.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  static int _resolveTabIndex(String path, List<_Tab> tabs) {
    for (int i = 0; i < tabs.length; i++) {
      if (path == tabs[i].path || path.startsWith('${tabs[i].path}/')) {
        return i;
      }
    }
    // Fallback: home is always index 0
    return 0;
  }
}

// ── Unread Notification Count Provider ───────────────────────────

final _unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return Stream.value(0);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) => rows.where((r) => r['is_read'] == false).length);
});

// ignore: avoid_annotating_with_dynamic
