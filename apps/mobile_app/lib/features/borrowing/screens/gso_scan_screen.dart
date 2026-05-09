import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/features/borrowing/providers/borrowing_provider.dart';

class GsoScanScreen extends ConsumerStatefulWidget {
  const GsoScanScreen({super.key});

  @override
  ConsumerState<GsoScanScreen> createState() => _GsoScanScreenState();
}

class _GsoScanScreenState extends ConsumerState<GsoScanScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _scannedLoan;

  Future<void> _processCode(String code) async {
    if (code.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      // Look for a loan associated with this item code that needs action
      // Either Pending_GSO/Approved (needs release) or Active (needs return)
      final response = await supabase
          .from('equipment_loans')
          .select('*, item:inventory_items(*), borrower:profiles!equipment_loans_borrower_id_fkey(full_name)')
          .eq('item.item_code', code)
          .inFilter('status', ['Approved', 'Active'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active or approved loans found for this item code.')),
          );
        }
      } else {
        setState(() => _scannedLoan = response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLoanStatus(String newStatus) async {
    if (_scannedLoan == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.from('equipment_loans').update({
        'status': newStatus,
        if (newStatus == 'Returned') 'actual_return_date': DateTime.now().toIso8601String(),
        if (newStatus == 'Active') 'actual_pickup_date': DateTime.now().toIso8601String(),
      }).eq('id', _scannedLoan!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item successfully ${newStatus == 'Active' ? 'released' : 'returned'}!')),
        );
        setState(() {
          _scannedLoan = null;
          _codeController.clear();
        });
        ref.refresh(inventoryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Equipment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mock Scanner Area
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Positioned(
                    bottom: 16,
                    child: Text(
                      'Camera preview goes here\n(Requires scanner package)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Manual Entry Fallback
            const Text('Or enter item code manually:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. ISUFST-GSO-001',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _processCode,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _processCode(_codeController.text),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lookup'),
                ),
              ],
            ),
            
            const Divider(height: 48),

            // Action Area
            if (_scannedLoan != null) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Item: ${_scannedLoan!['item']['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Borrower: ${_scannedLoan!['borrower']['full_name']}'),
                      Text('Current Status: ${_scannedLoan!['status'].replaceAll('_', ' ')}'),
                      const SizedBox(height: 24),
                      if (_scannedLoan!['status'] == 'Approved')
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _updateLoanStatus('Active'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF142D55),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Release Item to Borrower'),
                        )
                      else if (_scannedLoan!['status'] == 'Active')
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _updateLoanStatus('Returned'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Confirm Item Return'),
                        ),
                    ],
                  ),
                ),
              ),
            ] else if (!_isLoading && _codeController.text.isNotEmpty) ...[
              const Center(child: Text('Scan an item to view actions', style: TextStyle(color: Colors.grey))),
            ]
          ],
        ),
      ),
    );
  }
}
