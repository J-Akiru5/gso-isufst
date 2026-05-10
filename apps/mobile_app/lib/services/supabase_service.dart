import 'dart:io';
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

  // ── Rooms & Buildings ───────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRooms() async {
    return await client
        .from('rooms')
        .select('*, buildings(name, code)')
        .eq('is_active', true);
  }

  // ── Bookings ────────────────────────────────────────────────────
  static Future<void> createBooking(Map<String, dynamic> bookingData) async {
    await client.from('bookings').insert(bookingData);
  }

  static Future<List<Map<String, dynamic>>> getMyBookings() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    return await client
        .from('bookings')
        .select('*, rooms(name), buildings(name)')
        .eq('user_id', userId)
        .order('start_time');
  }

  static Future<List<Map<String, dynamic>>> getAllBookings() async {
    return await client
        .from('bookings')
        .select('*, profiles(full_name), rooms(name), buildings(name)')
        .order('start_time');
  }

  static Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? approvedBy,
  }) async {
    await client.from('bookings').update({
      'status': status,
      'approved_by': approvedBy,
      'approval_date': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  static Future<String> uploadBookingAttachment(String path, String fileName) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    final filePath = '$userId/$fileName';
    await client.storage.from('booking_attachments').upload(filePath, File(path));
    return client.storage.from('booking_attachments').getPublicUrl(filePath);
  }
}
