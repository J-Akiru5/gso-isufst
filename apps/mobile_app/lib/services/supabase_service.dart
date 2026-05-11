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

  // ── Travel ─────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyTravelBookings(String userId) async {
    final res = await client
        .from('travel_bookings')
        .select(
          '*,'
          'requester:profiles!travel_bookings_requester_id_fkey(full_name),'
          'driver:profiles!travel_bookings_driver_id_fkey(full_name),'
          'vehicle:vehicles(plate_number, brand, model)',
        )
        .eq('requester_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllTravelBookings() async {
    final res = await client
        .from('travel_bookings')
        .select(
          '*,'
          'requester:profiles!travel_bookings_requester_id_fkey(full_name),'
          'driver:profiles!travel_bookings_driver_id_fkey(full_name),'
          'vehicle:vehicles(plate_number, brand, model)',
        )
        .order('created_at', ascending: false);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> getDriverTrips(String driverId) async {
    final res = await client
        .from('travel_bookings')
        .select(
          '*,'
          'requester:profiles!travel_bookings_requester_id_fkey(full_name),'
          'driver:profiles!travel_bookings_driver_id_fkey(full_name),'
          'vehicle:vehicles(plate_number, brand, model)',
        )
        .eq('driver_id', driverId)
        .order('departure_time', ascending: true);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> getTravelBooking(String bookingId) async {
    final res = await client
        .from('travel_bookings')
        .select(
          '*,'
          'requester:profiles!travel_bookings_requester_id_fkey(full_name, email, phone),'
          'driver:profiles!travel_bookings_driver_id_fkey(full_name, email, phone),'
          'vehicle:vehicles(plate_number, brand, model, status)',
        )
        .eq('id', bookingId)
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<String> createTravelBooking(Map<String, dynamic> payload) async {
    final res = await client
        .from('travel_bookings')
        .insert(payload)
        .select('id')
        .single();
    return (res as Map)['id'].toString();
  }

  static Future<void> updateTravelBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await client.from('travel_bookings').update({'status': status}).eq('id', bookingId);
  }

  static Future<void> assignTravelBooking({
    required String bookingId,
    String? driverId,
    String? vehicleId,
  }) async {
    final update = <String, dynamic>{};
    if (driverId != null && driverId.isNotEmpty) update['driver_id'] = driverId;
    if (vehicleId != null && vehicleId.isNotEmpty) update['vehicle_id'] = vehicleId;
    update['status'] = 'Scheduled';
    await client.from('travel_bookings').update(update).eq('id', bookingId);
  }

  // ── Fleet ──────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getVehicles() async {
    final res = await client.from('vehicles').select('*').order('plate_number', ascending: true);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> upsertVehicle(Map<String, dynamic> payload) async {
    await client.from('vehicles').upsert(payload);
  }

  static Future<void> updateVehicleStatus({
    required String vehicleId,
    required String status,
  }) async {
    await client.from('vehicles').update({'status': status}).eq('id', vehicleId);
  }

  static Future<List<Map<String, dynamic>>> getDriverProfiles() async {
    final roleRows = await client
        .from('user_roles')
        .select('user_id, roles(name)');
    final ids = (roleRows as List)
        .where((e) => ((e as Map)['roles'] as Map?)?['name'] == 'driver')
        .map((e) => (e as Map)['user_id']?.toString())
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return [];
    final profiles = await client
        .from('profiles')
        .select('id, full_name, email')
        .inFilter('id', ids)
        .order('full_name', ascending: true);
    return (profiles as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
