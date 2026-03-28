import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/token_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';

// ─── Инфраструктура ───────────────────────────────────────────────
final _storageProvider = Provider((_) => TokenStorage());
final _dioProvider     = Provider((_) => createDio());
final _authApiProvider = Provider((ref) => AuthApi(ref.watch(_dioProvider)));

final authRepositoryProvider = Provider((ref) => AuthRepository(
      ref.watch(_authApiProvider),
      ref.watch(_storageProvider),
    ));

// ─── Состояния экранов ────────────────────────────────────────────

// A-2: отправка OTP
class SendOtpNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> send(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendOtp(phone),
    );
  }
}

final sendOtpProvider =
    AsyncNotifierProvider.autoDispose<SendOtpNotifier, void>(SendOtpNotifier.new);

// A-3: верификация OTP
class VerifyOtpState {
  const VerifyOtpState({this.isNewUser = false});
  final bool isNewUser;
}

class VerifyOtpNotifier extends AutoDisposeAsyncNotifier<VerifyOtpState?> {
  @override
  Future<VerifyOtpState?> build() async => null;

  Future<void> verify({
    required String phone,
    required String code,
    String? name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).verifyOtp(
            phone: phone,
            code: code,
            name: name,
          );
      return VerifyOtpState(isNewUser: result.isNewUser);
    });
  }
}

final verifyOtpProvider =
    AsyncNotifierProvider.autoDispose<VerifyOtpNotifier, VerifyOtpState?>(
        VerifyOtpNotifier.new);

// Глобальный статус авторизации
final isLoggedInProvider = FutureProvider((ref) async {
  return ref.watch(authRepositoryProvider).isLoggedIn();
});
