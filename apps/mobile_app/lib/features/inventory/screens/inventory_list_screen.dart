import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/inventory_provider.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(inventoryCategoriesProvider);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final selectedCategory = ref.watch(inventoryCategoryFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inventory Items', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => ref.read(inventorySearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search equipment, tools, furniture...',
                prefixIcon: const Icon(Icons.search, color: AppColors.neutral500),
                filled: true,
                fillColor: AppColors.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Categories
          categoriesAsync.when(
            data: (cats) => Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: cats.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      label: 'All',
                      isSelected: selectedCategory == null,
                      onTap: () => ref.read(inventoryCategoryFilterProvider.notifier).state = null,
                    );
                  }
                  final cat = cats[index - 1];
                  return _CategoryChip(
                    label: cat['name'],
                    isSelected: selectedCategory == cat['id'],
                    onTap: () => ref.read(inventoryCategoryFilterProvider.notifier).state = cat['id'],
                  );
                },
              ),
            ),
            loading: () => const SizedBox(height: 50),
            error: (_, __) => const SizedBox(),
          ),

          // Items Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(inventoryItemsProvider),
              child: itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No items found', style: TextStyle(color: AppColors.neutral500)));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _InventoryCard(item: item);
                    },
                  );
                },
                loading: () => const Center(child: _ShimmerGrid()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary600,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.neutral700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppColors.neutral100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final dynamic item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final available = item['available_quantity'] ?? 0;
    final total = item['quantity'] ?? 0;
    final isBorrowable = item['is_borrowable'] ?? false;

    return GestureDetector(
      onTap: () => context.push('/inventory/${item['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: item['image_url'] != null
                      ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover)
                      : null,
                ),
                child: item['image_url'] == null
                    ? const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.neutral400)
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Unnamed Item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category']?['name'] ?? 'Uncategorized',
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$available / $total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: available > 0 ? AppColors.success600 : AppColors.statusUrgent,
                        ),
                      ),
                      if (isBorrowable)
                        const Icon(Icons.event_available, size: 16, color: AppColors.primary600),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    // Placeholder for shimmer grid - I'll keep it simple for now or use a proper shimmer
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
