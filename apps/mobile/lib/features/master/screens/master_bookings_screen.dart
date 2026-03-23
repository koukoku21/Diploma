import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';
import '../providers/master_providers.dart';
import '../data/master_dashboard_models.dart';

// M-7: Список записей мастера
class MasterBookingsScreen extends ConsumerStatefulWidget {
  const MasterBookingsScreen({super.key});

  @override
  ConsumerState<MasterBookingsScreen> createState() => _MasterBookingsScreenState();
}

class _MasterBookingsScreenState extends ConsumerState<MasterBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Записи', style: AppTextStyles.title),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: kGold,
          labelColor: kGold,
          unselectedLabelColor: kTextSecondary,
          labelStyle: AppTextStyles.label,
          tabs: const [
            Tab(text: 'Предстоящие'),
            Tab(text: 'Завершённые'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BookingsList(status: 'PENDING', ref: ref),
          _BookingsList(status: 'COMPLETED', ref: ref),
        ],
      ),
    );
  }
}

class _BookingsList extends ConsumerWidget {
  const _BookingsList({required this.status, required this.ref});
  final String status;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final async = widgetRef.watch(masterBookingsProvider(status));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: kTextTertiary, size: 56),
                const SizedBox(height: AppSpacing.md),
                Text('Нет записей',
                    style: AppTextStyles.subtitle.copyWith(color: kTextSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: kGold,
          backgroundColor: kBgSecondary,
          onRefresh: () => widgetRef.refresh(masterBookingsProvider(status).future),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: bookings.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: kBorder, indent: 16, endIndent: 16),
            itemBuilder: (_, i) =>
                _MasterBookingTile(booking: bookings[i], ref: widgetRef),
          ),
        );
      },
    );
  }
}

class _MasterBookingTile extends StatelessWidget {
  const _MasterBookingTile({required this.booking, required this.ref});
  final MasterBookingItem booking;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, HH:mm', 'ru');
    final isPending = booking.status == 'PENDING';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
      leading: CircleAvatar(
        backgroundColor: kBgTertiary,
        child: Text(
          booking.clientName.isNotEmpty ? booking.clientName[0] : '?',
          style: AppTextStyles.label,
        ),
      ),
      title: Text(booking.clientName, style: AppTextStyles.label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(booking.serviceName,
              style: AppTextStyles.caption.copyWith(color: kTextSecondary)),
          Text(fmt.format(booking.startTime),
              style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
        ],
      ),
      trailing: isPending
          ? _ActionMenu(booking: booking, ref: ref)
          : Text(
              '${(booking.price).toStringAsFixed(0)} ₸',
              style: AppTextStyles.label.copyWith(color: kGold),
            ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.booking, required this.ref});
  final MasterBookingItem booking;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: kBgSecondary,
      icon: const Icon(Icons.more_vert, color: kTextSecondary),
      onSelected: (v) async {
        if (v == 'complete') {
          await createDio().patch('/bookings/${booking.id}/complete');
          // ignore: unused_result
          ref.refresh(masterBookingsProvider('PENDING'));
          // ignore: unused_result
          ref.refresh(masterBookingsProvider('COMPLETED'));
        } else if (v == 'cancel') {
          await createDio().patch('/bookings/${booking.id}/cancel',
              data: {'cancelledBy': 'MASTER'});
          // ignore: unused_result
          ref.refresh(masterBookingsProvider('PENDING'));
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'complete',
          child: Text('Завершить', style: AppTextStyles.body),
        ),
        PopupMenuItem(
          value: 'cancel',
          child: Text('Отменить',
              style: AppTextStyles.body.copyWith(color: kRose)),
        ),
      ],
    );
  }
}
