import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../data/master_models.dart';
import '../providers/master_provider.dart';

class MasterProfileScreen extends ConsumerWidget {
  const MasterProfileScreen({super.key, required this.masterId});
  final String masterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(masterProfileProvider(masterId));

    return Scaffold(
      backgroundColor: kBgPrimary,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (master) => _ProfileBody(master: master),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.master});
  final MasterProfile master;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ─── Фото-хедер с именем ─────────────────────────────────
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: kBgPrimary,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kBgPrimary.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                master.photos.isNotEmpty
                    ? Image.network(master.photos.first.url, fit: BoxFit.cover)
                    : Container(color: kBgTertiary),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, kBgPrimary],
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.lg,
                  left: AppSpacing.screenH,
                  right: AppSpacing.screenH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(master.name, style: AppTextStyles.h1),
                      if (master.specializations.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          master.specializations.take(3).join(' · ').toUpperCase(),
                          style: AppTextStyles.overline,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.lg),

              // Рейтинг + адрес
              _MetaRow(master: master),
              const SizedBox(height: AppSpacing.xl),

              // Портфолио
              if (master.photos.length > 1) ...[
                Text('Портфолио', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.md),
                _PortfolioGrid(photos: master.photos),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Услуги
              Text('Услуги', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.md),
              ...master.services.map((s) => _ServiceTile(
                    service: s,
                    onBook: () => context.push(
                      AppRoutes.serviceSelect(master.id),
                      extra: master,
                    ),
                  )),
              const SizedBox(height: AppSpacing.xl),

              // Отзывы
              if (master.reviews.isNotEmpty) ...[
                Text('Отзывы', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.md),
                ...master.reviews.map((r) => _ReviewTile(review: r)),
                const SizedBox(height: AppSpacing.xl),
              ],

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.master});
  final MasterProfile master;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (master.rating != null) ...[
          const Icon(Icons.star_rounded, color: kGold, size: 18),
          const SizedBox(width: 4),
          Text(
            '${master.rating!.toStringAsFixed(1)} (${master.reviewCount})',
            style: AppTextStyles.label.copyWith(color: kGold),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
        const Icon(Icons.location_on_outlined, color: kTextSecondary, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            master.address,
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PortfolioGrid extends StatelessWidget {
  const _PortfolioGrid({required this.photos});
  final List<MasterPortfolioPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.network(
            photos[i].thumbUrl ?? photos[i].url,
            width: 100,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onBook});
  final MasterService service;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.title, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  '${service.durationMin} мин',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            'от ${service.priceFrom}₸',
            style: AppTextStyles.label.copyWith(color: kGold),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onBook,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: kGold,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Записаться',
                style:
                    AppTextStyles.caption.copyWith(color: kBgPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final MasterReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              Text(review.clientName, style: AppTextStyles.label),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < review.rating ? kGold : kBorder2,
                  ),
                ),
              ),
            ],
          ),
          if (review.text != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.text!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}
