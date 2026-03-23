import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (enabled && !loading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGold,
          disabledBackgroundColor: kGold.withValues(alpha: 0.4),
          foregroundColor: kBgPrimary,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kBgPrimary,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: kBgPrimary,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
