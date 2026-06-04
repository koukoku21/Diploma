import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';
import '../data/chat_models.dart';

final _chatRoomsProvider = FutureProvider.autoDispose<List<ChatRoom>>((ref) async {
  final res = await createDio().get('/chat/rooms');
  return (res.data as List)
      .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
      .toList();
});

// C-10: Список чатов
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_chatRoomsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.chats, style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, color: context.colors.textTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет чатов', style: AppTextStyles.subtitle.copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Добавьте мастера в избранное\nчтобы начать переписку',
                      style: AppTextStyles.caption, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kGold,
            backgroundColor: context.colors.bgSecondary,
            onRefresh: () => ref.refresh(_chatRoomsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: rooms.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: context.colors.border, indent: 80),
              itemBuilder: (_, i) => _RoomTile(
                room: rooms[i],
                onTap: () => context.push(
                  AppRoutes.chat(rooms[i].roomId),
                  extra: (masterName: rooms[i].masterName),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.onTap});
  final ChatRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: context.colors.bgTertiary,
        backgroundImage:
            room.masterCover != null ? NetworkImage(room.masterCover!) : null,
        child: room.masterCover == null
            ? Icon(Icons.person_outline, color: context.colors.textTertiary)
            : null,
      ),
      title: Text(room.masterName, style: AppTextStyles.label),
      subtitle: room.lastMessage != null
          ? Text(
              room.lastMessage!.content,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(context.l10n.noChats,
              style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary)),
      trailing: Icon(Icons.chevron_right, color: context.colors.textTertiary, size: 20),
    );
  }
}
