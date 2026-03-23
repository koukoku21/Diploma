import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/master_dashboard_models.dart';

final masterDashboardProvider =
    FutureProvider.autoDispose<MasterDashboard>((ref) async {
  final res = await createDio().get('/masters/dashboard');
  return MasterDashboard.fromJson(res.data as Map<String, dynamic>);
});

final masterBookingsProvider =
    FutureProvider.autoDispose.family<List<MasterBookingItem>, String>((ref, status) async {
  final res = await createDio().get('/bookings/master', queryParameters: {
    if (status != 'all') 'status': status,
  });
  return (res.data as List)
      .map((e) => MasterBookingItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

final masterScheduleProvider =
    FutureProvider.autoDispose<List<ScheduleSlot>>((ref) async {
  final res = await createDio().get('/master/schedule');
  return (res.data as List)
      .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Toggle master active status
class MasterActiveNotifier extends StateNotifier<AsyncValue<bool>> {
  MasterActiveNotifier(bool initial) : super(AsyncValue.data(initial));

  Future<void> toggle(bool value) async {
    state = const AsyncValue.loading();
    try {
      await createDio().patch('/masters/me', data: {'isActive': value});
      state = AsyncValue.data(value);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final masterActiveProvider =
    StateNotifierProvider.autoDispose.family<MasterActiveNotifier, AsyncValue<bool>, bool>(
  (ref, initial) => MasterActiveNotifier(initial),
);
