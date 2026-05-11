import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/tokens/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../widgets/travel_status_badge.dart';

class TravelDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const TravelDetailScreen({super.key, required this.id});

  @override
  ConsumerState<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends ConsumerState<TravelDetailScreen> {
  String? _selectedVehicleId;
  String? _selectedDriverId;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(travelDetailProvider(widget.id));
    final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
    final isGso = roles.contains('gso_staff') || roles.contains('super_admin');
    final isDriver = roles.contains('driver');

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Request Detail')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (item) {
          final status = item['status']?.toString() ?? 'Pending';
          final departure = DateTime.tryParse(item['departure_time']?.toString() ?? '');
          final returnTime = DateTime.tryParse(item['return_time']?.toString() ?? '');
          final updateStatus = ref.read(updateTravelStatusProvider);
          final assign = ref.read(assignTravelBookingProvider);
          final vehiclesAsync = ref.watch(vehiclesProvider);
          final driversAsync = ref.watch(driverProfilesProvider);
          final canDriverStart = isDriver && status == 'Scheduled';
          final canDriverEnd = isDriver && status == 'Ongoing';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['destination']?.toString() ?? 'No destination',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TravelStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['booking_number']?.toString() ?? '',
                style: const TextStyle(color: AppColors.neutral500),
              ),
              const SizedBox(height: 16),
              _infoTile('Purpose', item['purpose']?.toString() ?? '-'),
              _infoTile('Departure', departure == null ? '-' : DateFormat('MMM d, y h:mm a').format(departure.toLocal())),
              _infoTile('Return', returnTime == null ? '-' : DateFormat('MMM d, y h:mm a').format(returnTime.toLocal())),
              _infoTile('Passengers', '${item['passenger_count'] ?? 0}'),
              _infoTile('Passenger Names', item['passenger_names']?.toString() ?? '-'),
              _infoTile('Requester', item['requester']?['full_name']?.toString() ?? '-'),
              _infoTile('Driver', item['driver']?['full_name']?.toString() ?? '-'),
              _infoTile('Vehicle', _vehicleLabel(item['vehicle'])),
              if (isGso) ...[
                const SizedBox(height: 18),
                const Text('GSO Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (status == 'Pending')
                      OutlinedButton(
                        onPressed: () => updateStatus(bookingId: widget.id, status: 'Approved'),
                        child: const Text('Approve'),
                      ),
                    if (status == 'Pending')
                      OutlinedButton(
                        onPressed: () => updateStatus(bookingId: widget.id, status: 'Rejected'),
                        child: const Text('Reject'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                vehiclesAsync.when(
                  data: (vehicles) => DropdownButtonFormField<String>(
                    value: _selectedVehicleId,
                    decoration: const InputDecoration(labelText: 'Assign Vehicle'),
                    items: vehicles
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v['id'].toString(),
                            child: Text('${v['plate_number'] ?? '-'} • ${v['brand'] ?? ''} ${v['model'] ?? ''}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedVehicleId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                driversAsync.when(
                  data: (drivers) => DropdownButtonFormField<String>(
                    value: _selectedDriverId,
                    decoration: const InputDecoration(labelText: 'Assign Driver'),
                    items: drivers
                        .map(
                          (d) => DropdownMenuItem<String>(
                            value: d['id'].toString(),
                            child: Text(d['full_name']?.toString() ?? 'Unknown'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedDriverId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: (_selectedDriverId == null && _selectedVehicleId == null)
                      ? null
                      : () => assign(
                            bookingId: widget.id,
                            driverId: _selectedDriverId,
                            vehicleId: _selectedVehicleId,
                          ),
                  child: const Text('Assign & Schedule'),
                ),
              ],
              if (canDriverStart || canDriverEnd) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => updateStatus(
                    bookingId: widget.id,
                    status: canDriverStart ? 'Ongoing' : 'Completed',
                  ),
                  icon: Icon(canDriverStart ? Icons.play_arrow : Icons.check),
                  child: Text(canDriverStart ? 'Start Trip' : 'End Trip'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _vehicleLabel(dynamic vehicle) {
    if (vehicle is! Map) return '-';
    return '${vehicle['plate_number'] ?? '-'} • ${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''}'.trim();
  }
}
