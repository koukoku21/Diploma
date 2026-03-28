import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'feed_models.dart';

class FeedRepository {
  FeedRepository(this._dio);
  final Dio _dio;

  Future<FeedResponse> getFeed({
    required double lat,
    required double lng,
    int radius = 5000,
    String? serviceTemplateId,
    int? maxPrice,
    int offset = 0,
  }) async {
    final res = await _dio.get('/feed', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      if (serviceTemplateId != null) 'serviceTemplateId': serviceTemplateId,
      if (maxPrice != null) 'maxPrice': maxPrice,
      'offset': offset,
    });
    return FeedResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) { return null; }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
