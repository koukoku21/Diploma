import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/network/dio_client.dart';

// M-2: Адрес работы мастера (2GIS autocomplete placeholder)
class MasterAddressScreen extends ConsumerStatefulWidget {
  const MasterAddressScreen({super.key});

  @override
  ConsumerState<MasterAddressScreen> createState() => _MasterAddressScreenState();
}

class _MasterAddressScreenState extends ConsumerState<MasterAddressScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  // In production: 2GIS suggestion list + selected lat/lng
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _ctrl.text.trim().length >= 5;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      // Update the master profile with the address
      // In production: geocode via 2GIS, get lat/lng from suggestion
      await createDio().patch('/masters/me', data: {
        'address': _ctrl.text.trim(),
        'lat': _lat ?? 51.1801,   // Astana default coords
        'lng': _lng ?? 71.4460,
      });
      if (mounted) context.push(AppRoutes.masterPortfolio);
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
        title: Text('Адрес работы', style: AppTextStyles.title),
        leading: BackButton(color: kTextPrimary, onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text('Где вы принимаете?', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Укажите адрес — клиенты увидят расстояние до вас.',
              style: AppTextStyles.body.copyWith(color: kTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppTextField(
              controller: _ctrl,
              hint: 'ул. Сейфуллина 4, Астана',
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.info_outline, color: kTextTertiary, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Поддержка 2GIS autocomplete будет добавлена',
                  style: AppTextStyles.caption.copyWith(color: kTextTertiary),
                ),
              ],
            ),

            const Spacer(),
            PrimaryButton(
              label: 'Далее',
              onPressed: _save,
              loading: _loading,
              enabled: _canSubmit,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
