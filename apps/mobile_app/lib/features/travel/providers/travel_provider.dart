import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

final myTravelBookingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return [];
  return SupabaseService.getMyTravelBookings(user.id);
});

final allTravelBookingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final roles = ref.watch(userRolesProvider).valueOrNull ?? [];
  final isGso = roles.contains('gso_staff') || roles.contains('super_admin');
  if (!isGso) return [];
  return SupabaseService.getAllTravelBookings();
});

final driverTripsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return [];
  return SupabaseService.getDriverTrips(user.id);
});

final vehiclesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getVehicles();
});

final driverProfilesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getDriverProfiles();
});

final travelDetailProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, id) async {
  return SupabaseService.getTravelBooking(id);
});

final createTravelBookingProvider = Provider.autoDispose<Future<String> Function(Map<String, dynamic>)>((ref) {
  return (payload) async {
    final id = await SupabaseService.createTravelBooking(payload);
    ref.invalidate(myTravelBookingsProvider);
    ref.invalidate(allTravelBookingsProvider);
    return id;
  };
});

final updateTravelStatusProvider = Provider.autoDispose<Future<void> Function({
  required String bookingId,
  required String status,
})>((ref) {
  return ({required String bookingId, required String status}) async {
    await SupabaseService.updateTravelBookingStatus(
      bookingId: bookingId,
      status: status,
    );
    ref.invalidate(myTravelBookingsProvider);
    ref.invalidate(allTravelBookingsProvider);
    ref.invalidate(driverTripsProvider);
    ref.invalidate(travelDetailProvider(bookingId));
  };
});

final assignTravelBookingProvider = Provider.autoDispose<Future<void> Function({
  required String bookingId,
  String? driverId,
  String? vehicleId,
})>((ref) {
  return ({required String bookingId, String? driverId, String? vehicleId}) async {
    await SupabaseService.assignTravelBooking(
      bookingId: bookingId,
      driverId: driverId,
      vehicleId: vehicleId,
    );
    ref.invalidate(myTravelBookingsProvider);
    ref.invalidate(allTravelBookingsProvider);
    ref.invalidate(driverTripsProvider);
    ref.invalidate(travelDetailProvider(bookingId));
  };
});

final upsertVehicleProvider = Provider.autoDispose<Future<void> Function(Map<String, dynamic>)>((ref) {
  return (vehicle) async {
    await SupabaseService.upsertVehicle(vehicle);
    ref.invalidate(vehiclesProvider);
  };
});

final updateVehicleStatusProvider = Provider.autoDispose<Future<void> Function({
  required String vehicleId,
  required String status,
})>((ref) {
  return ({required String vehicleId, required String status}) async {
    await SupabaseService.updateVehicleStatus(vehicleId: vehicleId, status: status);
    ref.invalidate(vehiclesProvider);
  };
});
