import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tokens/app_colors.dart';
import '../providers/travel_provider.dart';

class DriverVehicleScreen extends ConsumerWidget {
  const DriverVehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(driverTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicle')),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trips) {
          final assigned = trips.cast<Map<String, dynamic>>().firstWhere(
                (trip) => trip['vehicle'] != null,
                orElse: () => {},
              );
          final vehicle = assigned['vehicle'];

          if (vehicle == null || vehicle is! Map) {
            return const Center(child: Text('No vehicle assigned yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Vehicle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _row('Plate Number', vehicle['plate_number']?.toString() ?? '-'),
                      _row('Brand', vehicle['brand']?.toString() ?? '-'),
                      _row('Model', vehicle['model']?.toString() ?? '-'),
                      _row('Status', vehicle['status']?.toString() ?? 'Assigned'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vehicle details are based on your currently assigned trip.',
                style: TextStyle(color: AppColors.neutral500),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.neutral500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
