import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class FavouritesNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> toggle(String masterId, bool isFav) async {
    final dio = createDio();
    try {
      if (isFav) {
        await dio.delete('/favourites/$masterId');
        return false;
      } else {
        await dio.post('/favourites/$masterId');
        return true;
      }
    } catch (_) {
      return isFav;
    }
  }
}

final favouritesProvider =
    AsyncNotifierProvider.autoDispose<FavouritesNotifier, void>(
        FavouritesNotifier.new);
