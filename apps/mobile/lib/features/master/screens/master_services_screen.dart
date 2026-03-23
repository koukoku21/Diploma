import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/network/dio_client.dart';

final _servicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await createDio().get('/master/services');
  return (res.data as List).cast<Map<String, dynamic>>();
});

// M-11: Управление услугами
class MasterServicesScreen extends ConsumerWidget {
  const MasterServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_servicesProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Услуги', style: AppTextStyles.title),
        leading: BackButton(
            color: kTextPrimary, onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kGold),
            onPressed: () => _showAddSheet(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.content_cut_outlined,
                      color: kTextTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет услуг',
                      style: AppTextStyles.subtitle
                          .copyWith(color: kTextSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => _showAddSheet(context, ref),
                    child: Text('Добавить',
                        style: AppTextStyles.label.copyWith(color: kGold)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: services.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: kBorder, indent: 16, endIndent: 16),
            itemBuilder: (_, i) {
              final s = services[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH, vertical: AppSpacing.xs),
                title: Text(s['name'] as String, style: AppTextStyles.label),
                subtitle: Text(
                  '${s['duration']} мин · ${s['category']}',
                  style: AppTextStyles.caption.copyWith(color: kTextSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(s['price'] as num).toStringAsFixed(0)} ₸',
                      style: AppTextStyles.label.copyWith(color: kGold),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () async {
                        await createDio().delete('/master/services/${s["id"]}');
                        // ignore: unused_result
                        ref.refresh(_servicesProvider);
                      },
                      child: const Icon(Icons.delete_outline,
                          color: kRose, size: 20),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _AddServiceSheet(ref: ref),
    );
  }
}

class _AddServiceSheet extends ConsumerStatefulWidget {
  const _AddServiceSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends ConsumerState<_AddServiceSheet> {
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  int _duration = 60;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().length >= 2 && _priceCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await createDio().post('/master/services', data: {
        'name': _nameCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'duration': _duration,
        'category': 'Другое',
      });
      // ignore: unused_result
      widget.ref.refresh(_servicesProvider);
      if (mounted) Navigator.pop(context);
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
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                  color: kBorder2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Новая услуга', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),

          Text('Название', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _nameCtrl,
            hint: 'Маникюр с гель-лаком',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),

          Text('Цена (₸)', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _priceCtrl,
            hint: '5000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),

          Text('Длительность: $_duration мин', style: AppTextStyles.label),
          Slider(
            value: _duration.toDouble(),
            min: 15,
            max: 240,
            divisions: 15,
            activeColor: kGold,
            inactiveColor: kBorder2,
            label: '$_duration мин',
            onChanged: (v) => setState(() => _duration = v.round()),
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSave && !_loading ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                disabledBackgroundColor: kGold.withValues(alpha: 0.4),
                foregroundColor: kBgPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: kBgPrimary, strokeWidth: 2))
                  : Text('Добавить',
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700, color: kBgPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
