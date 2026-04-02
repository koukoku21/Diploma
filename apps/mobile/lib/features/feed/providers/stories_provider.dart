import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/feed_models.dart';

class StoriesState {
  const StoriesState({
    this.items = const [],
    this.loading = false,
    this.viewedIds = const {},
  });

  final List<StoryItem> items;
  final bool loading;
  final Set<String> viewedIds;

  StoriesState copyWith({
    List<StoryItem>? items,
    bool? loading,
    Set<String>? viewedIds,
  }) =>
      StoriesState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        viewedIds: viewedIds ?? this.viewedIds,
      );
}

class StoriesNotifier extends StateNotifier<StoriesState> {
  StoriesNotifier() : super(const StoriesState());

  final _dio = createDio();

  Future<void> load({required double lat, required double lng, int radiusKm = 10}) async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final res = await _dio.get('/stories/feed', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
      });
      final list = (res.data as List)
          .map((e) => StoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: list, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> markViewed(String storyId) async {
    if (state.viewedIds.contains(storyId)) return;
    state = state.copyWith(viewedIds: {...state.viewedIds, storyId});
    try {
      await _dio.post('/stories/$storyId/view');
    } catch (_) {}
  }
}

final storiesProvider =
    StateNotifierProvider<StoriesNotifier, StoriesState>((_) => StoriesNotifier());
