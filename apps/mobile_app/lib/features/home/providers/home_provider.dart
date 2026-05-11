import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

// ── Standard User Stats ──────────────────────────────────────
final myStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return {'maintenance': [], 'loans': [], 'bookings': []};
  final sb = Supabase.instance.client;

  final results = await Future.wait<dynamic>([
    sb.from('maintenance_requests')
        .select('id, status, title, priority_level, created_at')
        .eq('requester_id', user.id)
        .inFilter('status', ['Submitted', 'Received_GSO', 'Assigned', 'In_Progress'])
        .order('created_at', ascending: false)
        .limit(3),
    sb.from('equipment_loans')
        .select('id, status, loan_number, created_at')
        .eq('borrower_id', user.id)
        .inFilter('status', ['Pending_HOD', 'HOD_Approved', 'Pending_GSO', 'GSO_Approved', 'Released', 'In_Use'])
        .order('created_at', ascending: false)
        .limit(3),
    sb.from('bookings')
        .select('id, title, start_time, status')
        .eq('user_id', user.id)
        .eq('status', 'approved')
        .gte('start_time', DateTime.now().toIso8601String())
        .order('start_time', ascending: true)
        .limit(3),
  ]);

  return {
    'maintenance': results[0] as List<dynamic>,
    'loans': results[1] as List<dynamic>,
    'bookings': results[2] as List<dynamic>,
  };
});

// ── GSO / Admin KPIs ─────────────────────────────────────────
final gsoStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return {};
  final sb = Supabase.instance.client;

  final results = await Future.wait<dynamic>([
    sb.from('maintenance_requests')
        .select('id')
        .inFilter('status', ['Submitted', 'Received_GSO', 'Assigned', 'In_Progress']),
    sb.from('equipment_loans').select('id').inFilter('status', ['Released', 'In_Use']),
    sb.from('equipment_loans').select('id').eq('status', 'Overdue'),
    sb.from('equipment_loans').select('id').eq('status', 'Pending_HOD'),
    sb.from('travel_bookings').select('id').eq('status', 'Pending'),
    sb.from('maintenance_requests')
        .select('id, status, title, priority_level, created_at, requester:profiles!maintenance_requests_requester_id_fkey(full_name)')
        .inFilter('status', ['Submitted', 'Received_GSO', 'Assigned', 'In_Progress'])
        .order('created_at', ascending: false)
        .limit(5),
  ]);

  return {
    'openMaintenance': (results[0] as List).length,
    'activeBorrows': (results[1] as List).length,
    'overdueItems': (results[2] as List).length,
    'pendingApprovals': (results[3] as List).length + (results[4] as List).length,
    'recentMaintenance': results[5] as List<dynamic>,
  };
});

// ── Driver Dashboard ─────────────────────────────────────────
final driverDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return {};
  final sb = Supabase.instance.client;
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();

  final results = await Future.wait<dynamic>([
    sb.from('travel_bookings')
        .select('*, vehicle:vehicles(plate_number, brand, model), requester:profiles!travel_bookings_requester_id_fkey(full_name, phone)')
        .eq('driver_id', user.id)
        .inFilter('status', ['Scheduled', 'Ongoing'])
        .gte('departure_time', todayStart)
        .lte('departure_time', todayEnd)
        .limit(1),
    sb.from('travel_bookings')
        .select('id, booking_number, destination, departure_time, return_time, status, passenger_names')
        .eq('driver_id', user.id)
        .eq('status', 'Scheduled')
        .gt('departure_time', todayEnd)
        .order('departure_time', ascending: true)
        .limit(5),
    sb.from('travel_bookings').select('id').eq('driver_id', user.id).eq('status', 'Completed'),
  ]);

  final todayList = results[0] as List<dynamic>;
  return {
    'todayTrip': todayList.isNotEmpty ? todayList.first : null,
    'upcomingTrips': results[1] as List<dynamic>,
    'completedCount': (results[2] as List).length,
  };
});

// ── Technician Dashboard ─────────────────────────────────────
final technicianDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return {'tasks': [], 'completedCount': 0};
  final sb = Supabase.instance.client;

  final results = await Future.wait<dynamic>([
    sb.from('maintenance_requests')
        .select('id, status, title, priority_level, created_at, building:buildings(name), room:rooms(name)')
        .eq('assigned_to', user.id)
        .inFilter('status', ['Assigned', 'In_Progress'])
        .order('created_at', ascending: false)
        .limit(10),
    sb.from('maintenance_requests').select('id').eq('assigned_to', user.id).eq('status', 'Completed'),
  ]);

  return {
    'tasks': results[0] as List<dynamic>,
    'completedCount': (results[1] as List).length,
  };
});

// ── HOD Pending Loans ────────────────────────────────────────
final hodPendingProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return [];
  return Supabase.instance.client
      .from('equipment_loans')
      .select('id, loan_number, status, purpose, quantity_borrowed, created_at, item:inventory_items(name), borrower:profiles!equipment_loans_borrower_id_fkey(full_name)')
      .eq('status', 'Pending_HOD')
      .order('created_at', ascending: false)
      .limit(10);
});
