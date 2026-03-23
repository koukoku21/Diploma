import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../data/feed_models.dart';
import '../providers/feed_provider.dart';
import '../widgets/master_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _swiperCtrl = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).init(ref.read(feedFilterProvider));
    });
  }

  @override
  void dispose() {
    _swiperCtrl.dispose();
    super.dispose();
  }

  void _onSkip() => _swiperCtrl.swipe(CardSwiperDirection.left);
  void _onBook(FeedMaster master) =>
      context.push(AppRoutes.masterPublicProfile(master.id));

  bool _onSwipe(int prev, int? next, CardSwiperDirection dir) {
    ref.read(feedProvider.notifier).removeTop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        centerTitle: true,
        title: Text('MIRAKU',
            style: AppTextStyles.title.copyWith(letterSpacing: 4, color: kGold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: kTextSecondary),
            onPressed: () => _showFilter(context),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(FeedState state) {
    if (state.loading && state.cards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: kGold),
      );
    }

    if (state.cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: kTextTertiary, size: 64),
            const SizedBox(height: AppSpacing.md),
            Text('Мастеров не найдено',
                style: AppTextStyles.subtitle.copyWith(color: kTextSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text('Попробуйте увеличить радиус поиска',
                style: AppTextStyles.caption),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ─── Карточки ───────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CardSwiper(
              controller: _swiperCtrl,
              cardsCount: state.cards.length,
              onSwipe: _onSwipe,
              numberOfCardsDisplayed: state.cards.length.clamp(1, 3),
              backCardOffset: const Offset(0, 20),
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              cardBuilder: (ctx, index, _, __) {
                final master = state.cards[index];
                return GestureDetector(
                  onTap: () =>
                      context.push(AppRoutes.masterPublicProfile(master.id)),
                  child: MasterCard(master: master),
                );
              },
            ),
          ),
        ),

        // ─── Три кнопки действий ────────────────────────────────
        _ActionBar(
          onSkip: _onSkip,
          onFavourite: () => _handleFavourite(state.cards.first),
          onBook: () => _onBook(state.cards.first),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _handleFavourite(FeedMaster master) {
    _swiperCtrl.swipe(CardSwiperDirection.top);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${master.name} добавлен в избранное',
            style: AppTextStyles.caption.copyWith(color: kTextPrimary)),
        backgroundColor: kBgSecondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }
}

// ─── Три кнопки: ✕  ♡  📅 ────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onSkip,
    required this.onFavourite,
    required this.onBook,
  });

  final VoidCallback onSkip;
  final VoidCallback onFavourite;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Row(
        children: [
          // ✕ Пропустить
          _CircleBtn(
            onTap: onSkip,
            icon: Icons.close_rounded,
            color: kTextSecondary,
          ),
          const SizedBox(width: AppSpacing.md),

          // ♡ Избранное
          _CircleBtn(
            onTap: onFavourite,
            icon: Icons.favorite_border_rounded,
            color: kRose,
          ),
          const SizedBox(width: AppSpacing.md),

          // 📅 Записаться (шире)
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onBook,
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Записаться'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kBgPrimary,
                  shape: const StadiumBorder(),
                  textStyle: AppTextStyles.label
                      .copyWith(fontWeight: FontWeight.w700, color: kBgPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.onTap, required this.icon, required this.color});
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kBgSecondary,
          border: Border.all(color: kBorder2),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

// ─── Боттом-шит фильтров (C-1a) ──────────────────────────────────
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late FeedFilter _local;

  @override
  void initState() {
    super.initState();
    _local = ref.read(feedFilterProvider);
  }

  void _apply() {
    ref.read(feedFilterProvider.notifier).state = _local;
    ref.read(feedProvider.notifier).reload(_local);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ручка
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: kBorder2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text('Фильтры', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xl),

          Text('Радиус поиска', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Slider(
            value: _local.radius.toDouble(),
            min: 500,
            max: 20000,
            divisions: 39,
            activeColor: kGold,
            inactiveColor: kBorder2,
            label: '${(_local.radius / 1000).toStringAsFixed(1)} км',
            onChanged: (v) => setState(
                () => _local = _local.copyWith(radius: v.round())),
          ),

          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: kBgPrimary,
                shape: const StadiumBorder(),
              ),
              child: Text('Применить',
                  style: AppTextStyles.label
                      .copyWith(fontWeight: FontWeight.w700, color: kBgPrimary)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
