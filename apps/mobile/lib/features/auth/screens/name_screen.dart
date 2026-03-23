import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key, required this.phone});
  final String phone;

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _ctrl = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _canSubmit = _ctrl.text.trim().length >= 2);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Финальный вызов verify-otp с именем
    await ref.read(verifyOtpProvider.notifier).verify(
          phone: widget.phone,
          code: '', // код уже проверен на предыдущем экране — повторно не нужен
          name: _ctrl.text.trim(),
        );

    if (!mounted) return;
    context.go(AppRoutes.location);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(verifyOtpProvider).isLoading;

    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              Text('Как вас зовут?', style: AppTextStyles.display),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Мастера и клиенты будут видеть ваше имя.',
                style: AppTextStyles.body.copyWith(color: kTextSecondary),
              ),

              const SizedBox(height: 40),

              AppTextField(
                controller: _ctrl,
                autofocus: true,
                hint: 'Айгерим',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _canSubmit ? _submit() : null,
              ),

              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: 'Продолжить',
                onPressed: _submit,
                loading: loading,
                enabled: _canSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
