import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/booking_models.dart';

// Слоты для выбранной даты
final slotsProvider = FutureProvider.autoDispose
    .family<SlotResult, ({String masterId, String date, String serviceId})>(
  (ref, args) async {
    final dio = createDio();
    final res = await dio.get(
      '/masters/${args.masterId}/slots',
      queryParameters: {'date': args.date, 'serviceId': args.serviceId},
    );
    return SlotResult.fromJson(res.data as Map<String, dynamic>);
  },
);

// Создание записи
class CreateBookingNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null;

  Future<void> create({
    required String masterId,
    required String serviceId,
    required String date,
    required String time,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = createDio();
      final res = await dio.post('/bookings', data: {
        'masterId': masterId,
        'serviceId': serviceId,
        'date': date,
        'time': time,
      });
      return res.data as Map<String, dynamic>;
    });
  }
}

final createBookingProvider = AsyncNotifierProvider.autoDispose<
    CreateBookingNotifier, Map<String, dynamic>?>(CreateBookingNotifier.new);
