import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton accessor for Supabase client
final supabase = Supabase.instance.client;

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => client.auth.currentUser?.id;
  static Session? get currentSession => client.auth.currentSession;

  // ── Auth ────────────────────────────────────────────────────
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String employeeStudentId,
    required String initialRole,
  }) =>
      client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'employee_student_id': employeeStudentId,
          'initial_role': initialRole,
        },
      );

  static Future<void> signOut() => client.auth.signOut();

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ── Profile ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final res = await client
        .from('profiles')
        .select('*, departments(name, code)')
        .eq('id', userId)
        .maybeSingle();
    return res;
  }

  static Future<void> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) =>
      client.from('profiles').update(data).eq('id', userId);

  // ── Roles ────────────────────────────────────────────────────
  static Future<List<String>> getUserRoles(String userId) async {
    final res = await client
        .from('user_roles')
        .select('roles(name)')
        .eq('user_id', userId);
    return (res as List)
        .map((e) => e['roles']['name'] as String)
        .toList();
  }
}
