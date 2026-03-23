import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../master_profile/data/master_models.dart';

// C-3: Шаг 1/3 — Выбор услуги
class ServiceSelectScreen extends StatelessWidget {
  const ServiceSelectScreen({super.key, required this.master});
  final MasterProfile master;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Column(
          children: [
            Text('Выберите услугу', style: AppTextStyles.title),
            Text('Шаг 1 из 3',
                style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        itemCount: master.services.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final s = master.services[i];
          return GestureDetector(
            onTap: () => context.push(
              AppRoutes.slotSelect(master.id),
              extra: (master: master, service: s),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: kBgSecondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: AppTextStyles.subtitle),
                        const SizedBox(height: 4),
                        Text('${s.durationMin} мин',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(
                    'от ${s.priceFrom}₸',
                    style: AppTextStyles.label.copyWith(color: kGold),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.chevron_right, color: kTextTertiary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
