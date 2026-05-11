import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');
final inventoryCategoryFilterProvider = StateProvider<String?>((ref) => null);

final inventoryCategoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return Supabase.instance.client
      .from('inventory_categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', ascending: true);
});

final inventoryItemsProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(inventorySearchQueryProvider);
  final categoryId = ref.watch(inventoryCategoryFilterProvider);
  
  var request = Supabase.instance.client
      .from('inventory_items')
      .select('*, category:inventory_categories(name, icon), building:buildings(name), room:rooms(name)')
      .eq('is_active', true);

  if (categoryId != null) {
    request = request.eq('category_id', categoryId);
  }

  if (query.isNotEmpty) {
    request = request.ilike('name', '%$query%');
  }

  return request.order('name', ascending: true);
});

final inventoryItemDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return Supabase.instance.client
      .from('inventory_items')
      .select('*, category:inventory_categories(*), building:buildings(*), room:rooms(*)')
      .eq('id', id)
      .single();
});
