import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';
import '../data/chat_models.dart';

final _masterChatRoomsProvider =
    FutureProvider.autoDispose<List<ChatRoom>>((ref) async {
  final res = await createDio().get('/chat/rooms');
  return (res.data as List)
      .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
      .toList();
});

// M-13: Чаты мастера с клиентами
class MasterChatsScreen extends ConsumerWidget {
  const MasterChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_masterChatRoomsProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Сообщения', style: AppTextStyles.title),
        leading: BackButton(
            color: kTextPrimary, onPressed: () => Navigator.pop(context)),
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: kTextTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет сообщений',
                      style: AppTextStyles.subtitle
                          .copyWith(color: kTextSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Клиенты смогут написать вам\nпосле добавления в избранное',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kGold,
            backgroundColor: kBgSecondary,
            onRefresh: () => ref.refresh(_masterChatRoomsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: rooms.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: kBorder, indent: 80),
              itemBuilder: (_, i) {
                final room = rooms[i];
                final name = room.clientName ?? 'Клиент';
                final avatar = room.clientAvatarUrl;
                return ListTile(
                  onTap: () => context.push(
                    AppRoutes.chat(room.roomId),
                    extra: (masterName: name),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH,
                      vertical: AppSpacing.sm),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: kBgTertiary,
                    backgroundImage:
                        avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? const Icon(Icons.person_outline,
                            color: kTextTertiary)
                        : null,
                  ),
                  title: Text(name, style: AppTextStyles.label),
                  subtitle: room.lastMessage != null
                      ? Text(
                          room.lastMessage!.content,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text('Нет сообщений',
                          style: AppTextStyles.caption
                              .copyWith(color: kTextTertiary)),
                  trailing: const Icon(Icons.chevron_right,
                      color: kTextTertiary, size: 20),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
