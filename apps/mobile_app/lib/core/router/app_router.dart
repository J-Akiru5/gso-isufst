import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/maintenance/screens/maintenance_list_screen.dart';
import '../../features/maintenance/screens/maintenance_detail_screen.dart';
import '../../features/maintenance/screens/maintenance_new_screen.dart';
import '../../features/inventory/screens/inventory_list_screen.dart';
import '../../features/borrowing/screens/borrowing_list_screen.dart';
import '../../features/borrowing/screens/borrowing_detail_screen.dart';
import '../../features/borrowing/screens/borrowing_new_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (!hasSeenOnboarding) {
        return state.matchedLocation == '/onboarding' ? null : '/onboarding';
      }

      final session = Supabase.instance.client.auth.currentSession;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/pending-approval');

      if (session == null) {
        return isAuthRoute ? null : '/login';
      }

      // Check approval and roles
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

        final results = await Future.wait([profileFuture, rolesFuture]);
        final profile = results[0] as Map<String, dynamic>?;
        final rolesData = results[1] as List<dynamic>?;

        final roles = rolesData
                ?.map((e) => (e['roles'] as Map?)?['name'] as String?)
                .where((e) => e != null)
                .toList() ??
            [];
            
        final isSuperAdmin = roles.contains('super_admin');

        if (!isSuperAdmin) {
          if (profile != null && profile['is_active'] == false) {
            await Supabase.instance.client.auth.signOut();
            return '/login';
          }

          if (profile == null || profile['is_approved'] == false) {
            return isAuthRoute ? null : '/pending-approval';
          }
        }
      } catch (e) {
        debugPrint('Router error checking approval: $e');
        return '/pending-approval';
      }

      return isAuthRoute ? '/home' : null;
    },
    routes: [
      // ── Auth Routes ────────────────────────────────────
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


      // ── App Shell (Bottom Nav) ─────────────────────────
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const MaintenanceListScreen()),

          // Maintenance
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
                builder: (context, state) => MaintenanceDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Inventory
          GoRoute(
            path: '/inventory',
            builder: (_, __) => const InventoryListScreen(),
          ),

          // Borrowing
          GoRoute(
            path: '/borrowing',
            builder: (_, __) => const BorrowingListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const BorrowingNewScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => BorrowingDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Profile & Notifications
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
