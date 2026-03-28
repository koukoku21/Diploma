import 'package:flutter/material.dart';
import '../data/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

// C-2b: Все отзывы мастера
class AllReviewsScreen extends StatelessWidget {
  const AllReviewsScreen({
    super.key,
    required this.masterName,
    required this.reviews,
    required this.rating,
    required this.reviewCount,
  });
  final String masterName;
  final List<MasterReview> reviews;
  final double? rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Отзывы', style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Итоговый рейтинг
          if (rating != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH, vertical: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    rating!.toStringAsFixed(1),
                    style: AppTextStyles.h1.copyWith(fontSize: 48, color: kGold),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) => Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: i < rating!.round() ? kGold : kBorder2,
                        )),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$reviewCount отзывов',
                        style: AppTextStyles.caption.copyWith(color: kTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Divider(color: kBorder, height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final MasterReview review;

  static const _months = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String get _dateStr {
    final d = review.createdAt;
    return '${d.day} ${_months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 18,
                backgroundColor: kBgTertiary,
                backgroundImage: review.clientAvatar != null
                    ? NetworkImage(review.clientAvatar!)
                    : null,
                child: review.clientAvatar == null
                    ? const Icon(Icons.person_outline,
                        color: kTextTertiary, size: 18)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.clientName, style: AppTextStyles.label),
                    Text(_dateStr,
                        style: AppTextStyles.caption
                            .copyWith(color: kTextTertiary)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: i < review.rating ? kGold : kBorder2,
                )),
              ),
            ],
          ),
          if (review.text != null && review.text!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.text!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}
