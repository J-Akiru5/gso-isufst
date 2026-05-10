import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/services/supabase_service.dart';

final profileProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final response = await supabase
      .from('profiles')
      .select('*, user_roles(roles(name))')
      .eq('id', user.id)
      .single();
  
  return response;
});

final maintenanceListProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  // Fetch profile to check roles
  final profileRes = await supabase
      .from('profiles')
      .select('*, user_roles(roles(name))')
      .eq('id', user.id)
      .single();
  
  final roles = (profileRes['user_roles'] as List)
      .map((ur) => ur['roles']['name'] as String)
      .toList();
  
  final isGSO = roles.contains('gso_staff') || roles.contains('super_admin');
  final isTechnician = roles.contains('technician');

  var query = supabase
      .from('maintenance_requests')
      .select('''
        *,
        category:maintenance_categories(name),
        building:buildings(name),
        room:rooms(name),
        requester:profiles!maintenance_requests_requester_id_fkey(full_name, avatar_url)
      ''');

  if (isGSO) {
    // See all
  } else if (isTechnician) {
    query = query.eq('assigned_to', user.id);
  } else {
    query = query.eq('requester_id', user.id);
  }

  final response = await query.order('created_at', ascending: false);
  return response as List<dynamic>;
});

final maintenanceDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('maintenance_requests')
      .select('''
        *,
        category:maintenance_categories(name),
        building:buildings(name),
        room:rooms(name),
        requester:profiles!maintenance_requests_requester_id_fkey(full_name, avatar_url, phone, department:departments(name)),
        technician:profiles!maintenance_requests_assigned_to_fkey(full_name, avatar_url),
        attachments:maintenance_attachments(*),
        timeline:maintenance_timeline(*, performed_by:profiles(full_name))
      ''')
      .eq('id', id)
      .single();
      
  return response;
});

final maintenanceTimelineStreamProvider = StreamProvider.autoDispose.family<List<dynamic>, String>((ref, requestId) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('maintenance_timeline')
      .stream(primaryKey: ['id'])
      .eq('request_id', requestId)
      .order('created_at', ascending: false);
});
