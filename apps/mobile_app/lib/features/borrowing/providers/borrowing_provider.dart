import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

final myLoansProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return [];
  
  return Supabase.instance.client
      .from('equipment_loans')
      .select('*, item:inventory_items(name, image_url)')
      .eq('borrower_id', user.id)
      .order('created_at', ascending: false);
});

final loanDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final sb = Supabase.instance.client;
  final results = await Future.wait<dynamic>([
    sb.from('equipment_loans')
        .select('*, item:inventory_items(*, category:inventory_categories(name)), borrower:profiles!equipment_loans_borrower_id_fkey(*)')
        .eq('id', id)
        .single(),
    sb.from('loan_timeline')
        .select('*, performer:profiles(full_name)')
        .eq('loan_id', id)
        .order('created_at', ascending: true),
  ]);

  final loan = results[0] as Map<String, dynamic>;
  loan['timeline'] = results[1] as List<dynamic>;
  return loan;
});

// ── Management / Approvals ────────────────────────────────────

final pendingApprovalsProvider = FutureProvider<List<dynamic>>((ref) async {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  final isGso = roles.contains('gso_staff') || roles.contains('super_admin');
  final isHod = roles.contains('department_head');
  
  final sb = Supabase.instance.client;
  var request = sb.from('equipment_loans')
      .select('*, item:inventory_items(name, image_url), borrower:profiles!equipment_loans_borrower_id_fkey(full_name, department_id)');

  if (isHod && !isGso) {
    request = request.eq('status', 'Pending_HOD');
  } else if (isGso) {
    request = request.inFilter('status', ['Pending_GSO', 'GSO_Approved', 'Released', 'In_Use']);
  } else {
    // Standard users don't see management list
    return [];
  }

  return request.order('created_at', ascending: false);
});
