import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/master_providers.dart';
import '../data/master_dashboard_models.dart';
import '../../../core/widgets/bell_button.dart';
import '../../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';

// M-6: Дашборд мастера
class MasterDashboardScreen extends ConsumerWidget {
  const MasterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(masterDashboardProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text('MIRAKU',
            style: AppTextStyles.title.copyWith(letterSpacing: 4, color: kGold)),
        centerTitle: true,
        actions: const [
          BellButton(),
          SizedBox(width: 12),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (dashboard) => _DashboardBody(dashboard: dashboard),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.dashboard});
  final MasterDashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(masterActiveProvider(dashboard.isActive));
    final isActive = activeState.valueOrNull ?? dashboard.isActive;

    final fmt = NumberFormat('#,##0', 'ru');

    return RefreshIndicator(
      color: kGold,
      backgroundColor: context.colors.bgSecondary,
      onRefresh: () => ref.refresh(masterDashboardProvider.future),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        children: [
          const SizedBox(height: AppSpacing.xl),

          // ─── Тогл context.l10n.acceptingBookings ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.bgSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isActive ? kGold.withValues(alpha: 0.4) : context.colors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? kGold : context.colors.textTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? context.l10n.acceptingBookings : context.l10n.notAcceptingBookings,
                        style: AppTextStyles.label,
                      ),
                      Text(
                        isActive
                            ? context.l10n.visibleInFeedMsg
                            : context.l10n.hiddenFromFeedMsg,
                        style: AppTextStyles.caption
                            .copyWith(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: activeState.isLoading
                      ? null
                      : (v) => ref
                          .read(masterActiveProvider(dashboard.isActive).notifier)
                          .toggle(v),
                  activeColor: kGold,
                  inactiveThumbColor: context.colors.textTertiary,
                  inactiveTrackColor: context.colors.border2,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ─── Следующая запись ──────────────────────────────
          if (dashboard.nextBooking != null) ...[
            Text(context.l10n.nextBooking, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            _NextBookingCard(booking: dashboard.nextBooking!),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ─── Доход ────────────────────────────────────────
          Row(
            children: [
              Text(context.l10n.income, style: AppTextStyles.label),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(AppRoutes.masterStats),
                child: Text(context.l10n.statistics,
                    style: AppTextStyles.caption
                        .copyWith(color: kGold, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _IncomeCard(
                  label: context.l10n.todayLabel,
                  amount: '${fmt.format(dashboard.todayIncome)} ₸',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _IncomeCard(
                  label: context.l10n.thisMonth,
                  amount: '${fmt.format(dashboard.monthIncome)} ₸',
                ),
              ),
            ],
          ),

          if (dashboard.pendingCount > 0) ...[
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: kGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_outlined, color: kGold),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${dashboard.pendingCount} новых запросов на запись',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard({required this.booking});
  final MasterNextBooking booking;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, HH:mm', 'ru');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined, color: kGold, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.clientName, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(booking.serviceName,
                    style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
          Text(fmt.format(booking.startTime),
              style: AppTextStyles.caption.copyWith(color: kGold)),
        ],
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({required this.label, required this.amount});
  final String label;
  final String amount;

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
          Text(label,
              style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text(amount, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }
}
