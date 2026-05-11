import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Filter State ──────────────────────────────────────────────

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');
final inventoryCategoryFilterProvider = StateProvider<String?>((ref) => null);

// ── Categories ────────────────────────────────────────────────

final inventoryCategoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return Supabase.instance.client
      .from('inventory_categories')
      .select('id, name, icon, color')
      .eq('is_active', true)
      .order('sort_order', ascending: true);
});

// ── All Active Inventory (GSO staff view) ─────────────────────

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

// ── Borrowable Items Only (Borrow tab Browse view) ────────────

final borrowableItemsProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(inventorySearchQueryProvider);
  final categoryId = ref.watch(inventoryCategoryFilterProvider);

  var request = Supabase.instance.client
      .from('inventory_items')
      .select('*, category:inventory_categories(name, icon), building:buildings(name)')
      .eq('is_active', true)
      .eq('is_borrowable', true);

  if (categoryId != null) {
    request = request.eq('category_id', categoryId);
  }
  if (query.isNotEmpty) {
    request = request.ilike('name', '%$query%');
  }

  return request.order('name', ascending: true);
});

// ── Single Item Detail ────────────────────────────────────────

final inventoryItemDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return Supabase.instance.client
      .from('inventory_items')
      .select('*, category:inventory_categories(*), building:buildings(*), room:rooms(*)')
      .eq('id', id)
      .single();
});

// ── Audit Log for Item ────────────────────────────────────────

final inventoryAuditLogProvider = FutureProvider.family<List<dynamic>, String>((ref, itemId) async {
  return Supabase.instance.client
      .from('inventory_audit_log')
      .select('*, performer:profiles(full_name)')
      .eq('item_id', itemId)
      .order('created_at', ascending: false)
      .limit(20);
});
