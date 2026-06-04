import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../data/master_models.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

// C-2b: Все отзывы мастера
class AllReviewsScreen extends StatefulWidget {
  const AllReviewsScreen({
    super.key,
    required this.masterName,
    required this.reviews,
    required this.rating,
    required this.reviewCount,
    this.myMasterProfileId,
  });
  final String masterName;
  final List<MasterReview> reviews;
  final double? rating;
  final int reviewCount;
  // передаётся только когда текущий пользователь — владелец этого профиля
  final String? myMasterProfileId;

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  late List<MasterReview> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = List.of(widget.reviews);
  }

  void _onReplyAdded(String reviewId, MasterReviewReply reply) {
    setState(() {
      final idx = _reviews.indexWhere((r) => r.id == reviewId);
      if (idx != -1) _reviews[idx] = _reviews[idx].withReply(reply);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.reviews, style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (widget.rating != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH, vertical: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    widget.rating!.toStringAsFixed(1),
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
                          color: i < widget.rating!.round() ? kGold : context.colors.border2,
                        )),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.reviewCount} отзывов',
                        style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Divider(color: context.colors.border, height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _ReviewCard(
                review: _reviews[i],
                myMasterProfileId: widget.myMasterProfileId,
                onReplyAdded: _onReplyAdded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onReplyAdded,
    this.myMasterProfileId,
  });
  final MasterReview review;
  final String? myMasterProfileId;
  final void Function(String reviewId, MasterReviewReply reply) onReplyAdded;

  static const _months = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';

  void _showReplyDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgSecondary,
        title: Text(context.l10n.replyToReview, style: AppTextStyles.title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          maxLength: 1000,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: context.l10n.replyHint,
            hintStyle: AppTextStyles.body.copyWith(color: context.colors.textTertiary),
            filled: true,
            fillColor: context.colors.bgTertiary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: kGold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancelBtn, style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final res = await createDio().post(
                  '/reviews/${review.id}/reply',
                  data: {'text': text},
                );
                final reply = MasterReviewReply.fromJson(res.data as Map<String, dynamic>);
                onReplyAdded(review.id, reply);
              } on DioException catch (e) {
                final msg = (e.response?.data as Map?)?['message'] ?? 'Ошибка';
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg.toString())),
                  );
                }
              }
            },
            child: Text(context.l10n.sendBtn, style: AppTextStyles.caption.copyWith(color: kGold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canReply = myMasterProfileId != null && review.reply == null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.colors.bgTertiary,
                backgroundImage: review.clientAvatar != null
                    ? NetworkImage(review.clientAvatar!)
                    : null,
                child: review.clientAvatar == null
                    ? Icon(Icons.person_outline, color: context.colors.textTertiary, size: 18)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.clientName, style: AppTextStyles.label),
                    Text(_fmt(review.createdAt),
                        style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: i < review.rating ? kGold : context.colors.border2,
                )),
              ),
            ],
          ),
          if (review.text != null && review.text!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.text!, style: AppTextStyles.body),
          ],

          // Ответ мастера
          if (review.reply != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ReplyBlock(reply: review.reply!),
          ],

          // Кнопка «Ответить» (только для мастера, только если нет ответа)
          if (canReply) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => _showReplyDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: kGold),
                  const SizedBox(width: 4),
                  Text(context.l10n.reply,
                      style: AppTextStyles.caption.copyWith(color: kGold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReplyBlock extends StatelessWidget {
  const _ReplyBlock({required this.reply});
  final MasterReviewReply reply;

  static const _months = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.reply_rounded, size: 14, color: kGold),
              const SizedBox(width: 4),
              Text(context.l10n.replyMaster,
                  style: AppTextStyles.caption.copyWith(
                      color: kGold, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_fmt(reply.createdAt),
                  style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(reply.text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
