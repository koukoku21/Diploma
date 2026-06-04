import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';

// ─── Модель ───────────────────────────────────────────────────────
class _Notif {
  const _Notif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  factory _Notif.fromJson(Map<String, dynamic> j) => _Notif(
        id: j['id'] as String,
        type: j['type'] as String? ?? '',
        title: j['title'] as String,
        body: j['body'] as String,
        isRead: j['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      );
}

// ─── Provider ─────────────────────────────────────────────────────
final _notifProvider = FutureProvider.autoDispose<List<_Notif>>((ref) async {
  final res = await createDio().get('/notifications');
  return (res.data as List)
      .map((e) => _Notif.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Глобальный провайдер для бейджа (unread count)
final unreadCountProvider = FutureProvider<int>((ref) async {
  final res = await createDio().get('/notifications/unread-count');
  return (res.data as Map<String, dynamic>)['count'] as int? ?? 0;
});

// ─── Экран ────────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_notifProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text('Уведомления', style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(
          child: Text(context.l10n.errorLoad, style: AppTextStyles.body),
        ),
        data: (items) {
          // После загрузки сбрасываем бейдж
          ref.invalidate(unreadCountProvider);

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      color: context.colors.textTertiary, size: 64),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет уведомлений',
                      style: AppTextStyles.subtitle
                          .copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Здесь будут появляться уведомления о записях',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(color: context.colors.border, height: 1, indent: 72),
            itemBuilder: (_, i) => _NotifTile(notif: items[i]),
          );
        },
      ),
    );
  }
}

// ─── Плитка уведомления ───────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif});
  final _Notif notif;

  IconData get _icon {
    return switch (notif.type) {
      'NEW_BOOKING' || 'BOOKING_CONFIRMED' => Icons.calendar_today_rounded,
      'BOOKING_REMINDER' || 'BOOKING_REMINDER_MASTER' => Icons.alarm_rounded,
      'BOOKING_CANCELLED_BY_MASTER' ||
      'BOOKING_CANCELLED_BY_CLIENT' =>
        Icons.cancel_outlined,
      'NEW_REVIEW' || 'REVIEW_REQUEST' => Icons.star_rounded,
      'PROFILE_APPROVED' => Icons.check_circle_outline_rounded,
      'PROFILE_REJECTED' => Icons.cancel_outlined,
      'SALON_INVITE' || 'SALON_INVITE_ACCEPTED' => Icons.business_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color get _iconColor {
    return switch (notif.type) {
      'BOOKING_CANCELLED_BY_MASTER' ||
      'BOOKING_CANCELLED_BY_CLIENT' ||
      'PROFILE_REJECTED' =>
        kRose,
      'PROFILE_APPROVED' => kSuccess,
      _ => kGold,
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notif.isRead ? null : kGold.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            )),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: const BoxDecoration(
                              color: kGold, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notif.body,
                      style: AppTextStyles.caption
                          .copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(_timeAgo(notif.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: context.colors.textTertiary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
