import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tokens/app_colors.dart';
import '../providers/travel_provider.dart';

class FleetManagementScreen extends ConsumerWidget {
  const FleetManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final updateStatus = ref.read(updateVehicleStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Management')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(vehiclesProvider),
        child: vehiclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (vehicles) {
            if (vehicles.isEmpty) return const Center(child: Text('No vehicles found.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                final status = v['status']?.toString() ?? 'Available';
                final isAvailable = status.toLowerCase() == 'available';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      '${v['plate_number'] ?? '-'} • ${v['brand'] ?? ''} ${v['model'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: isAvailable ? AppColors.statusCompleted : AppColors.statusPending,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(status),
                        ],
                      ),
                    ),
                    trailing: Switch(
                      value: isAvailable,
                      onChanged: (val) => updateStatus(
                        vehicleId: v['id'].toString(),
                        status: val ? 'Available' : 'Unavailable',
                      ),
                    ),
                    onTap: () => _showVehicleDialog(context, ref, initial: v),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  Future<void> _showVehicleDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? initial}) async {
    final plateCtrl = TextEditingController(text: initial?['plate_number']?.toString() ?? '');
    final brandCtrl = TextEditingController(text: initial?['brand']?.toString() ?? '');
    final modelCtrl = TextEditingController(text: initial?['model']?.toString() ?? '');
    String status = initial?['status']?.toString() ?? 'Available';
    final formKey = GlobalKey<FormState>();
    final upsert = ref.read(upsertVehicleProvider);

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(initial == null ? 'Add Vehicle' : 'Edit Vehicle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: plateCtrl,
                  decoration: const InputDecoration(labelText: 'Plate Number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Available', child: Text('Available')),
                    DropdownMenuItem(value: 'Unavailable', child: Text('Unavailable')),
                    DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                  ],
                  onChanged: (value) => setState(() => status = value ?? 'Available'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                await upsert({
                  if (initial != null) 'id': initial['id'],
                  'plate_number': plateCtrl.text.trim(),
                  'brand': brandCtrl.text.trim(),
                  'model': modelCtrl.text.trim(),
                  'status': status,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
