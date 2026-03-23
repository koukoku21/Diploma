class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.isRead = false,
    this.isMe = false,
  });

  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final bool isRead;
  final bool isMe;

  factory ChatMessage.fromJson(Map<String, dynamic> j, {String? myId}) => ChatMessage(
        id: j['id'] as String,
        content: j['content'] as String,
        senderId: j['senderId'] as String,
        senderName: (j['sender'] as Map?)?['name'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        isRead: j['isRead'] as bool? ?? false,
        isMe: myId != null && j['senderId'] == myId,
      );

  ChatMessage copyWith({bool? isMe}) => ChatMessage(
        id: id,
        content: content,
        senderId: senderId,
        senderName: senderName,
        createdAt: createdAt,
        isRead: isRead,
        isMe: isMe ?? this.isMe,
      );
}

class ChatRoom {
  const ChatRoom({
    required this.roomId,
    required this.masterName,
    required this.masterId,
    this.masterCover,
    this.lastMessage,
  });

  final String roomId;
  final String masterName;
  final String masterId;
  final String? masterCover;
  final ChatMessage? lastMessage;

  factory ChatRoom.fromJson(Map<String, dynamic> j) {
    final master = j['master'] as Map<String, dynamic>?;
    final mUser  = master?['user'] as Map<String, dynamic>?;
    final photos = master?['portfolioPhotos'] as List?;
    final lastMsg = j['lastMessage'] as Map<String, dynamic>?;

    return ChatRoom(
      roomId: j['roomId'] as String,
      masterName: mUser?['name'] as String? ?? '',
      masterId: master?['id'] as String? ?? '',
      masterCover: (photos?.isNotEmpty == true)
          ? (photos!.first as Map)['url'] as String? : null,
      lastMessage: lastMsg != null ? ChatMessage.fromJson(lastMsg) : null,
    );
  }
}
