import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';

// M-5: Ожидание верификации мастера
class MasterPendingScreen extends StatelessWidget {
  const MasterPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ─── Icon ──────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGold.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: kGold,
                  size: 48,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Заявка отправлена!',
                style: AppTextStyles.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Наша команда проверяет ваш профиль.\nОдобрение занимает до 24 часов.',
                style: AppTextStyles.body.copyWith(color: kTextSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ─── What's next ───────────────────────────────
              _InfoRow(
                icon: Icons.notifications_outlined,
                text: 'Вы получите уведомление о решении',
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                icon: Icons.star_border_rounded,
                text: 'После одобрения профиль появится в ленте',
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                text: 'Настройте расписание после одобрения',
              ),

              const Spacer(),

              PrimaryButton(
                label: 'На главную',
                onPressed: () => context.go(AppRoutes.feed),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kBgSecondary,
            shape: BoxShape.circle,
            border: Border.all(color: kBorder2),
          ),
          child: Icon(icon, color: kTextSecondary, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text,
              style: AppTextStyles.body.copyWith(color: kTextSecondary)),
        ),
      ],
    );
  }
}
