import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/tokens/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../widgets/travel_status_badge.dart';

class TravelListScreen extends ConsumerWidget {
  const TravelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
    final isGso = roles.contains('gso_staff') || roles.contains('super_admin');
    final listAsync = ref.watch(isGso ? allTravelBookingsProvider : myTravelBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(isGso ? 'Travel Management' : 'Travel Requests')),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isGso) {
            ref.invalidate(allTravelBookingsProvider);
          } else {
            ref.invalidate(myTravelBookingsProvider);
          }
        },
        child: listAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No travel requests yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _TravelCard(item: item, isGso: isGso);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: isGso
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/travel/new'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Travel Request'),
            ),
    );
  }
}

class _TravelCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  final bool isGso;
  const _TravelCard({required this.item, required this.isGso});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = item['status']?.toString() ?? 'Pending';
    final updateStatus = ref.read(updateTravelStatusProvider);
    final depart = DateTime.tryParse(item['departure_time']?.toString() ?? '');
    Future<void> handleStatus(String nextStatus) async {
      try {
        await updateStatus(bookingId: item['id'] as String, status: nextStatus);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request marked as $nextStatus.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed: $e')),
          );
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/travel/${item['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['destination']?.toString() ?? 'No destination',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TravelStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item['booking_number']?.toString() ?? 'Draft request',
                style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
              const SizedBox(height: 6),
              Text(
                depart == null ? '-' : DateFormat('MMM d, y • h:mm a').format(depart.toLocal()),
                style: const TextStyle(color: AppColors.neutral700),
              ),
              if (isGso) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (status == 'Pending')
                      OutlinedButton(
                        onPressed: () => handleStatus('Approved'),
                        child: const Text('Approve'),
                      ),
                    if (status == 'Pending')
                      OutlinedButton(
                        onPressed: () => handleStatus('Rejected'),
                        child: const Text('Reject'),
                      ),
                    OutlinedButton(
                      onPressed: () => context.push('/travel/${item['id']}'),
                      child: const Text('Assign'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
