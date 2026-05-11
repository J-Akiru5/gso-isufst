import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/tokens/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(inventoryCategoriesProvider);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final selectedCategory = ref.watch(inventoryCategoryFilterProvider);
    final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
    final isGso = roles.contains('gso_staff') || roles.contains('super_admin');

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      body: Column(
        children: [
          // ── Search ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (val) => ref.read(inventorySearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search equipment, furniture, tools...',
                prefixIcon: const Icon(Icons.search, color: AppColors.neutral500),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ── Category Filter Chips ───────────────────────────
          categoriesAsync.when(
            data: (cats) => Container(
              height: 52,
              margin: const EdgeInsets.symmetric(vertical: 8),
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
            loading: () => const SizedBox(height: 52),
            error: (_, __) => const SizedBox(),
          ),

          // ── Item Grid ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.refresh(inventoryItemsProvider);
                ref.refresh(inventoryCategoriesProvider);
              },
              child: itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
                            child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.neutral400),
                          ),
                          const SizedBox(height: 20),
                          const Text('No items found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.neutral800)),
                          const SizedBox(height: 8),
                          const Text('Try a different search or category', style: TextStyle(fontSize: 13, color: AppColors.neutral500)),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _InventoryCard(item: items[index]),
                  );
                },
                loading: () => Shimmer.fromColors(
                  baseColor: AppColors.neutral200,
                  highlightColor: AppColors.neutral100,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) => Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.statusRejected),
                        const SizedBox(height: 16),
                        Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
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
        label: Text(label, style: const TextStyle(fontSize: 13)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.neutral700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.neutral200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final dynamic item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final available = (item['available_quantity'] as int?) ?? 0;
    final total = (item['quantity'] as int?) ?? 0;
    final isBorrowable = item['is_borrowable'] == true;
    final condition = item['condition'] as String? ?? 'Good';
    final conditionColor = _conditionColor(condition);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/inventory/${item['id']}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ─────────────────────────────────
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        image: item['image_url'] != null
                            ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: item['image_url'] == null
                          ? const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.neutral400)
                          : null,
                    ),
                    // Condition Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: conditionColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: conditionColor.withOpacity(0.4)),
                        ),
                        child: Text(condition, style: TextStyle(color: conditionColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    // Borrowable badge
                    if (isBorrowable)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              // ── Info ─────────────────────────────────
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['category']?['name'] ?? '',
                        style: const TextStyle(fontSize: 9, color: AppColors.neutral500, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['name'] ?? 'Unnamed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: available > 0 ? AppColors.statusCompleted : AppColors.statusRejected,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$available/$total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: available > 0 ? AppColors.statusCompleted : AppColors.statusRejected,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, size: 16, color: AppColors.neutral400),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _conditionColor(String condition) {
    switch (condition) {
      case 'New':
        return AppColors.statusCompleted;
      case 'Good':
        return AppColors.secondary;
      case 'Fair':
        return AppColors.statusPending;
      case 'Poor':
        return AppColors.statusRejected;
      case 'For_Disposal':
        return AppColors.neutral500;
      default:
        return AppColors.neutral500;
    }
  }
}
