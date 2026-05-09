import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/borrowing/providers/borrowing_provider.dart';

class MyLoansScreen extends ConsumerWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myLoansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loans'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myLoansProvider.future),
        child: loansAsync.when(
          data: (loans) {
            if (loans.isEmpty) {
              return const Center(child: Text('You have no borrowing history.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              itemBuilder: (context, index) {
                return _LoanCard(loan: loans[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final item = loan['item'];
    final status = loan['status'] as String;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item?['name'] ?? 'Unknown Item',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Pickup: ${DateFormat('MMM d').format(DateTime.parse(loan['expected_pickup_date']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.keyboard_return, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Return: ${DateFormat('MMM d').format(DateTime.parse(loan['expected_return_date']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quantity: ${loan['quantity_borrowed']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            if (loan['purpose'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Purpose: ${loan['purpose']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label = status.replaceAll('_', ' ');

    switch (status) {
      case 'Pending_HOD':
      case 'Pending_GSO':
        color = Colors.orange;
        break;
      case 'Approved':
      case 'Active':
        color = Colors.green;
        break;
      case 'Returned':
        color = Colors.blue;
        break;
      case 'Overdue':
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
