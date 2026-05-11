import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/travel_provider.dart';
import '../widgets/travel_status_badge.dart';

class DriverScheduleScreen extends ConsumerWidget {
  const DriverScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(driverTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Schedule')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(driverTripsProvider),
        child: tripsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (trips) {
            final now = DateTime.now();
            final upcoming = trips.where((trip) {
              final depart = DateTime.tryParse(trip['departure_time']?.toString() ?? '');
              return depart != null && depart.toLocal().isAfter(now);
            }).toList();

            if (upcoming.isEmpty) {
              return const Center(child: Text('No scheduled trips.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: upcoming.length,
              itemBuilder: (context, index) {
                final trip = upcoming[index];
                final depart = DateTime.tryParse(trip['departure_time']?.toString() ?? '');
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(trip['destination']?.toString() ?? '-'),
                    subtitle: Text(
                      depart == null ? '-' : DateFormat('EEE, MMM d • h:mm a').format(depart.toLocal()),
                    ),
                    trailing: TravelStatusBadge(status: trip['status']?.toString() ?? 'Scheduled'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
