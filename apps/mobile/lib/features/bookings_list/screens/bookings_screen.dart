import 'package:cached_network_image/cached_network_image.dart';
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

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clientBookingsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.myBookings, style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text(context.l10n.errorWithDetails(e.toString()), style: AppTextStyles.body)),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: context.colors.textTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text(context.l10n.noBookings, style: AppTextStyles.subtitle.copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(context.l10n.bookWithMasterDesc,
                      style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => context.go('/feed'),
                    child: Text(context.l10n.goToFeed,
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
            backgroundColor: context.colors.bgSecondary,
            onRefresh: () => ref.refresh(clientBookingsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                if (upcoming.isNotEmpty) ...[
                  Text(context.l10n.upcoming, style: AppTextStyles.label.copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  ...upcoming.map((b) => _BookingCard(
                      booking: b,
                      onReview: () => _showReview(context, ref, b),
                      onCancel: () => _confirmCancel(context, ref, b))),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (past.isNotEmpty) ...[
                  Text(context.l10n.completed, style: AppTextStyles.label.copyWith(color: context.colors.textSecondary)),
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
        backgroundColor: context.colors.bgSecondary,
        title: Text(context.l10n.cancelBookingQuestion, style: AppTextStyles.title),
        content: Text(
          context.l10n.bookingToCancelDesc(booking.masterName),
          style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.no, style: AppTextStyles.label.copyWith(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.yesCancelAction, style: AppTextStyles.label.copyWith(color: kRose)),
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
      backgroundColor: context.colors.bgSecondary,
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
    return GestureDetector(
      onTap: () => context.push(AppRoutes.bookingDetail(booking.id)),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          // Фото мастера
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: booking.masterCover != null
                ? CachedNetworkImage(imageUrl: booking.masterCover!,
                    width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56, height: 56, color: context.colors.bgTertiary,
                    child: Icon(Icons.person_outline,
                        color: context.colors.textTertiary, size: 28)),
          ),
          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.masterName, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(booking.serviceName,
                    style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time, size: 12, color: context.colors.textTertiary),
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
                  child: Text(context.l10n.rateAction,
                      style: AppTextStyles.caption.copyWith(color: kGold)),
                ),
              ],
              if (booking.status == BookingStatus.confirmed) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: onCancel,
                  child: Text(context.l10n.cancelAction,
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
      BookingStatus.confirmed => (context.l10n.statusPending, kGold),
      BookingStatus.completed => (context.l10n.statusCompleted, kSuccess),
      BookingStatus.cancelled => (context.l10n.statusCancelled, kRose),
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
