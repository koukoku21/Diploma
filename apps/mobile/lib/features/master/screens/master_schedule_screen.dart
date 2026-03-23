import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/network/dio_client.dart';
import '../providers/master_providers.dart';
import '../data/master_dashboard_models.dart';

const _dayNames = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

// M-8: Расписание мастера
class MasterScheduleScreen extends ConsumerStatefulWidget {
  const MasterScheduleScreen({super.key});

  @override
  ConsumerState<MasterScheduleScreen> createState() =>
      _MasterScheduleScreenState();
}

class _MasterScheduleScreenState extends ConsumerState<MasterScheduleScreen> {
  List<ScheduleSlot>? _local;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(masterScheduleProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Расписание', style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (slots) {
          _local ??= List.from(slots);
          return _ScheduleEditor(
            slots: _local!,
            saving: _saving,
            onChanged: (updated) => setState(() => _local = updated),
            onSave: () => _save(_local!),
          );
        },
      ),
    );
  }

  Future<void> _save(List<ScheduleSlot> slots) async {
    setState(() => _saving = true);
    try {
      await createDio().put('/master/schedule', data: {
        'slots': slots.map((s) => s.toJson()).toList(),
      });
      if (mounted) {
        // ignore: unused_result
        ref.refresh(masterScheduleProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Расписание сохранено', style: AppTextStyles.caption),
            backgroundColor: kBgSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: AppTextStyles.caption),
            backgroundColor: kBgSecondary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ScheduleEditor extends StatelessWidget {
  const _ScheduleEditor({
    required this.slots,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  final List<ScheduleSlot> slots;
  final bool saving;
  final ValueChanged<List<ScheduleSlot>> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(
          'Укажите рабочие часы для каждого дня недели',
          style: AppTextStyles.caption.copyWith(color: kTextSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Day rows ────────────────────────────────────────
        ...slots.map((slot) {
          final idx = slots.indexOf(slot);
          return _DayRow(
            slot: slot,
            onToggle: (v) {
              final updated = List<ScheduleSlot>.from(slots);
              updated[idx] = slot.copyWith(isWorking: v);
              onChanged(updated);
            },
            onTimeChange: (start, end) {
              final updated = List<ScheduleSlot>.from(slots);
              updated[idx] = slot.copyWith(startTime: start, endTime: end);
              onChanged(updated);
            },
          );
        }),

        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Сохранить', onPressed: onSave, loading: saving),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.slot,
    required this.onToggle,
    required this.onTimeChange,
  });

  final ScheduleSlot slot;
  final ValueChanged<bool> onToggle;
  final void Function(String start, String end) onTimeChange;

  Future<void> _pickTime(
    BuildContext context,
    String current,
    void Function(String) onPicked,
  ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kGold),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onPicked(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: slot.isWorking ? kBorder2 : kBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(_dayNames[slot.dayOfWeek],
                style: AppTextStyles.label.copyWith(
                  color: slot.isWorking ? kTextPrimary : kTextTertiary,
                )),
          ),

          Switch(
            value: slot.isWorking,
            onChanged: onToggle,
            activeColor: kGold,
            inactiveThumbColor: kTextTertiary,
            inactiveTrackColor: kBorder2,
          ),

          if (slot.isWorking) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => _pickTime(context, slot.startTime, (t) {
                onTimeChange(t, slot.endTime);
              }),
              child: _TimeChip(time: slot.startTime),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('—',
                  style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
            ),
            GestureDetector(
              onTap: () => _pickTime(context, slot.endTime, (t) {
                onTimeChange(slot.startTime, t);
              }),
              child: _TimeChip(time: slot.endTime),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text('Выходной',
                  style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: kBgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: kBorder2),
      ),
      child: Text(time, style: AppTextStyles.label),
    );
  }
}
