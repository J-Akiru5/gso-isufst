import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/tokens/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/borrowing_provider.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String id;
  const LoanDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(loanDetailProvider(id));
    final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
    final isGso = roles.contains('gso_staff') || roles.contains('super_admin');
    final isHod = roles.contains('department_head');
    final userId = ref.watch(authProvider).valueOrNull?.id;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(title: const Text('Loan Details')),
      body: loanAsync.when(
        data: (loan) {
          final status = loan['status'] as String? ?? '';
          final borrowerId = loan['borrower_id'] as String?;
          final isBorrower = borrowerId == userId;
          final timeline = loan['timeline'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                _HeaderSection(loan: loan),
                _DetailsCard(loan: loan),
                // ── Role-Based Actions ─────────────────
                _ActionButtons(
                  id: id,
                  status: status,
                  isBorrower: isBorrower,
                  isHod: isHod,
                  isGso: isGso,
                ),
                _TimelineSection(timeline: timeline),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.statusRejected),
                const SizedBox(height: 16),
                Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header Section ────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _HeaderSection({required this.loan});

  @override
  Widget build(BuildContext context) {
    final status = loan['status'] as String? ?? 'Unknown';
    final color = AppColors.statusColor(status);
    final createdAt = DateTime.tryParse(loan['created_at'] ?? '');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              status.replaceAll('_', ' '),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loan['loan_number'] ?? '#---',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutral900),
          ),
          const SizedBox(height: 6),
          Text(
            createdAt != null ? 'Requested on ${DateFormat('MMMM d, y').format(createdAt)}' : '—',
            style: const TextStyle(color: AppColors.neutral500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Details Card ──────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _DetailsCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final item = loan['item'] as Map?;
    final borrower = loan['borrower'] as Map?;
    final returnDate = DateTime.tryParse(loan['expected_return_date'] ?? '');
    final actualReturn = DateTime.tryParse(loan['actual_return_date'] ?? '');
    final isOverdue = returnDate != null && returnDate.isBefore(DateTime.now()) &&
        !['Returned', 'Inspected', 'Closed'].contains(loan['status']);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                    image: item?['image_url'] != null
                        ? DecorationImage(image: NetworkImage(item!['image_url']), fit: BoxFit.cover)
                        : null,
                  ),
                  child: item?['image_url'] == null
                      ? const Icon(Icons.inventory_2, size: 28, color: AppColors.neutral400)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item?['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Qty: ${loan['quantity_borrowed'] ?? 1}', style: const TextStyle(fontSize: 13, color: AppColors.neutral600)),
                      Text('Category: ${(item?['category'] as Map?)?['name'] ?? '—'}', style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(icon: Icons.person_outline, label: 'Borrower', value: borrower?['full_name'] ?? '—'),
                _InfoRow(icon: Icons.info_outline, label: 'Purpose', value: loan['purpose'] ?? '—'),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Expected Return',
                  value: returnDate != null ? DateFormat('MMM d, y').format(returnDate) : '—',
                  valueColor: isOverdue ? AppColors.statusRejected : null,
                  suffix: isOverdue ? '  OVERDUE' : null,
                  suffixColor: AppColors.statusRejected,
                ),
                if (actualReturn != null)
                  _InfoRow(
                    icon: Icons.check_circle_outline,
                    label: 'Returned On',
                    value: DateFormat('MMM d, y').format(actualReturn),
                    valueColor: AppColors.statusCompleted,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons (Role-Based) ───────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final String id;
  final String status;
  final bool isBorrower;
  final bool isHod;
  final bool isGso;
  const _ActionButtons({required this.id, required this.status, required this.isBorrower, required this.isHod, required this.isGso});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref.read(updateLoanStatusProvider({'id': id, 'status': newStatus}).future);
      ref.refresh(loanDetailProvider(id));
      ref.refresh(pendingApprovalsProvider);
      ref.refresh(myLoansProvider);
      if (context.mounted) {
        final isPositive = newStatus.contains('Approved') || newStatus == 'Released' || newStatus == 'Returned';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isPositive ? 'Done! Status updated.' : 'Request rejected.'),
          backgroundColor: isPositive ? AppColors.statusCompleted : AppColors.statusRejected,
        ));
        if (newStatus == 'Cancelled') context.pop();
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
    final List<Widget> buttons = [];

    // Borrower: can cancel while pending
    if (isBorrower && status == 'Pending_HOD') {
      buttons.add(_ActionButton(
        label: 'Cancel Request',
        icon: Icons.cancel_outlined,
        isPrimary: false,
        color: AppColors.statusRejected,
        onTap: () => _updateStatus(context, ref, 'Cancelled'),
      ));
    }

    // HOD: approve/reject pending_hod
    if ((isHod || isGso) && status == 'Pending_HOD') {
      buttons.add(_ActionButton(
        label: 'Reject',
        icon: Icons.thumb_down_outlined,
        isPrimary: false,
        color: AppColors.statusRejected,
        onTap: () => _updateStatus(context, ref, 'HOD_Rejected'),
      ));
      buttons.add(_ActionButton(
        label: 'HOD Approve',
        icon: Icons.thumb_up_outlined,
        isPrimary: true,
        color: AppColors.statusCompleted,
        onTap: () => _updateStatus(context, ref, 'HOD_Approved'),
      ));
    }

    // GSO: release when HOD has approved
    if (isGso && (status == 'HOD_Approved' || status == 'Pending_GSO')) {
      buttons.add(_ActionButton(
        label: 'Reject',
        icon: Icons.thumb_down_outlined,
        isPrimary: false,
        color: AppColors.statusRejected,
        onTap: () => _updateStatus(context, ref, 'GSO_Rejected'),
      ));
      buttons.add(_ActionButton(
        label: 'Release Item',
        icon: Icons.outbox_outlined,
        isPrimary: true,
        color: AppColors.secondary,
        onTap: () => _updateStatus(context, ref, 'Released'),
      ));
    }

    // GSO: mark returned / inspect
    if (isGso && (status == 'Released' || status == 'In_Use')) {
      buttons.add(_ActionButton(
        label: 'Mark Returned',
        icon: Icons.assignment_return_outlined,
        isPrimary: true,
        color: AppColors.statusCompleted,
        onTap: () => _updateStatus(context, ref, 'Returned'),
      ));
    }

    if (isGso && status == 'Returned') {
      buttons.add(_ActionButton(
        label: 'Inspect & Close',
        icon: Icons.verified_outlined,
        isPrimary: true,
        color: AppColors.statusClosed,
        onTap: () => _updateStatus(context, ref, 'Inspected'),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral500, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: buttons
                .map((btn) => Expanded(child: Padding(
                      padding: EdgeInsets.only(left: buttons.indexOf(btn) > 0 ? 8 : 0),
                      child: btn,
                    )))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.isPrimary, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Timeline Section ──────────────────────────────────────────

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
          const Text('TRACKING TIMELINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral500, letterSpacing: 0.5)),
          const SizedBox(height: 20),
          if (timeline.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No timeline events yet', style: TextStyle(color: AppColors.neutral400, fontSize: 13)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final step = timeline[index];
                final isLast = index == timeline.length - 1;
                final date = DateTime.tryParse(step['created_at'] ?? '');
                return _TimelineItem(
                  title: step['title'] ?? 'Updated',
                  subtitle: step['description'] ?? '',
                  date: date != null ? DateFormat('MMM d · h:mm a').format(date.toLocal()) : '—',
                  isLast: isLast,
                  performer: (step['performer'] as Map?)?['full_name'],
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
  const _TimelineItem({required this.title, required this.subtitle, required this.date, required this.isLast, this.performer});

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
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 48, color: AppColors.neutral200),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Text(date, style: const TextStyle(fontSize: 10, color: AppColors.neutral500)),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                ],
                if (performer != null) ...[
                  const SizedBox(height: 2),
                  Text('by $performer', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.neutral400)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? suffix;
  final Color? suffixColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor, this.suffix, this.suffixColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.neutral400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.neutral500, fontSize: 11)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: valueColor ?? AppColors.neutral900)),
                    ),
                    if (suffix != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (suffixColor ?? AppColors.statusRejected).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(suffix!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: suffixColor ?? AppColors.statusRejected)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
