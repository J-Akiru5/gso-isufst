import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/tokens/app_colors.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/borrowing_provider.dart';

class ReserveItemScreen extends ConsumerStatefulWidget {
  final String id;

  const ReserveItemScreen({super.key, required this.id});

  @override
  ConsumerState<ReserveItemScreen> createState() => _ReserveItemScreenState();
}

class _ReserveItemScreenState extends ConsumerState<ReserveItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  
  int _quantity = 1;
  DateTime _pickupDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  Future<void> _submit(Map<String, dynamic> item) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_quantity > item['available_quantity']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${item['available_quantity']} items available')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('equipment_loans').insert({
        'item_id': item['id'],
        'borrower_id': userId,
        'purpose': _purposeController.text,
        'quantity_borrowed': _quantity,
        'expected_pickup_date': DateFormat('yyyy-MM-dd').format(_pickupDate),
        'expected_return_date': DateFormat('yyyy-MM-dd').format(_returnDate),
        'status': 'Pending_HOD',
        'loan_type': 'reservation',
      });

      if (mounted) {
        ref.refresh(inventoryItemsProvider);
        ref.refresh(myLoansProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation request submitted successfully!')),
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

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final initialDate = isPickup ? _pickupDate : _returnDate;
    final firstDate = isPickup ? DateTime.now() : _pickupDate;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          if (_returnDate.isBefore(_pickupDate)) {
            _returnDate = _pickupDate.add(const Duration(days: 1));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(inventoryItemDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve Equipment'),
      ),
      body: detailAsync.when(
        data: (item) => _buildForm(item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildForm(Map<String, dynamic> item) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Info
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item['image_url'] != null
                      ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: Colors.grey))
                      : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['available_quantity']} Available',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form Fields
            const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_quantity > 1) setState(() => _quantity--);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    if (_quantity < item['available_quantity']) setState(() => _quantity++);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    label: 'Pickup Date',
                    date: _pickupDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateSelector(
                    label: 'Return Date',
                    date: _returnDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Purpose of Borrowing', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _purposeController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. For presentation in Room 201...',
              ),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSubmitting || item['available_quantity'] <= 0 
                  ? null 
                  : () => _submit(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF142D55),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Reservation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(DateFormat('MMM d, yyyy').format(date)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
