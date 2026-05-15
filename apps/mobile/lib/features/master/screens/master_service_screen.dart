import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/network/dio_client.dart';
import '../providers/onboarding_provider.dart';

const _categories = <String, String>{
  'Маникюр':       'MANICURE',
  'Педикюр':       'PEDICURE',
  'Стрижка':       'HAIRCUT',
  'Окрашивание':   'COLORING',
  'Макияж':        'MAKEUP',
  'Брови':         'BROWS',
  'Ресницы':       'LASHES',
  'Уход за кожей': 'SKINCARE',
  'Другое':        'OTHER',
};

// M-4: Добавить первую услугу
class MasterServiceScreen extends ConsumerStatefulWidget {
  const MasterServiceScreen({super.key});

  @override
  ConsumerState<MasterServiceScreen> createState() => _MasterServiceScreenState();
}

class _MasterServiceScreenState extends ConsumerState<MasterServiceScreen> {
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = _categories.keys.first;
  int _duration = 60;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().length >= 2 && _priceCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgSecondary,
        title: Text('Отправить заявку?', style: AppTextStyles.h1),
        content: Text(
          'После отправки заявка уйдёт на проверку. Убедитесь, что данные заполнены верно.',
          style: AppTextStyles.body.copyWith(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Отмена', style: AppTextStyles.label.copyWith(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Отправить', style: AppTextStyles.label.copyWith(color: kGold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final onboarding = ref.read(onboardingProvider);
      final dio = createDio();

      // 1. Создать профиль мастера
      await dio.post('/masters', data: {
        'specializations': onboarding.specializations,
        'address': onboarding.address,
        'lat': onboarding.lat,
        'lng': onboarding.lng,
      });

      // 2. Загрузить фото портфолио
      for (final photo in onboarding.photos) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(photo.bytes, filename: photo.filename),
        });
        await dio.post('/master/portfolio/upload', data: formData);
      }

      // 3. Создать первую услугу
      await dio.post('/master/services', data: {
        'name': _nameCtrl.text.trim(),
        'category': _categories[_category],
        'priceFrom': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'durationMin': _duration,
      });

      // 4. Сбросить локальное состояние онбординга
      ref.read(onboardingProvider.notifier).reset();

      if (mounted) context.pushReplacement(AppRoutes.masterPending);
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
        title: Text('Первая услуга', style: AppTextStyles.title),
        leading: BackButton(color: kTextPrimary, onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text('Добавьте услугу', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text('Вы сможете добавить больше услуг после одобрения.',
                style: AppTextStyles.body.copyWith(color: kTextSecondary)),
            const SizedBox(height: AppSpacing.xl),

            // Name
            Text('Название услуги', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _nameCtrl,
              hint: 'Маникюр с покрытием гель-лак',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category
            Text('Категория', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: kBgSecondary,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                filled: true,
                fillColor: kBgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: kBorder),
                ),
              ),
              items: _categories.keys.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: AppTextStyles.body),
              )).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Price
            Text('Цена (₸)', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _priceCtrl,
              hint: '5000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Duration
            Text('Длительность: $_duration мин', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
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

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Отправить на проверку',
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
