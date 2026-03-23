import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes  = List.generate(4, (_) => FocusNode());
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[0].requestFocus(),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();
  bool get _complete => _code.length == 4;

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _submit() async {
    await ref.read(verifyOtpProvider.notifier).verify(
          phone: widget.phone,
          code: _code,
        );

    final state = ref.read(verifyOtpProvider);
    if (!mounted) return;

    if (state.hasError) {
      _showError('Неверный код. Попробуйте ещё раз.');
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      return;
    }

    final result = state.value;
    if (result == null) return;

    if (result.isNewUser) {
      context.go(AppRoutes.name, extra: widget.phone);
    } else {
      context.go(AppRoutes.location);
    }
  }

  Future<void> _resend() async {
    await ref.read(sendOtpProvider.notifier).send(widget.phone);
    _startTimer();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.caption.copyWith(color: kTextPrimary)),
        backgroundColor: kRose.withValues(alpha: 0.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(verifyOtpProvider).isLoading;

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              Text('Введите код', style: AppTextStyles.display),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Отправили SMS на\n${widget.phone}',
                style: AppTextStyles.body.copyWith(color: kTextSecondary),
              ),

              const SizedBox(height: 40),

              // 4 ячейки OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) => _OtpCell(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  onChanged: (v) => _onDigitChanged(i, v),
                )),
              ),

              const SizedBox(height: 40),

              PrimaryButton(
                label: 'Подтвердить',
                onPressed: _submit,
                loading: loading,
                enabled: _complete,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Повтор отправки
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Отправить повторно через $_secondsLeft сек',
                        style: AppTextStyles.caption.copyWith(color: kTextTertiary),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: Text(
                          'Отправить повторно',
                          style: AppTextStyles.label.copyWith(color: kGold),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Одна ячейка OTP ─────────────────────────────────────────────
class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 72,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.h1.copyWith(fontSize: 28, color: kGold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: kBgTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: kGold, width: 1.5),
          ),
        ),
      ),
    );
  }
}
