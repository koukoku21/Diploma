import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../data/master_models.dart';
import '../providers/master_provider.dart';
import 'portfolio_gallery_screen.dart';
import 'all_reviews_screen.dart';

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
                _PortfolioGrid(
                  photos: master.photos,
                  onTap: (index) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PortfolioGalleryScreen(
                        photos: master.photos,
                        initialIndex: index,
                      ),
                    ),
                  ),
                ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Отзывы', style: AppTextStyles.title),
                    if (master.reviewCount > 3)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllReviewsScreen(
                              masterName: master.name,
                              reviews: master.reviews,
                              rating: master.rating,
                              reviewCount: master.reviewCount,
                            ),
                          ),
                        ),
                        child: Text(
                          'Все ${master.reviewCount}',
                          style: AppTextStyles.caption
                              .copyWith(color: kGold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...master.reviews.take(3).map((r) => _ReviewTile(review: r)),
                if (master.reviewCount > 3) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllReviewsScreen(
                          masterName: master.name,
                          reviews: master.reviews,
                          rating: master.rating,
                          reviewCount: master.reviewCount,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Посмотреть все отзывы',
                        style: AppTextStyles.caption.copyWith(color: kGold),
                      ),
                    ),
                  ),
                ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (master.rating != null) ...[
          Row(
            children: [
              // 5 звёзд с заливкой
              ...List.generate(5, (i) {
                final filled = i < master.rating!.floor();
                final half   = !filled && i < master.rating!;
                return Icon(
                  half
                      ? Icons.star_half_rounded
                      : filled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                  color: (filled || half) ? kGold : kBorder2,
                  size: 20,
                );
              }),
              const SizedBox(width: 6),
              Text(
                master.rating!.toStringAsFixed(1),
                style: AppTextStyles.label.copyWith(color: kGold),
              ),
              const SizedBox(width: 4),
              Text(
                '(${master.reviewCount})',
                style: AppTextStyles.caption.copyWith(color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: kTextSecondary, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                master.address,
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (master.lat != null && master.lng != null) ...[
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _openRoute(
                  context,
                  master.lat!,
                  master.lng!,
                  master.address
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: kGold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_outlined,
                          color: kGold, size: 14),
                      const SizedBox(width: 4),
                      Text('Маршрут',
                          style: AppTextStyles.caption
                              .copyWith(color: kGold, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

Future<void> _openRoute(
  BuildContext context,
  double lat,
  double lng,
  String address,
) async {
  final dgisUri = Uri.parse(
    'dgis://2gis.ru/routeSearch/rsType/car/to/$lng,$lat/go',
  );

  try {
    if (await canLaunchUrl(dgisUri)) {
      await launchUrl(dgisUri);
      return;
    }

    final webUri = Uri.parse(
      'https://2gis.ru/directions/points/to/$lng,$lat',
    );
    final opened = await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );

    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Не удалось открыть маршрут',
          style: AppTextStyles.caption.copyWith(color: kTextPrimary),
        ),
        backgroundColor: kBgSecondary,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Не удалось открыть маршрут',
          style: AppTextStyles.caption.copyWith(color: kTextPrimary),
        ),
        backgroundColor: kBgSecondary,
      ),
    );
  }
}


class _PortfolioGrid extends StatelessWidget {
  const _PortfolioGrid({required this.photos, required this.onTap});
  final List<MasterPortfolioPhoto> photos;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.network(
              photos[i].thumbUrl ?? photos[i].url,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
            ),
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
