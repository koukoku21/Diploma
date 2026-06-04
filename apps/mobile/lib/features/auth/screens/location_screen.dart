import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/router/app_router.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  Future<void> _requestLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;
      _goToFeed(context);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!context.mounted) return;
    _goToFeed(context);
  }

  void _goToFeed(BuildContext context) => context.go(AppRoutes.feed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            children: [
              const Spacer(),

              // Иллюстрация — карта/локация
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 56,
                  color: kGold,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Мастера рядом\nс вами',
                textAlign: TextAlign.center,
                style: AppTextStyles.display,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Разрешите доступ к геолокации,\nчтобы видеть мастеров в вашем районе\nАстаны.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
              ),

              const Spacer(),

              PrimaryButton(
                label: context.l10n.allowLocation,
                onPressed: () => _requestLocation(context),
              ),

              const SizedBox(height: AppSpacing.md),

              TextButton(
                onPressed: () => _goToFeed(context),
                child: Text(
                  context.l10n.skipBtn,
                  style: AppTextStyles.label.copyWith(color: context.colors.textSecondary),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
