import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/travel_provider.dart';
import '../widgets/travel_status_badge.dart';

class DriverTripDetailScreen extends ConsumerWidget {
  final String id;
  const DriverTripDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(travelDetailProvider(id));
    final updateStatus = ref.read(updateTravelStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Detail')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (item) {
          final status = item['status']?.toString() ?? 'Scheduled';
          final departure = DateTime.tryParse(item['departure_time']?.toString() ?? '');
          final returnTime = DateTime.tryParse(item['return_time']?.toString() ?? '');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['destination']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TravelStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),
              Text(item['booking_number']?.toString() ?? ''),
              const SizedBox(height: 16),
              _row('Departure', departure == null ? '-' : DateFormat('MMM d, y • h:mm a').format(departure.toLocal())),
              _row('Return', returnTime == null ? '-' : DateFormat('MMM d, y • h:mm a').format(returnTime.toLocal())),
              _row('Purpose', item['purpose']?.toString() ?? '-'),
              _row('Passengers', '${item['passenger_count'] ?? 0}'),
              _row('Passenger Names', item['passenger_names']?.toString() ?? '-'),
              _row('Requester', item['requester']?['full_name']?.toString() ?? '-'),
              _row('Vehicle', '${item['vehicle']?['plate_number'] ?? '-'} • ${item['vehicle']?['brand'] ?? ''} ${item['vehicle']?['model'] ?? ''}'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openInMaps(item['destination']?.toString()),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open in Maps'),
              ),
              const SizedBox(height: 8),
              if (status == 'Scheduled')
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await updateStatus(bookingId: id, status: 'Ongoing');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trip started.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to start trip: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Trip'),
                ),
              if (status == 'Ongoing')
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await updateStatus(bookingId: id, status: 'Completed');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trip completed.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to complete trip: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('End Trip'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
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
