import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/booking_provider.dart';
import '../../../core/tokens/app_colors.dart';

class SSCBookingAdminScreen extends ConsumerWidget {
  const SSCBookingAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(adminBookingsProvider);
    final updateBooking = ref.watch(updateBookingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Approvals')),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No booking requests found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              final isPending = b['status'] == 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            b['profiles']?['full_name'] ?? 'Unknown User',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          _buildStatusChip(b['status']),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Room: ${b['rooms']?['name']} (${b['buildings']?['name']})'),
                      Text('Time: ${b['start_time']} to ${b['end_time']}'),
                      if (b['notes'] != null) Text('Notes: ${b['notes']}'),
                      const SizedBox(height: 12),
                      if (b['attachment_url'] != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description),
                          title: const Text('View Approval Letter'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () async {
                            final url = Uri.parse(b['attachment_url']);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                      if (isPending)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _showStatusDialog(context, ref, updateBooking, b['id'], 'rejected'),
                              child: const Text('Reject', style: TextStyle(color: AppColors.statusRejected)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _showStatusDialog(context, ref, updateBooking, b['id'], 'approved'),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, WidgetRef ref, 
      Future<void> Function({required String bookingId, required String status, String? approvedBy}) updateBooking, 
      String bookingId, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm ${status == 'approved' ? 'Approval' : 'Rejection'}'),
        content: Text('Are you sure you want to mark this booking as $status?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              updateBooking(
                bookingId: bookingId,
                status: status,
                approvedBy: SupabaseService.currentUserId,
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: _getStatusColor(status).withOpacity(0.2),
      side: BorderSide(color: _getStatusColor(status)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.statusCompleted;
      case 'rejected': return AppColors.statusRejected;
      case 'cancelled': return AppColors.statusClosed;
      default: return AppColors.statusPending;
    }
  }
}
