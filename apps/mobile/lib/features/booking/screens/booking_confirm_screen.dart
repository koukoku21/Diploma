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
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Column(
          children: [
            Text('Подтверждение', style: AppTextStyles.title),
            Text('Шаг 3 из 3',
                style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
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
                color: kBgSecondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: kBgTertiary,
                    foregroundImage:
                        master.avatarUrl != null ? NetworkImage(master.avatarUrl!) : null,
                    child: const Icon(Icons.person, color: kTextTertiary),
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
            _DetailRow(label: 'Услуга', value: service.title),
            _DetailRow(label: 'Дата', value: _dateLabel),
            _DetailRow(label: 'Время', value: time),
            _DetailRow(
                label: 'Длительность', value: '${service.durationMin} мин'),
            _DetailRow(
                label: 'Стоимость',
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
                      'Оплата мастеру наличными или Kaspi QR',
                      style:
                          AppTextStyles.caption.copyWith(color: kTextSecondary),
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
                  'Не удалось создать запись. Попробуйте ещё раз.',
                  style: AppTextStyles.caption.copyWith(color: kRose),
                  textAlign: TextAlign.center,
                ),
              ),

            PrimaryButton(
              label: 'Записаться',
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
        content: Text('Запись создана! Ждём вас $date в $time',
            style: AppTextStyles.caption.copyWith(color: kTextPrimary)),
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
              style: AppTextStyles.body.copyWith(color: kTextSecondary)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.label
                  .copyWith(color: valueColor ?? kTextPrimary)),
        ],
      ),
    );
  }
}
