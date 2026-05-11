import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tokens/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/borrowing_provider.dart';

// NOTE: This screen is a fallback for direct /borrowing/management deep links.
// The primary approval UI lives inside BorrowingRootScreen's Approvals tab.

class BorrowManagementScreen extends ConsumerWidget {
  const BorrowManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingApprovalsProvider);
    final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
    final isGso = roles.contains('gso_staff') || roles.contains('super_admin');

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(title: const Text('Loan Approvals')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(pendingApprovalsProvider),
        child: pendingAsync.when(
          data: (loans) {
            if (loans.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: AppColors.statusCompleted),
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
              itemBuilder: (context, index) => _ApprovalTile(loan: loans[index], isGso: isGso),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _ApprovalTile extends ConsumerWidget {
  final dynamic loan;
  final bool isGso;
  const _ApprovalTile({required this.loan, required this.isGso});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(updateLoanStatusProvider({'id': loan['id'], 'status': status}).future);
      ref.refresh(pendingApprovalsProvider);
      if (context.mounted) {
        final isApproval = status.contains('Approved') || status == 'Released';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isApproval ? 'Approved ✓' : 'Rejected'),
          backgroundColor: isApproval ? AppColors.statusCompleted : AppColors.statusRejected,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusRejected),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = loan['item'] as Map?;
    final borrower = loan['borrower'] as Map?;
    final status = loan['status'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(loan['loan_number'] ?? '#---',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              const Spacer(),
              Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item?['name'] ?? 'Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('By: ${borrower?['full_name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 13, color: AppColors.neutral600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus(context, ref, isGso ? 'GSO_Rejected' : 'HOD_Rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRejected,
                    side: const BorderSide(color: AppColors.statusRejected),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, ref, isGso ? 'Released' : 'HOD_Approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusCompleted,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 40),
                    elevation: 0,
                  ),
                  child: Text(isGso ? 'Release Item' : 'Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
