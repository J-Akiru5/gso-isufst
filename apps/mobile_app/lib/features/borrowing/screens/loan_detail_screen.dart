import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/borrowing_provider.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String id;
  const LoanDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(loanDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Loan Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: loanAsync.when(
        data: (loan) => SingleChildScrollView(
          child: Column(
            children: [
              _HeaderSection(loan: loan),
              _DetailsCard(loan: loan),
              _TimelineSection(timeline: loan['timeline'] ?? []),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _HeaderSection({required this.loan});

  @override
  Widget build(BuildContext context) {
    final status = loan['status'] ?? 'Unknown';
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.replaceAll('_', ' '),
              style: const TextStyle(color: AppColors.primary700, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loan['loan_number'] ?? '#---',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Requested on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(loan['created_at']))}',
            style: const TextStyle(color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _DetailsCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final item = loan['item'];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BORROWED ITEM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral500)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2, size: 20, color: AppColors.neutral400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item?['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Qty: ${loan['quantity_borrowed']}', style: const TextStyle(fontSize: 13, color: AppColors.neutral600)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _InfoRow(label: 'Purpose', value: loan['purpose'] ?? '—'),
          _InfoRow(label: 'Exp. Return', value: DateFormat('MMM dd, yyyy').format(DateTime.parse(loan['expected_return_date']))),
          _InfoRow(label: 'Actual Return', value: loan['actual_return_date'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(loan['actual_return_date'])) : 'Pending'),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<dynamic> timeline;
  const _TimelineSection({required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRACKING TIMELINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral500)),
          const SizedBox(height: 20),
          if (timeline.isEmpty)
            const Center(child: Text('No timeline data available', style: TextStyle(color: AppColors.neutral400, fontSize: 13)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final step = timeline[index];
                final isLast = index == timeline.length - 1;
                return _TimelineItem(
                  title: step['title'] ?? 'Updated',
                  subtitle: step['description'] ?? '',
                  date: DateFormat('MMM dd, HH:mm').format(DateTime.parse(step['created_at'])),
                  isLast: isLast,
                  performer: step['performer']?['full_name'],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final bool isLast;
  final String? performer;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.isLast,
    this.performer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: AppColors.primary600, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: AppColors.neutral200),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(date, style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                ],
              ),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.neutral600)),
              if (performer != null)
                Text('By $performer', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.neutral500)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
