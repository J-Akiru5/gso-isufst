import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

// ── Auth State ───────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Listen to auth state changes
    ref.onDispose(
      SupabaseService.authStateChanges.listen((event) {
        state = AsyncValue.data(event.session?.user);
      }).cancel,
    );
    return SupabaseService.currentUser;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      return res.user;
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String employeeStudentId,
    required String initialRole,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        employeeStudentId: employeeStudentId,
        initialRole: initialRole,
      );
      return res.user;
    });
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

// ── Profile ──────────────────────────────────────────────────

final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return null;
  return SupabaseService.getProfile(user.id);
});

// ── User Roles ───────────────────────────────────────────────

final userRolesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return [];
  return SupabaseService.getUserRoles(user.id);
});

// ── Role Helpers ─────────────────────────────────────────────

final isSuperAdminProvider = Provider.autoDispose<bool>((ref) {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  return roles.contains('super_admin');
});

final isGsoStaffProvider = Provider.autoDispose<bool>((ref) {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  return roles.contains('gso_staff') || roles.contains('super_admin');
});

final isDeptHeadProvider = Provider.autoDispose<bool>((ref) {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  return roles.contains('department_head') || roles.contains('super_admin');
});

final isTechnicianProvider = Provider.autoDispose<bool>((ref) {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  return roles.contains('technician');
});

final isDriverProvider = Provider.autoDispose<bool>((ref) {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  return roles.contains('driver');
});

final isSscStaffProvider = Provider.autoDispose<bool>((ref) {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  return roles.contains('ssc_staff');
});
