import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';

final _overridesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await createDio().get('/master/schedule/overrides');
  return (res.data as List).cast<Map<String, dynamic>>();
});

// M-8a: Особые дни (заблокировать дату / изменить часы)
class MasterScheduleOverridesScreen extends ConsumerWidget {
  const MasterScheduleOverridesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_overridesProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Особые дни', style: AppTextStyles.title),
        leading: BackButton(color: kTextPrimary, onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kGold),
            onPressed: () => _showAddSheet(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e', style: AppTextStyles.body)),
        data: (overrides) {
          if (overrides.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available_outlined,
                      color: kTextTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет особых дней',
                      style: AppTextStyles.subtitle.copyWith(color: kTextSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Нажмите + чтобы заблокировать дату\nили изменить часы работы',
                      style: AppTextStyles.caption.copyWith(color: kTextTertiary),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            itemCount: overrides.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _OverrideCard(
              item: overrides[i],
              onDelete: () async {
                await createDio()
                    .delete('/master/schedule/overrides/${overrides[i]['id']}');
                // ignore: unused_result
                ref.refresh(_overridesProvider);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _AddOverrideSheet(ref: ref),
    );
  }
}

// ─── Override card ─────────────────────────────────────────────────────────
class _OverrideCard extends StatelessWidget {
  const _OverrideCard({required this.item, required this.onDelete});
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  static const List<String> _months = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ];

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.day} ${_months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDayOff  = item['isDayOff'] as bool? ?? true;
    final dateStr   = item['date'] as String? ?? '';
    final startTime = item['startTime'] as String?;
    final endTime   = item['endTime'] as String?;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDayOff ? kRose.withValues(alpha: 0.3) : kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDayOff
                  ? kRose.withValues(alpha: 0.1)
                  : kGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDayOff ? Icons.block_outlined : Icons.schedule_outlined,
              color: isDayOff ? kRose : kGold,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(dateStr), style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  isDayOff
                      ? 'Выходной день'
                      : 'Изменённые часы: ${startTime ?? ''} – ${endTime ?? ''}',
                  style: AppTextStyles.caption.copyWith(
                      color: isDayOff ? kRose : kTextSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline, color: kTextTertiary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Add override sheet ─────────────────────────────────────────────────────
class _AddOverrideSheet extends StatefulWidget {
  const _AddOverrideSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddOverrideSheet> createState() => _AddOverrideSheetState();
}

class _AddOverrideSheetState extends State<_AddOverrideSheet> {
  DateTime _date    = DateTime.now().add(const Duration(days: 1));
  bool _isDayOff    = true;
  String _startTime = '10:00';
  String _endTime   = '19:00';
  bool _loading     = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kGold, surface: kBgSecondary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = _parseTime(isStart ? _startTime : _endTime);
    final picked  = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kGold, surface: kBgSecondary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final str =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _startTime = str;
      } else {
        _endTime = str;
      }
    });
  }

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmtDate(DateTime d) {
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final dateStr =
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      await createDio().post('/master/schedule/overrides', data: {
        'date': dateStr,
        'isDayOff': _isDayOff,
        if (!_isDayOff) 'startTime': _startTime,
        if (!_isDayOff) 'endTime': _endTime,
      });
      // ignore: unused_result
      widget.ref.refresh(_overridesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: kBgSecondary),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ручка
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                  color: kBorder2, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          Text('Добавить особый день', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),

          // Дата
          Text('Дата', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: kBgTertiary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Text(_fmtDate(_date), style: AppTextStyles.body),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined,
                      color: kTextTertiary, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Тип
          Text('Тип', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDayOff = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _isDayOff ? kRose.withValues(alpha: 0.12) : kBgTertiary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: _isDayOff ? kRose.withValues(alpha: 0.5) : kBorder),
                    ),
                    child: Center(
                      child: Text('Выходной',
                          style: AppTextStyles.label.copyWith(
                              color: _isDayOff ? kRose : kTextSecondary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDayOff = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: !_isDayOff ? kGold.withValues(alpha: 0.12) : kBgTertiary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: !_isDayOff ? kGold.withValues(alpha: 0.5) : kBorder),
                    ),
                    child: Center(
                      child: Text('Другие часы',
                          style: AppTextStyles.label.copyWith(
                              color: !_isDayOff ? kGold : kTextSecondary)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Время (только если не выходной)
          if (!_isDayOff) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Часы работы', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(true),
                    child: _TimeButton(label: 'Начало', time: _startTime),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.arrow_forward, color: kTextTertiary, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(false),
                    child: _TimeButton(label: 'Конец', time: _endTime),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                disabledBackgroundColor: kGold.withValues(alpha: 0.4),
                foregroundColor: kBgPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: kBgPrimary, strokeWidth: 2))
                  : Text('Сохранить',
                      style: AppTextStyles.label
                          .copyWith(fontWeight: FontWeight.w700, color: kBgPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.time});
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: kBgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
          const SizedBox(height: 2),
          Text(time, style: AppTextStyles.label),
        ],
      ),
    );
  }
}
