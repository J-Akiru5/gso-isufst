// This file is no longer used as the primary My Loans UI.
// The My Loans tab is now embedded in BorrowingRootScreen.
// Kept as a standalone screen for any future deep-link use.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/tokens/app_colors.dart';
import '../providers/borrowing_provider.dart';

class MyLoansScreen extends ConsumerWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myLoansProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(title: const Text('My Borrowed Items')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myLoansProvider),
        child: loansAsync.when(
          data: (loans) {
            if (loans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
                      child: const Icon(Icons.history_outlined, size: 40, color: AppColors.neutral400),
                    ),
                    const SizedBox(height: 20),
                    const Text('No borrowing history', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Browse the inventory to request items.', style: TextStyle(color: AppColors.neutral500, fontSize: 13)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/borrowing'),
                      child: const Text('Browse Inventory'),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final loan = loans[index];
                final item = loan['item'] as Map?;
                final status = loan['status'] as String? ?? 'Pending';
                final date = DateTime.tryParse(loan['created_at'] ?? '');
                final color = AppColors.statusColor(status);

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => context.push('/borrowing/${loan['id']}'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.neutral100,
                              borderRadius: BorderRadius.circular(10),
                              image: item?['image_url'] != null
                                  ? DecorationImage(image: NetworkImage(item!['image_url']), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: item?['image_url'] == null
                                ? const Icon(Icons.inventory_2, size: 24, color: AppColors.neutral400)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item?['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(
                                  date != null ? DateFormat('MMM d, y').format(date) : '—',
                                  style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => Shimmer.fromColors(
            baseColor: AppColors.neutral200,
            highlightColor: AppColors.neutral100,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, __) => Container(
                height: 80,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
