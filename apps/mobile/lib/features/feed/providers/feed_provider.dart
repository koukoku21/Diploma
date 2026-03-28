import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/feed_models.dart';
import '../data/feed_repository.dart';

// Астана как дефолтные координаты (если нет геолокации)
const _defaultLat = 51.1694;
const _defaultLng = 71.4491;

final feedRepositoryProvider = Provider(
  (ref) => FeedRepository(createDio()),
);

// Фильтры
class FeedFilter {
  const FeedFilter({
    this.serviceTemplateId,
    this.maxPrice,
    this.radius = 5000,
  });
  final String? serviceTemplateId; // ID из ServiceTemplate
  final int? maxPrice;
  final int radius;

  FeedFilter copyWith({
    Object? serviceTemplateId = _sentinel,
    Object? maxPrice = _sentinel,
    int? radius,
  }) =>
      FeedFilter(
        serviceTemplateId: serviceTemplateId == _sentinel
            ? this.serviceTemplateId
            : serviceTemplateId as String?,
        maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as int?,
        radius: radius ?? this.radius,
      );
}

const _sentinel = Object();

final feedFilterProvider = StateProvider((_) => const FeedFilter());

// Карточки в ленте
class FeedState {
  const FeedState({
    this.cards = const [],
    this.hasMore = true,
    this.nextOffset = 0,
    this.loading = false,
  });
  final List<FeedMaster> cards;
  final bool hasMore;
  final int nextOffset;
  final bool loading;

  FeedState copyWith({
    List<FeedMaster>? cards,
    bool? hasMore,
    int? nextOffset,
    bool? loading,
  }) =>
      FeedState(
        cards: cards ?? this.cards,
        hasMore: hasMore ?? this.hasMore,
        nextOffset: nextOffset ?? this.nextOffset,
        loading: loading ?? this.loading,
      );
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier(this._repo) : super(const FeedState());

  final FeedRepository _repo;
  double _lat = _defaultLat;
  double _lng = _defaultLng;
  FeedFilter _filter = const FeedFilter();

  Future<void> init(FeedFilter filter) async {
    _filter = filter;
    final pos = await _repo.getCurrentPosition();
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
    }
    await _load(reset: true);
  }

  Future<void> reload(FeedFilter filter) async {
    _filter = filter;
    await _load(reset: true);
  }

  // Убрать верхнюю карточку (свайп или кнопка ✕)
  void removeTop() {
    if (state.cards.isEmpty) return;
    final remaining = state.cards.sublist(1);
    state = state.copyWith(cards: remaining);
    // Подгружаем ещё если осталось мало
    if (remaining.length <= 3 && state.hasMore) _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    if (state.loading) return;
    state = state.copyWith(loading: true);

    try {
      final res = await _repo.getFeed(
        lat: _lat,
        lng: _lng,
        radius: _filter.radius,
        serviceTemplateId: _filter.serviceTemplateId,
        maxPrice: _filter.maxPrice,
        offset: reset ? 0 : state.nextOffset,
      );

      state = state.copyWith(
        cards: reset ? res.items : [...state.cards, ...res.items],
        hasMore: res.hasMore,
        nextOffset: res.nextOffset,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }
}

final feedProvider =
    StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.watch(feedRepositoryProvider));
});
