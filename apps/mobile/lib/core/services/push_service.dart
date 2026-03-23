import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';

/// Обработчик фоновых push (top-level функция — требование FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Фоновое уведомление — Flutter обрабатывает само отображение через FCM
}

class PushService {
  PushService._();

  /// Вызывается один раз в main() до runApp.
  /// Если firebase не настроен (нет google-services.json) — молча пропускает.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Запрашиваем разрешение (iOS/macOS)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Регистрируем токен если пользователь уже авторизован
      await _registerToken(messaging);

      // Обновляем токен при его ротации
      messaging.onTokenRefresh.listen(_sendTokenToServer);

      // Foreground уведомления — показываем как banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Можно показать in-app SnackBar или overlay
        // Пока полагаемся на system notification
      });
    } catch (_) {
      // Firebase не инициализирован (нет google-services.json) — пропускаем
    }
  }

  static Future<void> _registerToken(FirebaseMessaging messaging) async {
    const storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'access_token');
    if (accessToken == null) return; // Пользователь не авторизован

    final fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      await _sendTokenToServer(fcmToken);
    }
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      await createDio().post('/notifications/token', data: {
        'token': token,
        'platform': _platform,
      });
    } catch (_) {
      // Токен отправим позже при следующем запуске
    }
  }

  static String get _platform {
    // Определяется в runtime
    try {
      return const bool.fromEnvironment('dart.library.io') ? 'android' : 'ios';
    } catch (_) {
      return 'android';
    }
  }
}
