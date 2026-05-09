import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/features/borrowing/providers/borrowing_provider.dart';

class HodLoanApprovalScreen extends ConsumerStatefulWidget {
  const HodLoanApprovalScreen({super.key});

  @override
  ConsumerState<HodLoanApprovalScreen> createState() => _HodLoanApprovalScreenState();
}

class _HodLoanApprovalScreenState extends ConsumerState<HodLoanApprovalScreen> {
  bool _isSubmitting = false;

  Future<void> _updateStatus(String loanId, String newStatus) async {
    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.from('equipment_loans').update({
        'status': newStatus,
      }).eq('id', loanId);

      if (mounted) {
        ref.refresh(pendingHODLoansProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan request ${newStatus == 'Approved' ? 'approved' : 'rejected'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingHODLoansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Loan Approvals'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pendingHODLoansProvider.future),
        child: pendingAsync.when(
          data: (loans) {
            if (loans.isEmpty) {
              return const Center(child: Text('No pending approvals at the moment.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan['item']?['name'] ?? 'Unknown Item',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text('Borrower: ${loan['borrower']?['full_name']}'),
                        Text('Quantity: ${loan['quantity_borrowed']}'),
                        Text('Purpose: ${loan['purpose'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Pickup: ${DateFormat('MMM d').format(DateTime.parse(loan['expected_pickup_date']))}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            Text('Return: ${DateFormat('MMM d').format(DateTime.parse(loan['expected_return_date']))}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting ? null : () => _updateStatus(loan['id'], 'Rejected'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : () => _updateStatus(loan['id'], 'Approved'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
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
