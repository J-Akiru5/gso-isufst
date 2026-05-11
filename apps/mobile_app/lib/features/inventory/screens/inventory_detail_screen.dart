import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/inventory_provider.dart';

class InventoryDetailScreen extends ConsumerWidget {
  final String id;
  const InventoryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemDetailProvider(id));

    return Scaffold(
      backgroundColor: Colors.white,
      body: itemAsync.when(
        data: (item) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppColors.primary600,
              flexibleSpace: FlexibleSpaceBar(
                background: item['image_url'] != null
                    ? Image.network(item['image_url'], fit: BoxFit.cover)
                    : Container(
                        color: AppColors.neutral100,
                        child: const Icon(Icons.inventory_2, size: 80, color: AppColors.neutral400),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? 'Item Details',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item['category']?['name'] ?? 'Uncategorized',
                                style: const TextStyle(color: AppColors.neutral500, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(available: item['available_quantity'] ?? 0),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _InfoSection(title: 'Description', content: item['description'] ?? 'No description provided.'),
                    const Divider(height: 32),
                    
                    const Text('Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    _SpecRow(label: 'Item Code', value: item['item_code'] ?? '—'),
                    _SpecRow(label: 'Model', value: item['model'] ?? '—'),
                    _SpecRow(label: 'Manufacturer', value: item['manufacturer'] ?? '—'),
                    _SpecRow(label: 'Serial No.', value: item['serial_number'] ?? '—'),
                    _SpecRow(label: 'Condition', value: item['condition'] ?? 'Good'),
                    
                    const Divider(height: 32),
                    const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    _SpecRow(label: 'Building', value: item['building']?['name'] ?? '—'),
                    _SpecRow(label: 'Room', value: item['room']?['name'] ?? '—'),
                    _SpecRow(label: 'Detail', value: item['location_detail'] ?? '—'),
                    
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomSheet: itemAsync.when(
        data: (item) => (item['is_borrowable'] == true && (item['available_quantity'] ?? 0) > 0)
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: ElevatedButton(
                  onPressed: () => context.push('/borrowing/new?itemId=$id'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Borrow Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int available;
  const _StatusBadge({required this.available});

  @override
  Widget build(BuildContext context) {
    final isAvailable = available > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.success50.withOpacity(0.5) : AppColors.statusUrgent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAvailable ? AppColors.success600 : AppColors.statusUrgent),
      ),
      child: Text(
        isAvailable ? 'AVAILABLE ($available)' : 'OUT OF STOCK',
        style: TextStyle(
          color: isAvailable ? AppColors.success700 : AppColors.statusUrgent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  const _InfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(color: AppColors.neutral600, height: 1.5)),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.neutral500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
