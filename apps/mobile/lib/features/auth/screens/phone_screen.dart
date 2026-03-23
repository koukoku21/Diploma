import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final digits = _ctrl.text.replaceAll(RegExp(r'\D'), '');
      setState(() => _canSubmit = digits.length == 10);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '+7${_ctrl.text.replaceAll(RegExp(r'\D'), '')}';

  Future<void> _submit() async {
    await ref.read(sendOtpProvider.notifier).send(_fullPhone);
    final state = ref.read(sendOtpProvider);
    if (state.hasError) {
      if (!mounted) return;
      _showError(state.error.toString());
      return;
    }
    if (!mounted) return;
    context.push(AppRoutes.otp, extra: _fullPhone);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.caption.copyWith(color: kTextPrimary)),
        backgroundColor: kBgSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(sendOtpProvider).isLoading;

    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              Text('Войти', style: AppTextStyles.display),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Введите ваш номер телефона.\nМы отправим код подтверждения.',
                style: AppTextStyles.body.copyWith(color: kTextSecondary),
              ),

              const SizedBox(height: 40),

              AppTextField(
                controller: _ctrl,
                autofocus: true,
                prefixText: '+7 ',
                hint: '700 000 00 00',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                maxLength: 12,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _PhoneFormatter(),
                ],
                onSubmitted: (_) => _canSubmit ? _submit() : null,
              ),

              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: 'Получить код',
                onPressed: _submit,
                loading: loading,
                enabled: _canSubmit,
              ),

              const Spacer(),

              Center(
                child: Text(
                  'Нажимая «Получить код», вы соглашаетесь\nс Условиями использования',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: kTextTertiary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Форматтер: 700 000 00 00 ─────────────────────────────────────
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();

    for (var i = 0; i < digits.length && i < 10; i++) {
      if (i == 3 || i == 6 || i == 8) buf.write(' ');
      buf.write(digits[i]);
    }

    final str = buf.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
