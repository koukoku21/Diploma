import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/data/service_template.dart';

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
              final template = s['template'] as Map<String, dynamic>?;
              final title = template?['name'] as String? ?? s['title'] as String? ?? '—';
              final category = template?['category'] as String? ?? s['category'] as String? ?? '';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH, vertical: AppSpacing.xs),
                title: Text(title, style: AppTextStyles.label),
                subtitle: Text(
                  '${s['durationMin']} мин · ${ServiceTemplate.categoryLabel(category)}',
                  style: AppTextStyles.caption.copyWith(color: kTextSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(s['priceFrom'] as num).toStringAsFixed(0)} ₸',
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
  final _priceCtrl = TextEditingController();
  int _duration = 60;
  bool _loading = false;
  ServiceTemplate? _selectedTemplate;

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _selectedTemplate != null && _priceCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await createDio().post('/master/services', data: {
        'templateId': _selectedTemplate!.id,
        'priceFrom': int.tryParse(_priceCtrl.text.trim()) ?? 500,
        'durationMin': _duration,
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
    final templatesAsync = ref.watch(serviceTemplatesProvider);

    return SingleChildScrollView(
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

          // ─── Выбор услуги из справочника ──────────────────────
          Text('Услуга', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          templatesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: kGold)),
            error: (e, _) => Text('Ошибка загрузки: $e',
                style: AppTextStyles.caption.copyWith(color: kRose)),
            data: (templates) => _TemplatePicker(
              templates: templates,
              selected: _selectedTemplate,
              onChanged: (t) => setState(() => _selectedTemplate = t),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Цена ─────────────────────────────────────────────
          Text('Цена (₸)', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _priceCtrl,
            hint: '3000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Длительность ─────────────────────────────────────
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

// ─── Пикер шаблонов ────────────────────────────────────────────────
class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.templates,
    required this.selected,
    required this.onChanged,
  });

  final List<ServiceTemplate> templates;
  final ServiceTemplate? selected;
  final ValueChanged<ServiceTemplate> onChanged;

  @override
  Widget build(BuildContext context) {
    // Группируем по категории
    final byCategory = <String, List<ServiceTemplate>>{};
    for (final t in templates) {
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }

    return Container(
      decoration: BoxDecoration(
        color: kBgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: selected != null ? kGold : kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текущий выбор
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected?.name ?? 'Выберите услугу...',
                    style: AppTextStyles.body.copyWith(
                      color: selected != null ? kTextPrimary : kTextTertiary,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more, color: kTextTertiary, size: 20),
              ],
            ),
          ),

          // Список сгруппированный
          const Divider(height: 1, color: kBorder),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: byCategory.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                        child: Text(
                          ServiceTemplate.categoryLabel(entry.key),
                          style: AppTextStyles.caption.copyWith(
                              color: kGold, fontWeight: FontWeight.w700),
                        ),
                      ),
                      ...entry.value.map((t) => GestureDetector(
                            onTap: () => onChanged(t),
                            child: Container(
                              color: selected?.id == t.id
                                  ? kGold.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(t.name,
                                        style: AppTextStyles.body.copyWith(
                                          color: selected?.id == t.id
                                              ? kGold
                                              : kTextPrimary,
                                        )),
                                  ),
                                  if (selected?.id == t.id)
                                    const Icon(Icons.check,
                                        color: kGold, size: 18),
                                ],
                              ),
                            ),
                          )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
