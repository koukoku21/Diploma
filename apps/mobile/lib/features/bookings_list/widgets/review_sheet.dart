import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';

// C-7: Оставить отзыв (боттом-шит)
class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({
    super.key,
    required this.bookingId,
    required this.masterName,
    required this.onDone,
  });
  final String bookingId;
  final String masterName;
  final VoidCallback onDone;

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  int _rating = 0;
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _loading = true);
    try {
      await createDio().post('/reviews', data: {
        'bookingId': widget.bookingId,
        'rating': _rating,
        if (_ctrl.text.trim().isNotEmpty) 'text': _ctrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onDone();
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось отправить отзыв',
            style: AppTextStyles.caption.copyWith(color: kTextPrimary),
          ),
          backgroundColor: kBgSecondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: kBorder2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text('Оцените визит', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('к ${widget.masterName}',
              style: AppTextStyles.body.copyWith(color: kTextSecondary)),
          const SizedBox(height: AppSpacing.xl),

          // Звёзды
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? kGold : kTextTertiary,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Текст отзыва
          TextField(
            controller: _ctrl,
            maxLines: 3,
            maxLength: 500,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Расскажите о визите (необязательно)',
              hintStyle: AppTextStyles.body.copyWith(color: kTextTertiary),
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
                borderSide: const BorderSide(color: kGold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: (_rating > 0 && !_loading) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                disabledBackgroundColor: kGold.withValues(alpha: 0.4),
                foregroundColor: kBgPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kBgPrimary))
                  : Text('Отправить отзыв',
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700, color: kBgPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
