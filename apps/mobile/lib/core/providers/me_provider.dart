import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../features/profile/data/profile_models.dart';

final meProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final res = await createDio().get('/users/me');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});
