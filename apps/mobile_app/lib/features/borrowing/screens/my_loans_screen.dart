import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/borrowing_provider.dart';

class MyLoansScreen extends ConsumerWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myLoansProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Borrowed Items', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myLoansProvider),
        child: loansAsync.when(
          data: (loans) {
            if (loans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_outlined, size: 64, color: AppColors.neutral300),
                    const SizedBox(height: 16),
                    const Text('No borrowing history yet', style: TextStyle(color: AppColors.neutral500)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/inventory'),
                      child: const Text('Browse Inventory'),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final loan = loans[index];
                return _LoanListItem(loan: loan);
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

class _LoanListItem extends StatelessWidget {
  final dynamic loan;
  const _LoanListItem({required this.loan});

  @override
  Widget build(BuildContext context) {
    final item = loan['item'];
    final status = loan['status'] ?? 'Pending';
    final date = DateTime.tryParse(loan['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Unknown date';

    return InkWell(
      onTap: () => context.push('/borrowing/${loan['id']}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(8),
                image: item['image_url'] != null
                    ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: item['image_url'] == null ? const Icon(Icons.inventory_2, color: AppColors.neutral400) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Requested on $dateStr', style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                ],
              ),
            ),
            _StatusChip(status: status),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.neutral500;
    Color bgColor = AppColors.neutral100;

    if (status.contains('Approved')) {
      color = AppColors.success600;
      bgColor = AppColors.success50;
    } else if (status.contains('Pending')) {
      color = AppColors.primary600;
      bgColor = AppColors.primary50;
    } else if (status.contains('Rejected') || status.contains('Cancelled')) {
      color = AppColors.statusUrgent;
      bgColor = AppColors.statusUrgent.withOpacity(0.1);
    } else if (status == 'Released' || status == 'In_Use') {
      color = Colors.blue;
      bgColor = Colors.blue.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
