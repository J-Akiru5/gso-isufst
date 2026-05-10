import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';

// ── Booking State ───────────────────────────────────────────────

class BookingNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return SupabaseService.getMyBookings();
  }

  Future<void> requestBooking({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    String? attachmentUrl,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.createBooking({
        'user_id': SupabaseService.currentUserId,
        'room_id': roomId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'attachment_url': attachmentUrl,
        'notes': notes,
        'status': 'pending',
      });
      return SupabaseService.getMyBookings();
    });
  }
}

final bookingProvider = AsyncNotifierProvider<BookingNotifier, List<Map<String, dynamic>>>(() {
  return BookingNotifier();
});

// ── Admin Bookings ──────────────────────────────────────────────

final adminBookingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getAllBookings();
});

final roomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getRooms();
});

final updateBookingProvider = Provider.autoDispose<Future<void> Function({required String bookingId, required String status, String? approvedBy})>((ref) {
  return ({required String bookingId, required String status, String? approvedBy}) async {
    await SupabaseService.updateBookingStatus(
      bookingId: bookingId,
      status: status,
      approvedBy: approvedBy,
    );
    ref.invalidate(adminBookingsProvider);
  };
});
