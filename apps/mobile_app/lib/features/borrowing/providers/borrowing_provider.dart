import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

// ── Loan History ──────────────────────────────────────────────

final myLoansProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return [];
  return Supabase.instance.client
      .from('equipment_loans')
      .select('*, item:inventory_items(name, image_url)')
      .eq('borrower_id', user.id)
      .order('created_at', ascending: false);
});

// ── Loan Detail + Timeline ────────────────────────────────────

final loanDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final sb = Supabase.instance.client;
  final results = await Future.wait<dynamic>([
    sb.from('equipment_loans')
        .select(
          '*,'
          'item:inventory_items(*, category:inventory_categories(name, icon)),'
          'borrower:profiles!equipment_loans_borrower_id_fkey(full_name, email, avatar_url),'
          'released_by_profile:profiles!equipment_loans_released_by_fkey(full_name),'
          'returned_to_profile:profiles!equipment_loans_returned_to_fkey(full_name)',
        )
        .eq('id', id)
        .single(),
    sb.from('loan_timeline')
        .select('*, performer:profiles(full_name)')
        .eq('loan_id', id)
        .order('created_at', ascending: true),
  ]);
  final loan = Map<String, dynamic>.from(results[0] as Map);
  loan['timeline'] = results[1] as List<dynamic>;
  return loan;
});

// ── Approvals / Management ────────────────────────────────────

final pendingApprovalsProvider = FutureProvider<List<dynamic>>((ref) async {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  final isGso = roles.contains('gso_staff') || roles.contains('super_admin');
  final isHod = roles.contains('department_head');
  if (!isGso && !isHod) return [];

  final sb = Supabase.instance.client;
  var request = sb.from('equipment_loans').select(
    '*,'
    'item:inventory_items(name, image_url),'
    'borrower:profiles!equipment_loans_borrower_id_fkey(full_name, department_id)',
  );

  if (isGso) {
    // GSO handles items that are HOD-approved or still pending GSO action
    request = request.inFilter('status', ['HOD_Approved', 'Pending_GSO', 'Released', 'In_Use']);
  } else {
    // HOD sees only items pending their own approval
    request = request.eq('status', 'Pending_HOD');
  }

  return request.order('created_at', ascending: false);
});

// ── Status Update Mutation ────────────────────────────────────

final updateLoanStatusProvider = FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final id = params['id']!;
  final status = params['status']!;
  final update = <String, dynamic>{'status': status};

  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    // Stamp who performed the action
    if (status == 'Released') {
      update['released_by'] = user.id;
      update['released_at'] = DateTime.now().toIso8601String();
    } else if (status == 'Returned') {
      update['returned_to'] = user.id;
      update['returned_at'] = DateTime.now().toIso8601String();
    } else if (status == 'Inspected') {
      update['inspected_by'] = user.id;
      update['inspected_at'] = DateTime.now().toIso8601String();
    }
  }

  await Supabase.instance.client.from('equipment_loans').update(update).eq('id', id);
});
