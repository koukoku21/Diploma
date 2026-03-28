import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/network/dio_client.dart';

// label → API enum value (ServiceCategory)
const _specializations = <String, String>{
  'Маникюр':            'MANICURE',
  'Педикюр':            'PEDICURE',
  'Стрижка':            'HAIRCUT',
  'Окрашивание':        'COLORING',
  'Макияж':             'MAKEUP',
  'Ресницы':            'LASHES',
  'Брови':              'BROWS',
  'Уход за кожей':      'SKINCARE',
  'Другое':             'OTHER',
};

// M-1: Специализации мастера
class MasterSpecializationsScreen extends ConsumerStatefulWidget {
  const MasterSpecializationsScreen({super.key});

  @override
  ConsumerState<MasterSpecializationsScreen> createState() =>
      _MasterSpecializationsScreenState();
}

class _MasterSpecializationsScreenState
    extends ConsumerState<MasterSpecializationsScreen> {
  final _selected = <String>{};
  bool _loading = false;

  Future<void> _next() async {
    if (_selected.isEmpty) return;
    setState(() => _loading = true);
    try {
      await createDio().post('/masters', data: {
        'specializations': _selected.map((s) => _specializations[s]).toList(),
        'address': 'Астана',          // обновляется на следующем шаге
        'lat': 51.1801,
        'lng': 71.4460,
      });
      if (mounted) context.push(AppRoutes.masterAddress);
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
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Стать мастером', style: AppTextStyles.title),
        leading: BackButton(
          color: kTextPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text('Ваши специализации', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text('Выберите от одной и более',
                style: AppTextStyles.body.copyWith(color: kTextSecondary)),
            const SizedBox(height: AppSpacing.xl),

            // ─── Chips ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _specializations.keys.map((s) {
                    final selected = _selected.contains(s);
                    return FilterChip(
                      label: Text(s, style: AppTextStyles.label.copyWith(
                        color: selected ? kBgPrimary : kTextPrimary,
                      )),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selected.add(s);
                        } else {
                          _selected.remove(s);
                        }
                      }),
                      selectedColor: kGold,
                      backgroundColor: kBgSecondary,
                      checkmarkColor: kBgPrimary,
                      side: BorderSide(
                        color: selected ? kGold : kBorder2,
                      ),
                      shape: const StadiumBorder(),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Далее',
              onPressed: _next,
              loading: _loading,
              enabled: _selected.isNotEmpty,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
