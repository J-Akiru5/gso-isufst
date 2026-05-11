import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../core/tokens/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/borrowing_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

/// Root screen for `/borrowing` — adapts tabs based on user role.
class BorrowingRootScreen extends ConsumerStatefulWidget {
  const BorrowingRootScreen({super.key});

  @override
  ConsumerState<BorrowingRootScreen> createState() => _BorrowingRootScreenState();
}

class _BorrowingRootScreenState extends ConsumerState<BorrowingRootScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
    final isGso = roles.contains('gso_staff') || roles.contains('super_admin');
    final isHod = roles.contains('department_head');
    final isTechnician = roles.contains('technician');
    final canApprove = isGso || isHod;
    // Technicians see My Loans + Browse (read-only). No approval tab.
    final tabCount = canApprove ? 3 : 2;

    if (_tabController.length != tabCount) {
      _tabController.dispose();
      // This is handled by the state rebuild correctly since we recreate
    }

    return DefaultTabController(
      length: canApprove ? 3 : 2,
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        appBar: AppBar(
          title: const Text('Borrowing'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.neutral500,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              const Tab(text: 'My Loans'),
              Tab(text: isTechnician ? 'Browse' : 'Browse & Reserve'),
              if (canApprove) Tab(text: isGso ? 'Management' : 'Approvals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyLoansTab(),
            _BrowseEquipmentTab(viewOnly: isTechnician),
            if (canApprove) _ApprovalsTab(isGso: isGso),
          ],
        ),
      ),
    );
  }
}

// ── My Loans Tab ──────────────────────────────────────────────

class _MyLoansTab extends ConsumerWidget {
  const _MyLoansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myLoansProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myLoansProvider),
      child: loansAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return _BorrowingEmptyState(
              icon: Icons.history_outlined,
              title: 'No borrowing history',
              subtitle: 'Browse available equipment and submit a borrow request.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _LoanListItem(loan: loans[i]),
          );
        },
        loading: () => _LoanListShimmer(),
        error: (e, _) => _ErrorState(message: e.toString()),
      ),
    );
  }
}

// ── Browse & Reserve Tab ─────────────────────────────────────

class _BrowseEquipmentTab extends ConsumerStatefulWidget {
  final bool viewOnly;
  const _BrowseEquipmentTab({this.viewOnly = false});

  @override
  ConsumerState<_BrowseEquipmentTab> createState() => _BrowseEquipmentTabState();
}

class _BrowseEquipmentTabState extends ConsumerState<_BrowseEquipmentTab> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(inventoryCategoriesProvider);
    final itemsAsync = ref.watch(borrowableItemsProvider); // borrowable only
    final selectedCat = ref.watch(inventoryCategoryFilterProvider);

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            onChanged: (v) => ref.read(inventorySearchQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'Search borrowable items...',
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
        // Category filter
        categoriesAsync.when(
          data: (cats) => Container(
            height: 52,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: cats.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _CategoryChip(
                    label: 'All',
                    isSelected: selectedCat == null,
                    onTap: () => ref.read(inventoryCategoryFilterProvider.notifier).state = null,
                  );
                }
                final cat = cats[i - 1];
                return _CategoryChip(
                  label: cat['name'],
                  isSelected: selectedCat == cat['id'],
                  onTap: () => ref.read(inventoryCategoryFilterProvider.notifier).state = cat['id'],
                );
              },
            ),
          ),
          loading: () => const SizedBox(height: 52),
          error: (_, __) => const SizedBox(),
        ),
        // Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.refresh(borrowableItemsProvider);
              ref.refresh(inventoryCategoriesProvider);
            },
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _BorrowingEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No borrowable items',
                    subtitle: 'Check back later or contact GSO.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _BorrowableItemCard(
                    item: items[i],
                    viewOnly: widget.viewOnly,
                  ),
                );
              },
              loading: () => _GridShimmer(),
              error: (e, _) => _ErrorState(message: e.toString()),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Approvals Tab ─────────────────────────────────────────────

class _ApprovalsTab extends ConsumerWidget {
  final bool isGso;
  const _ApprovalsTab({required this.isGso});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingApprovalsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(pendingApprovalsProvider),
      child: pendingAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return _BorrowingEmptyState(
              icon: Icons.check_circle_outline,
              title: 'No pending approvals',
              subtitle: 'All loan requests have been processed.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _ApprovalCard(loan: loans[i], isGso: isGso),
          );
        },
        loading: () => _LoanListShimmer(),
        error: (e, _) => _ErrorState(message: e.toString()),
      ),
    );
  }
}

// ── Approval Card ─────────────────────────────────────────────

