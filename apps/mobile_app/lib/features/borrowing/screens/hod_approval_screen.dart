// Legacy HOD Approval Screen — now superseded by BorrowingRootScreen Approvals tab.
// Kept to avoid dead import references. References pendingApprovalsProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tokens/app_colors.dart';
import '../providers/borrowing_provider.dart';

class HodLoanApprovalScreen extends ConsumerWidget {
  const HodLoanApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingApprovalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending HOD Approvals')),
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
              itemBuilder: (context, index) {
                final loan = loans[index];
                final item = loan['item'] as Map?;
                final borrower = loan['borrower'] as Map?;
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
                      Text(item?['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('By: ${borrower?['full_name'] ?? 'Unknown'}', style: const TextStyle(color: AppColors.neutral600, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await ref.read(updateLoanStatusProvider({'id': loan['id'], 'status': 'HOD_Rejected'}).future);
                                ref.refresh(pendingApprovalsProvider);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.statusRejected,
                                side: const BorderSide(color: AppColors.statusRejected),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await ref.read(updateLoanStatusProvider({'id': loan['id'], 'status': 'HOD_Approved'}).future);
                                ref.refresh(pendingApprovalsProvider);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusCompleted,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 40),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
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
