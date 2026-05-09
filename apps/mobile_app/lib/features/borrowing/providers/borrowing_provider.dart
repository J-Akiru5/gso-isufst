import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/services/supabase_service.dart';

final inventoryProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('inventory_items')
      .select('''
        *,
        category:inventory_categories(name),
        building:buildings(name)
      ''')
      .eq('is_borrowable', true)
      .eq('is_active', true)
      .order('name');
      
  return response as List<dynamic>;
});

final inventoryDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('inventory_items')
      .select('''
        *,
        category:inventory_categories(name),
        building:buildings(name),
        room:rooms(name)
      ''')
      .eq('id', id)
      .single();
      
  return response;
});

final myLoansProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  final response = await supabase
      .from('equipment_loans')
      .select('''
        *,
        item:inventory_items(name, image_url)
      ''')
      .eq('borrower_id', user.id)
      .order('created_at', ascending: false);
      
  return response as List<dynamic>;
});

final pendingHODLoansProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;
  // Note: Add proper department filtering later based on the HOD's department
  final response = await supabase
      .from('equipment_loans')
      .select('''
        *,
        item:inventory_items(name, image_url),
        borrower:profiles!equipment_loans_borrower_id_fkey(full_name)
      ''')
      .eq('status', 'Pending_HOD')
      .order('created_at', ascending: false);
      
  return response as List<dynamic>;
});
