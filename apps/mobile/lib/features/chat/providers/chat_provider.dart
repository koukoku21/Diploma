import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../data/chat_models.dart';
import '../../../core/network/dio_client.dart';

// ─── Current user ID (decoded from JWT) ──────────────────────────
String? _parseUserId(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return map['sub'] as String?;
  } catch (_) {
    return null;
  }
}

final currentUserIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');
  if (token == null) return null;
  return _parseUserId(token);
});

// ─── Messages provider ────────────────────────────────────────────
final chatMessagesProvider =
    FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, roomId) async {
  final myId = await ref.watch(currentUserIdProvider.future);
  final res = await createDio().get('/chat/rooms/$roomId/messages');
  return (res.data as List)
      .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>, myId: myId))
      .toList();
});

// ─── WebSocket notifier ───────────────────────────────────────────
class ChatSocketNotifier extends StateNotifier<List<ChatMessage>> {
  ChatSocketNotifier(this.roomId) : super([]);

  final String roomId;
  io.Socket? _socket;
  String? _myId;

  Future<void> connect(List<ChatMessage> history, String? myId) async {
    _myId = myId;
    state = history;

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    _socket = io.io(
      'http://10.0.2.2:3000/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join_room', {'roomId': roomId});
    });

    _socket!.on('new_message', (data) {
      final msg = ChatMessage.fromJson(data as Map<String, dynamic>, myId: _myId);
      state = [...state, msg];
    });
  }

  void send(String content) {
    _socket?.emit('send_message', {'roomId': roomId, 'content': content});
  }

  void sendTyping() {
    _socket?.emit('typing', {'roomId': roomId});
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}

final chatSocketProvider =
    StateNotifierProvider.autoDispose.family<ChatSocketNotifier, List<ChatMessage>, String>(
  (ref, roomId) => ChatSocketNotifier(roomId),
);
