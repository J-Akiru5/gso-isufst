import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/tokens/app_colors.dart';
import '../providers/travel_provider.dart';
import '../widgets/travel_status_badge.dart';

class DriverTripsScreen extends ConsumerWidget {
  const DriverTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(driverTripsProvider);
    final updateStatus = ref.read(updateTravelStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(driverTripsProvider),
        child: tripsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (trips) {
            if (trips.isEmpty) return const Center(child: Text('No assigned trips.'));
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final todayEnd = todayStart.add(const Duration(days: 1));
            Map<String, dynamic>? todayTrip;
            final upcoming = <Map<String, dynamic>>[];
            final past = <Map<String, dynamic>>[];

            for (final trip in trips) {
              final depart = DateTime.tryParse(trip['departure_time']?.toString() ?? '');
              if (depart == null) continue;
              final local = depart.toLocal();
              if (local.isAfter(todayStart) && local.isBefore(todayEnd) && todayTrip == null) {
                todayTrip = trip;
              } else if (local.isAfter(now)) {
                upcoming.add(trip);
              } else {
                past.add(trip);
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (todayTrip != null) ...[
                  const Text('Today\'s Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  _TripCard(
                    trip: todayTrip,
                    showActions: true,
                    onStart: () => updateStatus(bookingId: todayTrip!['id'] as String, status: 'Ongoing'),
                    onEnd: () => updateStatus(bookingId: todayTrip!['id'] as String, status: 'Completed'),
                    onMaps: () => _openInMaps(todayTrip!['destination']?.toString()),
                  ),
                  const SizedBox(height: 18),
                ],
                const Text('Upcoming Trips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                if (upcoming.isEmpty)
                  const Text('No upcoming trips.', style: TextStyle(color: AppColors.neutral500)),
                ...upcoming.map((t) => _TripCard(trip: t)),
                const SizedBox(height: 18),
                const Text('Past Trips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                if (past.isEmpty)
                  const Text('No past trips.', style: TextStyle(color: AppColors.neutral500)),
                ...past.map((t) => _TripCard(trip: t)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openInMaps(String? destination) async {
    if (destination == null || destination.trim().isEmpty) return;
    final encoded = Uri.encodeComponent(destination);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic>? trip;
  final bool showActions;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onMaps;

  const _TripCard({
    required this.trip,
    this.showActions = false,
    this.onStart,
    this.onEnd,
    this.onMaps,
  });

  @override
  Widget build(BuildContext context) {
    if (trip == null) return const SizedBox.shrink();
    final item = trip!;
    final status = item['status']?.toString() ?? 'Scheduled';
    final depart = DateTime.tryParse(item['departure_time']?.toString() ?? '');
    final canStart = status == 'Scheduled';
    final canEnd = status == 'Ongoing';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/driver/trips/${item['id']}'),
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
                      item['destination']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TravelStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(item['booking_number']?.toString() ?? '-', style: const TextStyle(color: AppColors.neutral500)),
              const SizedBox(height: 4),
              Text(
                depart == null ? '-' : DateFormat('MMM d, y • h:mm a').format(depart.toLocal()),
                style: const TextStyle(color: AppColors.neutral700),
              ),
              if (showActions) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onMaps,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Open in Maps'),
                    ),
                    if (canStart)
                      ElevatedButton(
                        onPressed: onStart,
                        child: const Text('Start Trip'),
                      ),
                    if (canEnd)
                      ElevatedButton(
                        onPressed: onEnd,
                        child: const Text('End Trip'),
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
