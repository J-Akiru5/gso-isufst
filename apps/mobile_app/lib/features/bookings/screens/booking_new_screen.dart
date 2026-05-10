import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/booking_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../core/tokens/app_colors.dart';

class BookingNewScreen extends ConsumerStatefulWidget {
  const BookingNewScreen({super.key});

  @override
  ConsumerState<BookingNewScreen> createState() => _BookingNewScreenState();
}

class _BookingNewScreenState extends ConsumerState<BookingNewScreen> {
  String? selectedRoomId;
  DateTime startTime = DateTime.now().add(const Duration(days: 1));
  DateTime endTime = DateTime.now().add(const Duration(days: 1, hours: 2));
  PlatformFile? pickedFile;
  final TextEditingController _notesController = TextEditingController();
  bool isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() => pickedFile = result.files.first);
    }
  }

  Future<void> _submitBooking() async {
    if (selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room')),
      );
      return;
    }

    setState(() => isUploading = true);
    try {
      String? attachmentUrl;
      if (pickedFile != null) {
        attachmentUrl = await SupabaseService.uploadBookingAttachment(
          pickedFile!.path!,
          pickedFile!.name,
        );
      }

      await ref.read(bookingProvider.notifier).requestBooking(
            roomId: selectedRoomId!,
            startTime: startTime,
            endTime: endTime,
            attachmentUrl: attachmentUrl,
            notes: _notesController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request submitted successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting booking: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Request Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            roomsAsync.when(
              data: (rooms) => DropdownButtonFormField<String>(
                value: selectedRoomId,
                decoration: const InputDecoration(
                  hintText: 'Choose a room',
                  border: OutlineInputBorder(),
                ),
                items: rooms.map<DropdownMenuItem<String>>((room) {
                  final buildingName = room['buildings']?['name'] ?? 'Unknown';
                  return DropdownMenuItem(
                    value: room['id'],
                    child: Text('$buildingName - ${room['name']}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedRoomId = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading rooms: $e'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(startTime),
                            );
                            if (time != null) {
                              setState(() => startTime = DateTime(
                                date.year, date.month, date.day, time.hour, time.minute
                              ));
                            }
                          }
                        },
                        child: Text(DateFormat('yyyy-MM-dd HH:mm').format(startTime)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endTime),
                            );
                            if (time != null) {
                              setState(() => endTime = DateTime(
                                date.year, date.month, date.day, time.hour, time.minute
                              ));
                            }
                          }
                        },
                        child: Text(DateFormat('yyyy-MM-dd HH:mm').format(endTime)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Attachment (Approval Letter)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: AppColors.neutral100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.upload_file),
              title: Text(pickedFile?.name ?? 'No file selected'),
              trailing: IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _pickFile,
              ),
              onTap: _pickFile,
            ),
            const SizedBox(height: 20),
            const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional details...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isUploading ? null : _submitBooking,
              child: isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
