import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/feed_models.dart';

class MasterCard extends StatelessWidget {
  const MasterCard({super.key, required this.master});
  final FeedMaster master;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: kBorder2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ─── Фото (70% высоты карточки) ──────────────────────
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Фото
                master.coverUrl != null
                    ? Image.network(
                        master.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),

                // Градиент снизу
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, kBgPrimary],
                      ),
                    ),
                  ),
                ),

                // Бейдж "Верифицирован"
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: _VerifiedBadge(),
                ),

                // Имя + специализации
                Positioned(
                  bottom: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(master.name, style: AppTextStyles.h1),
                      const SizedBox(height: 4),
                      if (master.specializations.isNotEmpty)
                        Text(
                          master.specializations
                              .take(3)
                              .map(_formatCategory)
                              .join(' · ')
                              .toUpperCase(),
                          style: AppTextStyles.overline,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Мета-инфо (рейтинг, цена, расстояние) ──────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (master.rating != null) ...[
                  const Icon(Icons.star_rounded, color: kGold, size: 16),
                  const SizedBox(width: 3),
                  Text(
                    master.rating!.toStringAsFixed(1),
                    style: AppTextStyles.label.copyWith(color: kGold),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (master.minPrice != null)
                  Text(
                    'от ${master.minPrice}₸',
                    style: AppTextStyles.label.copyWith(color: kTextPrimary),
                  ),
                const Spacer(),
                const Icon(Icons.location_on_outlined,
                    color: kTextSecondary, size: 14),
                const SizedBox(width: 2),
                Text(
                  master.distanceLabel,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        color: kBgTertiary,
        child: const Center(
          child: Icon(Icons.person_outline, color: kTextTertiary, size: 64),
        ),
      );

  String _formatCategory(String cat) => switch (cat) {
        'MANICURE' => 'Маникюр',
        'PEDICURE' => 'Педикюр',
        'HAIRCUT' => 'Стрижка',
        'COLORING' => 'Окрашивание',
        'MAKEUP' => 'Макияж',
        'LASHES' => 'Ресницы',
        'BROWS' => 'Брови',
        'SKINCARE' => 'Уход',
        _ => cat,
      };
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kSuccess.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: kSuccess.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: kSuccess, size: 12),
          const SizedBox(width: 4),
          Text(
            'Верифицирован',
            style: AppTextStyles.caption.copyWith(color: kSuccess, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
