import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/booking_provider.dart';
import '../../../core/tokens/app_colors.dart';
import 'booking_new_screen.dart';

class BookingListScreen extends ConsumerWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/bookings/new'),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          final appointments = bookings.map((b) {
            return Appointment(
              startTime: DateTime.parse(b['start_time']),
              endTime: DateTime.parse(b['end_time']),
              subject: '${b['rooms']?['name']} - ${b['status']}',
              color: _getStatusColor(b['status']),
            );
          }).toList();

          return Column(
            children: [
              SizedBox(
                height: 400,
                child: SfCalendar(
                  view: CalendarView.month,
                  dataSource: MeetingDataSource(appointments),
                  monthViewSettings: const MonthViewSettings(
                    showAgenda: true,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('${b['rooms']?['name']}'),
                        subtitle: Text(
                          '${DateFormat('MMM dd, HH:mm').format(DateTime.parse(b['start_time']))} - ${DateFormat('HH:mm').format(DateTime.parse(b['end_time']))}',
                        ),
                        trailing: _buildStatusChip(b['status']),
                        onTap: () async {
                          if (b['attachment_url'] != null) {
                            final url = Uri.parse(b['attachment_url']);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
