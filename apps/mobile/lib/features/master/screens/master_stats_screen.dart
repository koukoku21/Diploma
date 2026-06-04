import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';

// ─── Модели ───────────────────────────────────────────────────────
class _DayData {
  const _DayData({required this.date, required this.revenue, required this.bookings});
  final String date;
  final int revenue;
  final int bookings;
  factory _DayData.fromJson(Map<String, dynamic> j) => _DayData(
        date: j['date'] as String,
        revenue: (j['revenue'] as num?)?.toInt() ?? 0,
        bookings: (j['bookings'] as num?)?.toInt() ?? 0,
      );
}

class _PeriodData {
  const _PeriodData({required this.revenue, required this.bookings});
  final int revenue;
  final int bookings;
  factory _PeriodData.fromJson(Map<String, dynamic> j) => _PeriodData(
        revenue: (j['revenue'] as num?)?.toInt() ?? 0,
        bookings: (j['bookings'] as int?) ?? 0,
      );
}

class _Stats {
  const _Stats({
    required this.rating,
    required this.reviewCount,
    required this.week,
    required this.month,
    required this.allTime,
    required this.cancelled,
    required this.dailyChart,
  });
  final double? rating;
  final int reviewCount;
  final _PeriodData week;
  final _PeriodData month;
  final _PeriodData allTime;
  final int cancelled;
  final List<_DayData> dailyChart;

  factory _Stats.fromJson(Map<String, dynamic> j) => _Stats(
        rating: (j['rating'] as num?)?.toDouble(),
        reviewCount: j['reviewCount'] as int? ?? 0,
        week: _PeriodData.fromJson(j['week'] as Map<String, dynamic>),
        month: _PeriodData.fromJson(j['month'] as Map<String, dynamic>),
        allTime: _PeriodData.fromJson(j['allTime'] as Map<String, dynamic>),
        cancelled: (j['allTime'] as Map<String, dynamic>?)?['cancelled'] as int? ?? 0,
        dailyChart: (j['dailyChart'] as List)
            .map((e) => _DayData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Provider ─────────────────────────────────────────────────────
final _statsProvider = FutureProvider.autoDispose<_Stats>((ref) async {
  final res = await createDio().get('/masters/me/stats');
  return _Stats.fromJson(res.data as Map<String, dynamic>);
});

// ─── Экран ────────────────────────────────────────────────────────
class MasterStatsScreen extends ConsumerWidget {
  const MasterStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_statsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.statistics, style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) =>
            Center(child: Text('Ошибка: $e', style: AppTextStyles.body)),
        data: (stats) => _Body(stats: stats),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.stats});
  final _Stats stats;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
      children: [
        // ─── Рейтинг + отзывы ─────────────────────────────────
        Row(children: [
          Expanded(
            child: _StatCard(
              label: context.l10n.ratingLabel,
              value: s.rating != null
                  ? s.rating!.toStringAsFixed(1)
                  : '—',
              icon: Icons.star_rounded,
              iconColor: kGold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              label: context.l10n.reviewsCount,
              value: '${s.reviewCount}',
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: kGold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              label: context.l10n.cancellations,
              value: '${s.cancelled}',
              icon: Icons.cancel_outlined,
              iconColor: kRose,
            ),
          ),
        ]),

        const SizedBox(height: AppSpacing.lg),

        // ─── Период ───────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: context.colors.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: context.colors.border),
          ),
          child: TabBar(
            controller: _tabs,
            labelStyle: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppTextStyles.caption,
            labelColor: context.colors.bgPrimary,
            unselectedLabelColor: context.colors.textSecondary,
            indicator: BoxDecoration(
              color: kGold,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: context.l10n.weekLabel),
              Tab(text: context.l10n.monthLabel),
              Tab(text: context.l10n.allTimeLabel),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ─── Метрики периода ──────────────────────────────────
        AnimatedBuilder(
          animation: _tabs,
          builder: (_, __) {
            final period = switch (_tabs.index) {
              0 => s.week,
              1 => s.month,
              _ => s.allTime,
            };
            return Row(children: [
              Expanded(
                child: _StatCard(
                  label: context.l10n.revenueLabel,
                  value: _fmt(period.revenue),
                  icon: Icons.payments_outlined,
                  iconColor: kGold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  label: context.l10n.bookingsCountLabel,
                  value: '${period.bookings}',
                  icon: Icons.calendar_today_rounded,
                  iconColor: kGold,
                ),
              ),
            ]);
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        // ─── График 7 дней ────────────────────────────────────
        Text(context.l10n.revenueFor7Days, style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.md),
        _BarChart(days: s.dailyChart),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _fmt(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}М ₸';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} тыс ₸';
    }
    return '$amount ₸';
  }
}

// ─── Карточка-метрика ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: AppTextStyles.h1
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary)),
        ],
      ),
    );
  }
}

// ─── Бар-чарт ────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  const _BarChart({required this.days});
  final List<_DayData> days;

  static const _weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final maxRevenue = days.fold(0, (m, d) => d.revenue > m ? d.revenue : m);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final frac = maxRevenue > 0 ? d.revenue / maxRevenue : 0.0;
                final parsedDate = DateTime.tryParse(d.date);
                final isToday = parsedDate != null &&
                    parsedDate.day == DateTime.now().day &&
                    parsedDate.month == DateTime.now().month;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.revenue > 0)
                          Text(
                            _shortFmt(d.revenue),
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: isToday ? kGold : context.colors.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: (frac * 80).clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            color: isToday
                                ? kGold
                                : kGold.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: days.map((d) {
              final parsedDate = DateTime.tryParse(d.date);
              final label = parsedDate != null
                  ? _weekDays[(parsedDate.weekday - 1) % 7]
                  : '?';
              final isToday = parsedDate != null &&
                  parsedDate.day == DateTime.now().day &&
                  parsedDate.month == DateTime.now().month;
              return Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: isToday ? kGold : context.colors.textTertiary,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _shortFmt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}к';
    return '$v';
  }
}
