import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/borrowing_provider.dart';

class BorrowManagementScreen extends ConsumerWidget {
  const BorrowManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingApprovalsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Loan Approvals', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(pendingApprovalsProvider),
        child: pendingAsync.when(
          data: (loans) {
            if (loans.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: AppColors.success600),
                    SizedBox(height: 16),
                    Text('No pending approvals', style: TextStyle(color: AppColors.neutral500)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final loan = loans[index];
                return _ApprovalCard(loan: loan);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  final dynamic loan;
  const _ApprovalCard({required this.loan});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String decision) async {
    final status = decision == 'Approved' ? 'HOD_Approved' : 'HOD_Rejected'; // Simplified for now
    
    // In a real app, this should handle GSO vs HOD logic properly
    try {
      await Supabase.instance.client.from('equipment_loans').update({
        'status': status,
      }).eq('id', loan['id']);

      ref.refresh(pendingApprovalsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $decision'), backgroundColor: decision == 'Approved' ? AppColors.success600 : AppColors.statusUrgent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusUrgent),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borrower = loan['borrower'] as Map?;
    final item = loan['item'] as Map?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loan['loan_number'] ?? '#---', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary600)),
              Text(loan['status']?.toString().replaceAll('_', ' ') ?? '', style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item?['name'] ?? 'Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Borrowed by: ${borrower?['full_name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14, color: AppColors.neutral600)),
          const SizedBox(height: 12),
          Text('Purpose: ${loan['purpose'] ?? 'No purpose provided'}', style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus(context, ref, 'Rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusUrgent,
                    side: const BorderSide(color: AppColors.statusUrgent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, ref, 'Approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
