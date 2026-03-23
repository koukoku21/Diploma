import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/booking_list_models.dart';

final clientBookingsProvider = FutureProvider.autoDispose<List<BookingItem>>((ref) async {
  final dio = createDio();
  final res = await dio.get('/bookings/my');
  return (res.data as List)
      .map((e) => BookingItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Отмена записи
class CancelBookingNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> cancel(String bookingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await createDio().patch('/bookings/$bookingId/cancel', data: {});
    });
  }
}

final cancelBookingProvider =
    AsyncNotifierProvider.autoDispose<CancelBookingNotifier, void>(
        CancelBookingNotifier.new);
