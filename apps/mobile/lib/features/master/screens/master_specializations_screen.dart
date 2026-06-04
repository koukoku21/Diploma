import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../providers/onboarding_provider.dart';

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

  void _next() {
    if (_selected.isEmpty) return;
    ref.read(onboardingProvider.notifier).setSpecializations(
      _selected.map((s) => _specializations[s]!).toList(),
    );
    context.push(AppRoutes.masterAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.becomeMaster, style: AppTextStyles.title),
        leading: BackButton(
          color: context.colors.textPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(context.l10n.masterSpecializations, style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.chooseOne,
                style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
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
                        color: selected ? context.colors.bgPrimary : context.colors.textPrimary,
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
                      backgroundColor: context.colors.bgSecondary,
                      checkmarkColor: context.colors.bgPrimary,
                      side: BorderSide(
                        color: selected ? kGold : context.colors.border2,
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
              label: context.l10n.continueBtn,
              onPressed: _next,
              enabled: _selected.isNotEmpty,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
