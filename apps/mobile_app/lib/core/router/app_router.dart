import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Auth
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
// ── Onboarding
import '../../features/onboarding/screens/onboarding_screen.dart';
// ── Shell
import '../../features/home/screens/home_shell.dart';
import '../../features/home/screens/home_dashboard_screen.dart';
// ── Maintenance
import '../../features/maintenance/screens/maintenance_list_screen.dart';
import '../../features/maintenance/screens/maintenance_detail_screen.dart';
import '../../features/maintenance/screens/maintenance_new_screen.dart';
// ── Inventory
import '../../features/inventory/screens/inventory_list_screen.dart';
import '../../features/inventory/screens/inventory_detail_screen.dart';
// ── Borrowing
import '../../features/borrowing/screens/borrowing_list_screen.dart';
import '../../features/borrowing/screens/loan_detail_screen.dart';
import '../../features/borrowing/screens/borrow_request_screen.dart';
// ── Bookings
import '../../features/bookings/screens/booking_list_screen.dart';
import '../../features/bookings/screens/booking_new_screen.dart';
import '../../features/bookings/screens/ssc_booking_admin_screen.dart';
// ── Travel & Fleet
import '../../features/travel/screens/travel_list_screen.dart';
import '../../features/travel/screens/travel_new_screen.dart';
import '../../features/travel/screens/travel_detail_screen.dart';
import '../../features/travel/screens/driver_trips_screen.dart';
import '../../features/travel/screens/driver_trip_detail_screen.dart';
import '../../features/travel/screens/driver_schedule_screen.dart';
import '../../features/travel/screens/driver_vehicle_screen.dart';
import '../../features/travel/screens/fleet_management_screen.dart';
// ── Profile & Notifications
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notification_center_screen.dart';

// ── Placeholder for not-yet-implemented screens ────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              const Text(
                'Coming in Phase 3',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
}

// ── Router Provider ────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      // ① Onboarding gate
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
        return state.matchedLocation == '/onboarding' ? null : '/onboarding';
      }

      final session = Supabase.instance.client.auth.currentSession;
      final path = state.matchedLocation;
      final isAuthRoute = path.startsWith('/login') ||
          path.startsWith('/register') ||
          path.startsWith('/pending-approval');

      // ② No session → login
      if (session == null) {
        return isAuthRoute ? null : '/login';
      }

      // ③ Session exists — fetch profile + roles in parallel
      try {
        final profileFuture = Supabase.instance.client
            .from('profiles')
            .select('is_approved, is_active')
            .eq('id', session.user.id)
            .maybeSingle();

        final rolesFuture = Supabase.instance.client
            .from('user_roles')
            .select('roles(name)')
            .eq('user_id', session.user.id);

        final results = await Future.wait<dynamic>([profileFuture, rolesFuture]);
        final profile = results[0] as Map<String, dynamic>?;
        final rolesData = results[1] as List<dynamic>?;

        final roles = rolesData
                ?.map((e) => (e['roles'] as Map?)?['name'] as String?)
                .whereType<String>()
                .toList() ??
            [];

        final isSuperAdmin = roles.contains('super_admin');
        final isGso = roles.contains('gso_staff') || isSuperAdmin;
        final isDriver = roles.contains('driver');
        final isSsc = roles.contains('ssc_staff');
        final isDeptHead = roles.contains('department_head') || isSuperAdmin;

        // ④ Inactive account
        if (!isSuperAdmin && profile != null && profile['is_active'] == false) {
          await Supabase.instance.client.auth.signOut();
          return '/login';
        }

        // ⑤ Pending approval
        if (!isSuperAdmin && (profile == null || profile['is_approved'] == false)) {
          return isAuthRoute ? null : '/pending-approval';
        }

        // ⑥ RBAC route guards
        // Admin-only
        if (path.startsWith('/admin/users') && !isSuperAdmin) return '/home';
        // GSO/Admin-only
        if (path.startsWith('/fleet') && !isGso) return '/home';
        if (path.startsWith('/inventory') && !isGso) return '/home';
        // Driver-only routes
        if (path.startsWith('/driver') && !isDriver) return '/home';
        // Block drivers from standard routes
        if (isDriver &&
            (path.startsWith('/borrowing') ||
                path.startsWith('/bookings') ||
                path.startsWith('/travel'))) {
          return '/driver/trips';
        }
        // SSC/GSO/Admin for booking approvals
        if (path.startsWith('/admin/bookings') &&
            !isGso &&
            !isSsc) {
          return '/home';
        }
        // Borrow management for HOD/GSO/Admin
        if (path.startsWith('/borrowing/management') &&
            !isGso &&
            !isDeptHead) {
          return '/home';
        }
      } catch (e) {
        debugPrint('Router redirect error: $e');
        return '/pending-approval';
      }

      // ⑦ Already authenticated → redirect away from auth pages
      return isAuthRoute ? '/home' : null;
    },

    routes: [
      // ── Standalone Auth Routes ──────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/pending-approval',
        builder: (_, __) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── App Shell (Bottom Nav) ─────────────────────────────
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          // ── Home Dashboard
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeDashboardScreen(),
          ),

          // ── Maintenance ─────────────────────────────────────
          GoRoute(
            path: '/maintenance',
            builder: (_, __) => const MaintenanceListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const MaintenanceNewScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => MaintenanceDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // ── Inventory ───────────────────────────────────────
          GoRoute(
            path: '/inventory',
            builder: (_, __) => const InventoryListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => InventoryDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // ── Borrowing ───────────────────────────────────────
          GoRoute(
            path: '/borrowing',
            builder: (_, __) => const BorrowingRootScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) {
                  final itemId = state.uri.queryParameters['itemId'] ?? '';
                  return BorrowRequestScreen(itemId: itemId);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => LoanDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // ── Room Bookings ───────────────────────────────────
          GoRoute(
            path: '/bookings',
            builder: (_, __) => const BookingListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const BookingNewScreen(),
              ),
            ],
          ),

          // ── Travel Requests ─────────────────────────────────
          GoRoute(
            path: '/travel',
            builder: (_, __) => const TravelListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const TravelNewScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => TravelDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // ── Driver Routes ────────────────────────────────────
          GoRoute(
            path: '/driver/trips',
            builder: (_, __) => const DriverTripsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => DriverTripDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/driver/schedule',
            builder: (_, __) => const DriverScheduleScreen(),
          ),
          GoRoute(
            path: '/driver/vehicle',
            builder: (_, __) => const DriverVehicleScreen(),
          ),

          // ── Fleet Management ─────────────────────────────────
          GoRoute(
            path: '/fleet',
            builder: (_, __) => const FleetManagementScreen(),
          ),

          // ── Admin / SSC ──────────────────────────────────────
          GoRoute(
            path: '/admin/bookings',
            builder: (_, __) => const SSCBookingAdminScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'User Management'),
          ),

          // ── Profile & Notifications ──────────────────────────
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationCenterScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Page not found: ${state.uri}'),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
