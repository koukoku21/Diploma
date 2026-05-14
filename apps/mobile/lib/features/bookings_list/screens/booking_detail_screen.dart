import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../data/booking_list_models.dart';
import '../providers/bookings_provider.dart';
import '../widgets/review_sheet.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: kBgPrimary,
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Column(children: [
          AppBar(backgroundColor: kBgPrimary),
          Center(child: Text('Ошибка: $e', style: AppTextStyles.body)),
        ]),
        data: (b) => _Body(booking: b, bookingId: bookingId),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.booking, required this.bookingId});
  final BookingDetail booking;
  final String bookingId;

  static const _months = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];
  static const _weekdays = ['', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  String get _dateStr {
    final d = booking.startsAt;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month]}, ${_weekdays[d.weekday]}  •  $h:$m';
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
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
            child: Text('Нет',
                style: AppTextStyles.label.copyWith(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Да, отменить',
                style: AppTextStyles.label.copyWith(color: kRose)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(cancelBookingProvider.notifier).cancel(bookingId);
    if (context.mounted) context.pop();
  }

  void _review(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => ReviewSheet(
        bookingId: bookingId,
        masterName: booking.masterName,
        onDone: () => ref.invalidate(bookingDetailProvider(bookingId)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel = booking.status == BookingStatus.confirmed;
    final canReview = booking.status == BookingStatus.completed && !booking.hasReview;
    final canBookAgain = booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelled;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: kBgPrimary,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kBgPrimary.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  color: kTextPrimary, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: booking.masterCover != null
                ? Image.network(booking.masterCover!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _CoverPlaceholder())
                : const _CoverPlaceholder(),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Мастер + статус
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.masterName, style: AppTextStyles.title),
                        if (booking.masterRating != null)
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                color: kGold, size: 16),
                            const SizedBox(width: 4),
                            Text(booking.masterRating!.toStringAsFixed(1),
                                style: AppTextStyles.body
                                    .copyWith(color: kTextSecondary)),
                          ]),
                      ],
                    ),
                  ),
                  _StatusChip(status: booking.status),
                ]),
                const SizedBox(height: AppSpacing.xl),

                // Услуга
                _InfoCard(
                  icon: Icons.content_cut_rounded,
                  label: 'Услуга',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.serviceName, style: AppTextStyles.label),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('${booking.durationMin} мин',
                            style: AppTextStyles.body
                                .copyWith(color: kTextSecondary)),
                        const SizedBox(width: 12),
                        Text('${booking.priceSnapshot} ₸',
                            style: AppTextStyles.label.copyWith(color: kGold)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Дата и время
                _InfoCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Дата и время',
                  child: Text(_dateStr, style: AppTextStyles.label),
                ),
                const SizedBox(height: AppSpacing.md),

                // Адрес
                if (booking.masterAddress != null) ...[
                  _InfoCard(
                    icon: Icons.location_on_rounded,
                    label: 'Адрес',
                    child: Text(booking.masterAddress!,
                        style: AppTextStyles.body
                            .copyWith(color: kTextSecondary)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Причина отмены
                if (booking.status == BookingStatus.cancelled &&
                    booking.cancelReason != null) ...[
                  _InfoCard(
                    icon: Icons.info_outline_rounded,
                    label: 'Причина отмены',
                    child: Text(booking.cancelReason!,
                        style: AppTextStyles.body
                            .copyWith(color: kTextSecondary)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Мой отзыв
                if (booking.hasReview && booking.reviewRating != null) ...[
                  _InfoCard(
                    icon: Icons.star_rounded,
                    label: 'Мой отзыв',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (i) => Icon(
                            i < booking.reviewRating!
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: i < booking.reviewRating!
                                ? kGold
                                : kTextTertiary,
                            size: 18,
                          )),
                        ),
                        if (booking.reviewText?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(booking.reviewText!,
                              style: AppTextStyles.body
                                  .copyWith(color: kTextSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Оставить отзыв
                if (canReview)
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () => _review(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: kBgPrimary,
                        shape: const StadiumBorder(),
                      ),
                      child: Text('Оставить отзыв',
                          style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w700, color: kBgPrimary)),
                    ),
                  ),
                if (canReview) const SizedBox(height: AppSpacing.md),

                // Записаться снова
                if (canBookAgain) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.push(
                          AppRoutes.masterPublicProfile(booking.masterId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: kBgPrimary,
                        shape: const StadiumBorder(),
                      ),
                      child: Text('Записаться снова',
                          style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w700, color: kBgPrimary)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Профиль мастера
                OutlinedButton(
                  onPressed: () => context.push(
                      AppRoutes.masterPublicProfile(booking.masterId)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGold,
                    side: const BorderSide(color: kGold),
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: Text('Открыть профиль мастера',
                      style: AppTextStyles.label.copyWith(color: kGold)),
                ),

                // Отменить запись
                if (canCancel) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: OutlinedButton(
                      onPressed: () => _cancel(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kRose,
                        side: const BorderSide(color: kRose),
                        shape: const StadiumBorder(),
                      ),
                      child: Text('Отменить запись',
                          style: AppTextStyles.label.copyWith(color: kRose)),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.child});
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kGold, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: kTextTertiary)),
                const SizedBox(height: 4),
                child,
              ],
            ),
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
      BookingStatus.confirmed => ('Предстоит', kGold),
      BookingStatus.completed => ('Завершено', kSuccess),
      BookingStatus.cancelled => ('Отменено', kRose),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgSecondary,
      child: const Center(
        child: Icon(Icons.person_outline, color: kTextTertiary, size: 64),
      ),
    );
  }
}
