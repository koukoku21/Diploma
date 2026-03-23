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

// C-4: Шаг 2/3 — Выбор даты и времени
class SlotSelectScreen extends ConsumerStatefulWidget {
  const SlotSelectScreen({
    super.key,
    required this.master,
    required this.service,
  });
  final MasterProfile master;
  final MasterService service;

  @override
  ConsumerState<SlotSelectScreen> createState() => _SlotSelectScreenState();
}

class _SlotSelectScreenState extends ConsumerState<SlotSelectScreen> {
  late DateTime _selectedDate;
  String? _selectedTime;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = today;
    _dates = List.generate(14, (i) => today.add(Duration(days: i)));
  }

  String get _dateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(slotsProvider((
      masterId: widget.master.id,
      date: _dateStr,
      serviceId: widget.service.id,
    )));

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Column(
          children: [
            Text('Выберите время', style: AppTextStyles.title),
            Text('Шаг 2 из 3',
                style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Чип услуги
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: kGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(widget.service.title,
                      style: AppTextStyles.label.copyWith(color: kGold)),
                  const Spacer(),
                  Text('${widget.service.durationMin} мин · от ${widget.service.priceFrom}₸',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          ),

          // Горизонтальный скроллер дат
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final d = _dates[i];
                final selected = d.day == _selectedDate.day &&
                    d.month == _selectedDate.month;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = d;
                    _selectedTime = null;
                  }),
                  child: _DateCell(date: d, selected: selected),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Слоты времени
          Expanded(
            child: slotsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: kGold)),
              error: (e, _) => Center(
                  child: Text('Ошибка загрузки слотов',
                      style:
                          AppTextStyles.body.copyWith(color: kTextSecondary))),
              data: (result) {
                if (result.isDayOff || result.slots.isEmpty) {
                  return Center(
                    child: Text('Нет свободного времени',
                        style: AppTextStyles.body
                            .copyWith(color: kTextSecondary)),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: result.slots.length,
                  itemBuilder: (_, i) {
                    final t = result.slots[i];
                    final sel = t == _selectedTime;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTime = t),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? kGold : kBgSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          border: Border.all(
                              color: sel ? kGold : kBorder),
                        ),
                        child: Text(
                          t,
                          style: AppTextStyles.label.copyWith(
                              color: sel ? kBgPrimary : kTextPrimary,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Кнопка
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: PrimaryButton(
              label: 'Продолжить',
              enabled: _selectedTime != null,
              onPressed: () => context.push(
                AppRoutes.bookingConfirm,
                extra: (
                  master: widget.master,
                  service: widget.service,
                  date: _dateStr,
                  time: _selectedTime!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({required this.date, required this.selected});
  final DateTime date;
  final bool selected;

  static const _weekdays = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  static const _months = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: selected ? kGold : kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: selected ? kGold : kBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekdays[date.weekday % 7],
            style: AppTextStyles.caption.copyWith(
              color: selected ? kBgPrimary : kTextSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            '${date.day}',
            style: AppTextStyles.subtitle.copyWith(
              color: selected ? kBgPrimary : kTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            _months[date.month],
            style: AppTextStyles.caption.copyWith(
              color: selected ? kBgPrimary : kTextSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