class _ApprovalCard extends ConsumerWidget {
  final dynamic loan;
  final bool isGso;
  const _ApprovalCard({required this.loan, required this.isGso});

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref.read(updateLoanStatusProvider({
        'id': loan['id'],
        'status': newStatus,
      }).future);
      ref.refresh(pendingApprovalsProvider);
      if (context.mounted) {
        final isApproval = newStatus.contains('Approved') || newStatus == 'Released';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isApproval ? 'Approved successfully' : 'Rejected'),
          backgroundColor: isApproval ? AppColors.statusCompleted : AppColors.statusRejected,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusRejected),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = loan['item'] as Map?;
    final borrower = loan['borrower'] as Map?;
    final status = loan['status'] ?? '';

    // Determine available actions
    final List<({String label, String newStatus, bool isPrimary})> actions = [];
    if (status == 'Pending_HOD' && !isGso) {
      actions.add((label: 'Reject', newStatus: 'HOD_Rejected', isPrimary: false));
      actions.add((label: 'Approve', newStatus: 'HOD_Approved', isPrimary: true));
    } else if (isGso) {
      if (status == 'HOD_Approved' || status == 'Pending_GSO') {
        actions.add((label: 'Reject', newStatus: 'GSO_Rejected', isPrimary: false));
        actions.add((label: 'Release Item', newStatus: 'Released', isPrimary: true));
      } else if (status == 'Released' || status == 'In_Use') {
        actions.add((label: 'Mark Returned', newStatus: 'Returned', isPrimary: true));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/borrowing/${loan['id']}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      loan['loan_number'] ?? '#---',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    ),
                    const Spacer(),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(item?['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.neutral500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        borrower?['full_name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if ((loan['purpose'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.neutral500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          loan['purpose'],
                          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: actions.map((action) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: action == actions.first ? 0 : 8),
                        child: action.isPrimary
                            ? ElevatedButton(
                                onPressed: () => _handleAction(context, ref, action.newStatus),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusCompleted,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 40),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(action.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              )
                            : OutlinedButton(
                                onPressed: () => _handleAction(context, ref, action.newStatus),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.statusRejected,
                                  side: const BorderSide(color: AppColors.statusRejected),
                                  minimumSize: const Size(0, 40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(action.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared: Loan List Item ────────────────────────────────────

class _LoanListItem extends StatelessWidget {
  final dynamic loan;
  const _LoanListItem({required this.loan});

  @override
  Widget build(BuildContext context) {
    final item = loan['item'] as Map?;
    final status = loan['status'] as String? ?? 'Pending';
    final date = DateTime.tryParse(loan['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('MMM d, y').format(date) : '—';
    final returnDate = DateTime.tryParse(loan['expected_return_date'] ?? '');
    final returnStr = returnDate != null ? DateFormat('MMM d, y').format(returnDate) : '—';
    final isOverdue = returnDate != null && returnDate.isBefore(DateTime.now()) && !['Returned', 'Inspected', 'Closed'].contains(status);

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
            border: Border.all(color: isOverdue ? AppColors.statusRejected.withOpacity(0.4) : AppColors.neutral200),
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.neutral400),
                        const SizedBox(width: 4),
                        Text('Requested $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                      ],
                    ),
                    if (isOverdue) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.statusRejected),
                          const SizedBox(width: 4),
                          Text('Overdue — due $returnStr', style: const TextStyle(fontSize: 11, color: AppColors.statusRejected, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared: Status Badge ───────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Shared: Borrowable Item Card ─────────────────────────────

class _BorrowableItemCard extends StatelessWidget {
  final dynamic item;
  final bool viewOnly;
  const _BorrowableItemCard({required this.item, this.viewOnly = false});

  @override
  Widget build(BuildContext context) {
    final available = (item['available_quantity'] as int?) ?? 0;
    final isAvailable = available > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          if (!viewOnly && isAvailable) {
            context.push('/borrowing/new?itemId=${item['id']}');
          } else {
            context.push('/inventory/${item['id']}');
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                    if (!isAvailable)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: const Center(
                          child: Text('OUT OF STOCK',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['category']?['name'] ?? '',
                      style: const TextStyle(fontSize: 10, color: AppColors.neutral500, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isAvailable ? AppColors.statusCompleted : AppColors.statusRejected,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAvailable ? '$available Available' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? AppColors.statusCompleted : AppColors.statusRejected,
                          ),
                        ),
                        if (!viewOnly && isAvailable) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Borrow', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────

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

// ── Empty State ───────────────────────────────────────────────

class _BorrowingEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _BorrowingEmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.neutral400),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.neutral800)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.statusRejected),
            const SizedBox(height: 16),
            const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────

class _LoanListShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
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
    );
  }
}

class _GridShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral200,
      highlightColor: AppColors.neutral100,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
