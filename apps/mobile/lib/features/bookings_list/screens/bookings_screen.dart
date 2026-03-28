import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/booking_list_models.dart';
import '../providers/bookings_provider.dart';
import '../widgets/review_sheet.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clientBookingsProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Мои записи', style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e', style: AppTextStyles.body)),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: kTextTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет записей', style: AppTextStyles.subtitle.copyWith(color: kTextSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Запишитесь к мастеру в ленте',
                      style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => context.go('/feed'),
                    child: Text('Перейти в ленту',
                        style: AppTextStyles.label.copyWith(color: kGold)),
                  ),
                ],
              ),
            );
          }

          final upcoming  = bookings.where((b) => b.status == BookingStatus.confirmed).toList();
          final past      = bookings.where((b) => b.status != BookingStatus.confirmed).toList();

          return RefreshIndicator(
            color: kGold,
            backgroundColor: kBgSecondary,
            onRefresh: () => ref.refresh(clientBookingsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                if (upcoming.isNotEmpty) ...[
                  Text('Предстоящие', style: AppTextStyles.label.copyWith(color: kTextSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  ...upcoming.map((b) => _BookingCard(
                      booking: b,
                      onReview: () => _showReview(context, ref, b),
                      onCancel: () => _confirmCancel(context, ref, b))),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (past.isNotEmpty) ...[
                  Text('Завершённые', style: AppTextStyles.label.copyWith(color: kTextSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  ...past.map((b) => _BookingCard(
                      booking: b,
                      onReview: () => _showReview(context, ref, b),
                      onCancel: () {})),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, BookingItem booking) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgSecondary,
        title: Text('Отменить запись?', style: AppTextStyles.title),
        content: Text(
          'Запись к ${booking.masterName} будет отменена.',
          style: AppTextStyles.body.copyWith(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Нет', style: AppTextStyles.label.copyWith(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Да, отменить', style: AppTextStyles.label.copyWith(color: kRose)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(cancelBookingProvider.notifier).cancel(booking.id);
    ref.invalidate(clientBookingsProvider);
  }

  void _showReview(BuildContext context, WidgetRef ref, BookingItem booking) {
    if (booking.status != BookingStatus.completed || booking.hasReview) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => ReviewSheet(
        bookingId: booking.id,
        masterName: booking.masterName,
        onDone: () => ref.refresh(clientBookingsProvider),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onReview,
    required this.onCancel,
  });
  final BookingItem booking;
  final VoidCallback onReview;
  final VoidCallback onCancel;

  static const _months = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String get _dateStr {
    final d = booking.startsAt;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month]}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          // Фото мастера
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: booking.masterCover != null
                ? Image.network(booking.masterCover!,
                    width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56, height: 56, color: kBgTertiary,
                    child: const Icon(Icons.person_outline,
                        color: kTextTertiary, size: 28)),
          ),
          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.masterName, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(booking.serviceName,
                    style: AppTextStyles.body.copyWith(color: kTextSecondary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time, size: 12, color: kTextTertiary),
                  const SizedBox(width: 4),
                  Text(_dateStr, style: AppTextStyles.caption),
                  const Spacer(),
                  Text('${booking.priceSnapshot}₸',
                      style: AppTextStyles.label.copyWith(color: kGold)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusChip(status: booking.status),
              if (booking.status == BookingStatus.completed && !booking.hasReview) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: onReview,
                  child: Text('Оценить',
                      style: AppTextStyles.caption.copyWith(color: kGold)),
                ),
              ],
              if (booking.status == BookingStatus.confirmed) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: onCancel,
                  child: Text('Отменить',
                      style: AppTextStyles.caption.copyWith(color: kRose)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BookingStatus.confirmed => ('Ожидает', kGold),
      BookingStatus.completed => ('Завершено', kSuccess),
      BookingStatus.cancelled => ('Отменено', kRose),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}
