import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/me_provider.dart';
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
    final me = ref.watch(meProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (master) {
          final myMasterProfileId = me.valueOrNull?.masterProfileId;
          final isOwnProfile = myMasterProfileId == master.id;
          return _ProfileBody(
            master: master,
            myMasterProfileId: isOwnProfile ? myMasterProfileId : null,
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.master, this.myMasterProfileId});
  final MasterProfile master;
  final String? myMasterProfileId;

  void _shareProfile(BuildContext context, MasterProfile m) {
    if (m.username == null) return;
    final link = 'https://diploma-api-dt1b.vercel.app/p/${m.username}';
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.colors.border2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Поделиться профилем', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(link,
                style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary)),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(child: _ShareBtn(
                icon: Icons.copy_rounded,
                label: context.l10n.copyLink,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.linkCopied),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              )),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _ShareBtn(
                icon: Icons.telegram,
                label: 'Telegram',
                onTap: () async {
                  final text = Uri.encodeComponent('Запишись к мастеру:');
                  final url = Uri.encodeComponent(link);
                  await launchUrl(
                    Uri.parse('https://t.me/share/url?url=$url&text=$text'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              )),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _ShareBtn(
                icon: Icons.message_rounded,
                label: 'WhatsApp',
                onTap: () async {
                  final text = Uri.encodeComponent('Запишись к мастеру: $link');
                  await launchUrl(
                    Uri.parse('https://wa.me/?text=$text'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              )),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ─── Фото-хедер с именем ─────────────────────────────────
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: context.colors.bgPrimary,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.colors.bgPrimary.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (master.username != null)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.bgPrimary.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ios_share_rounded, size: 18),
                ),
                onPressed: () => _shareProfile(context, master),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                master.photos.isNotEmpty
                    ? CachedNetworkImage(imageUrl: master.photos.first.url, fit: BoxFit.cover)
                    : Container(color: context.colors.bgTertiary),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, context.colors.bgPrimary],
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
              const SizedBox(height: AppSpacing.md),

              // Соцсети
              if (master.instagramUrl != null || master.tiktokUrl != null || master.whatsappPhone != null)
                _SocialRow(master: master),
              if (master.instagramUrl != null || master.tiktokUrl != null || master.whatsappPhone != null)
                const SizedBox(height: AppSpacing.xl)
              else
                const SizedBox(height: AppSpacing.xl),

              // Портфолио
              if (master.photos.length > 1) ...[
                Text(context.l10n.portfolio, style: AppTextStyles.title),
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
              Text(context.l10n.services, style: AppTextStyles.title),
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
                    Text(context.l10n.reviews, style: AppTextStyles.title),
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
                              myMasterProfileId: myMasterProfileId,
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
                  color: (filled || half) ? kGold : context.colors.border2,
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
                style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: context.colors.textSecondary, size: 16),
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
                onTap: () => _openRoute(master.lat!, master.lng!, master.address),
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

Future<void> _openRoute(double lat, double lng, String address) async {
  // 2GIS deep link — открывает приложение 2GIS с маршрутом до точки
  final dgisUri = Uri.parse(
      'dgis://2gis.ru/routeSearch/rsType/car/to/$lng,$lat/go');

  if (await canLaunchUrl(dgisUri)) {
    await launchUrl(dgisUri);
    return;
  }

  // Fallback: веб-версия 2GIS
  final webUri = Uri.parse(
      'https://2gis.ru/directions/points/to/$lng,$lat');
  await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
            child: CachedNetworkImage(
              imageUrl: photos[i].thumbUrl ?? photos[i].url,
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
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
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
                context.l10n.bookBtn,
                style:
                    AppTextStyles.caption.copyWith(color: context.colors.bgPrimary, fontWeight: FontWeight.w700),
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
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
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
                    color: i < review.rating ? kGold : context.colors.border2,
                  ),
                ),
              ),
            ],
          ),
          if (review.text != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.text!, style: AppTextStyles.body),
          ],
          if (review.reply != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.bgTertiary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply_rounded, size: 14, color: kGold),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(review.reply!.text,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.master});
  final MasterProfile master;

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (master.instagramUrl != null)
          _SocialBtn(
            label: 'Instagram',
            color: const Color(0xFFE1306C),
            icon: Icons.camera_alt_outlined,
            onTap: () => _open('https://instagram.com/${master.instagramUrl}'),
          ),
        if (master.instagramUrl != null && (master.tiktokUrl != null || master.whatsappPhone != null))
          const SizedBox(width: AppSpacing.sm),
        if (master.tiktokUrl != null)
          _SocialBtn(
            label: 'TikTok',
            color: context.colors.textPrimary,
            icon: Icons.music_note_rounded,
            onTap: () => _open('https://tiktok.com/@${master.tiktokUrl}'),
          ),
        if (master.tiktokUrl != null && master.whatsappPhone != null)
          const SizedBox(width: AppSpacing.sm),
        if (master.whatsappPhone != null)
          _SocialBtn(
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            icon: Icons.message_rounded,
            onTap: () => _open('https://wa.me/${master.whatsappPhone}'),
          ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({required this.label, required this.color, required this.icon, required this.onTap});
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareBtn extends StatelessWidget {
  const _ShareBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.bgTertiary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kGold, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
