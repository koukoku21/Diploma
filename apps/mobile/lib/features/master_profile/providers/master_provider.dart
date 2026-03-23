import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/master_models.dart';

final masterProfileProvider =
    FutureProvider.autoDispose.family<MasterProfile, String>((ref, masterId) async {
  final dio = createDio();
  final res = await dio.get('/masters/$masterId');
  return MasterProfile.fromJson(res.data as Map<String, dynamic>);
});
