import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../master_profile/data/master_models.dart';
import '../providers/booking_provider.dart';

// C-5: Шаг 3/3 — Подтверждение записи
class BookingConfirmScreen extends ConsumerWidget {
  const BookingConfirmScreen({
    super.key,
    required this.master,
    required this.service,
    required this.date,
    required this.time,
  });

  final MasterProfile master;
  final MasterService service;
  final String date;
  final String time;

  static const _months = [
    '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];

  String get _dateLabel {
    final d = DateTime.parse(date);
    return '${d.day} ${_months[d.month]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBookingProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Column(
          children: [
            Text(context.l10n.confirmationTitle, style: AppTextStyles.title),
            Text('Шаг 3 из 3',
                style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Карточка мастера
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.bgSecondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: context.colors.bgTertiary,
                    backgroundImage: master.avatarUrl != null
                        ? NetworkImage(master.avatarUrl!)
                        : null,
                    child: master.avatarUrl == null
                        ? Icon(Icons.person, color: context.colors.textTertiary)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(master.name, style: AppTextStyles.subtitle),
                      Text(master.address,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Детали записи
            _DetailRow(label: context.l10n.serviceLabel, value: service.title),
            _DetailRow(label: context.l10n.dateLabel, value: _dateLabel),
            _DetailRow(label: context.l10n.timeLabel, value: time),
            _DetailRow(
                label: context.l10n.durationLabel, value: '${service.durationMin} мин'),
            _DetailRow(
                label: context.l10n.costLabel,
                value: 'от ${service.priceFrom}₸',
                valueColor: kGold),

            const SizedBox(height: AppSpacing.lg),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: kGold.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: kGold, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.paymentNote,
                      style:
                          AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Ошибка: выбранное время уже занято',
                  style: AppTextStyles.caption.copyWith(color: kRose),
                  textAlign: TextAlign.center,
                ),
              ),

            PrimaryButton(
              label: context.l10n.bookBtn,
              loading: state.isLoading,
              onPressed: () => _confirm(context, ref),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    await ref.read(createBookingProvider.notifier).create(
          masterId: master.id,
          serviceId: service.id,
          date: date,
          time: time,
        );

    final state = ref.read(createBookingProvider);
    if (!context.mounted) return;

    if (state.hasError) return;

    // Успех → возвращаемся в ленту
    context.go(AppRoutes.feed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.bookingCreated(date, time),
            style: AppTextStyles.caption.copyWith(color: context.colors.textPrimary)),
        backgroundColor: kSuccess.withValues(alpha: 0.2),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.label
                  .copyWith(color: valueColor ?? context.colors.textPrimary)),
        ],
      ),
    );
  }
}
