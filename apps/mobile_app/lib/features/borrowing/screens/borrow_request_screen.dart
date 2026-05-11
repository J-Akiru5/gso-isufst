import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/borrowing_provider.dart';

class BorrowRequestScreen extends ConsumerStatefulWidget {
  final String itemId;
  const BorrowRequestScreen({super.key, required this.itemId});

  @override
  ConsumerState<BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends ConsumerState<BorrowRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  DateTime? _returnDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Get next loan number (simplistic for demo, usually handled by DB function)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final loanNumber = 'LN-$timestamp';

      await Supabase.instance.client.from('equipment_loans').insert({
        'loan_number': loanNumber,
        'item_id': widget.itemId,
        'borrower_id': user.id,
        'purpose': _purposeController.text,
        'quantity_borrowed': int.parse(_quantityController.text),
        'expected_return_date': _returnDate!.toIso8601String(),
        'status': 'Pending_HOD',
      });

      if (mounted) {
        ref.refresh(myLoansProvider);
        context.go('/borrowing');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borrow request submitted successfully!'), backgroundColor: AppColors.success600),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusUrgent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(inventoryItemDetailProvider(widget.itemId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Borrow Request', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () => context.pop(),
        ),
      ),
      body: itemAsync.when(
        data: (item) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                            Text(item['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Stock available: ${item['available_quantity']}', style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text('Purpose of Borrowing', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _purposeController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. For class presentation, event setup...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              final q = int.tryParse(val);
                              if (q == null || q <= 0) return 'Invalid';
                              if (q > (item['available_quantity'] ?? 0)) return 'Low stock';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Return Date', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) setState(() => _returnDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _returnDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_returnDate!),
                                    style: TextStyle(color: _returnDate == null ? AppColors.neutral500 : Colors.black),
                                  ),
                                  const Icon(Icons.calendar_today, size: 18, color: AppColors.neutral500),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
