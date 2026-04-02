import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/data/service_template.dart';
import '../data/feed_models.dart';
import '../providers/feed_provider.dart';
import '../providers/stories_provider.dart';
import '../widgets/master_card.dart';
import '../widgets/story_circle.dart';

// ─── Категории-чипы ──────────────────────────────────────────────
const _kCategories = [
  (label: 'Все',         code: null),
  (label: 'Маникюр',    code: 'MANICURE'),
  (label: 'Педикюр',    code: 'PEDICURE'),
  (label: 'Стрижка',    code: 'HAIRCUT'),
  (label: 'Окрашивание',code: 'COLORING'),
  (label: 'Макияж',     code: 'MAKEUP'),
  (label: 'Ресницы',    code: 'LASHES'),
  (label: 'Брови',      code: 'BROWS'),
  (label: 'Уход',       code: 'SKINCARE'),
];

// ─── Режим отображения ────────────────────────────────────────────
enum _FeedMode { list, swipe }

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _swiperCtrl = CardSwiperController();
  _FeedMode _mode = _FeedMode.list;
  String? _selectedCategory; // null = Все

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filter = ref.read(feedFilterProvider);
      ref.read(feedProvider.notifier).init(filter);
      _loadStories();
    });
  }

  Future<void> _loadStories() async {
    final repo = ref.read(feedRepositoryProvider);
    final pos = await repo.getCurrentPosition();
    ref.read(storiesProvider.notifier).load(
          lat: pos?.latitude ?? 51.1694,
          lng: pos?.longitude ?? 71.4491,
        );
  }

  @override
  void dispose() {
    _swiperCtrl.dispose();
    super.dispose();
  }

  List<FeedMaster> get _filteredMasters {
    final all = ref.watch(feedProvider).cards;
    if (_selectedCategory == null) return all;
    return all
        .where((m) => m.specializations.contains(_selectedCategory))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStoriesRow(),
            _buildToggleAndChips(),
            const Divider(color: kBorder, height: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ─── Шапка ───────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text('MIRAKU',
              style: AppTextStyles.title
                  .copyWith(letterSpacing: 4, color: kGold, fontSize: 18)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: kTextSecondary),
            onPressed: () => _showFilter(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─── Сторисы ─────────────────────────────────────────────────────
  Widget _buildStoriesRow() {
    final storiesState = ref.watch(storiesProvider);

    if (storiesState.loading && storiesState.items.isEmpty) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2)),
      );
    }

    if (storiesState.items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: storiesState.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final story = storiesState.items[i];
          return StoryCircle(
            story: story,
            isViewed: storiesState.viewedIds.contains(story.id),
            onTap: () => _openStory(storiesState.items, i),
          );
        },
      ),
    );
  }

  void _openStory(List<StoryItem> stories, int initialIndex) {
    context.push('/stories', extra: {
      'stories': stories,
      'initialIndex': initialIndex,
    });
  }

  // ─── Переключатель + чипы ─────────────────────────────────────────
  Widget _buildToggleAndChips() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
          child: Row(
            children: [
              // Счётчик мастеров
              Consumer(builder: (_, ref, __) {
                final count = ref.watch(feedProvider).cards.length;
                return Text(
                  '$count мастеров рядом',
                  style: AppTextStyles.caption,
                );
              }),
              const Spacer(),
              // Переключатель Лента / Свайп
              _ModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
            ],
          ),
        ),

        // Чипы категорий
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: _kCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final cat = _kCategories[i];
              final isSelected = _selectedCategory == cat.code;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? kGold : kBgSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: isSelected ? kGold : kBorder2),
                  ),
                  child: Text(
                    cat.label,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? kBgPrimary : kTextSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // ─── Основной контент ─────────────────────────────────────────────
  Widget _buildBody() {
    final state = ref.watch(feedProvider);
    final masters = _filteredMasters;

    if (state.loading && state.cards.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kGold));
    }

    if (masters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: kTextTertiary, size: 56),
            const SizedBox(height: AppSpacing.md),
            Text('Мастеров не найдено',
                style: AppTextStyles.subtitle
                    .copyWith(color: kTextSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text('Попробуйте другую категорию или увеличьте радиус',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return _mode == _FeedMode.list
        ? _buildListMode(masters)
        : _buildSwipeMode(state);
  }

  // ─── Режим Лента ─────────────────────────────────────────────────
  Widget _buildListMode(List<FeedMaster> masters) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xl),
      itemCount: masters.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _MasterListCard(master: masters[i]),
    );
  }

  // ─── Режим Свайп ─────────────────────────────────────────────────
  Widget _buildSwipeMode(FeedState state) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CardSwiper(
              controller: _swiperCtrl,
              cardsCount: state.cards.length,
              onSwipe: (prev, next, dir) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) ref.read(feedProvider.notifier).removeTop();
                });
                return true;
              },
              numberOfCardsDisplayed:
                  (state.cards.length - 1).clamp(1, 3),
              backCardOffset: const Offset(0, 20),
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              cardBuilder: (ctx, index, _, __) {
                if (index >= state.cards.length) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => context.push(
                      AppRoutes.masterPublicProfile(state.cards[index].id)),
                  child: MasterCard(master: state.cards[index]),
                );
              },
            ),
          ),
        ),
        if (state.cards.isNotEmpty)
          _SwipeActionBar(
            onSkip: () => _swiperCtrl.swipe(CardSwiperDirection.left),
            onFavourite: () => _handleFavourite(state.cards.first),
            onBook: () =>
                context.push(AppRoutes.masterPublicProfile(state.cards.first.id)),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _handleFavourite(FeedMaster master) async {
    _swiperCtrl.swipe(CardSwiperDirection.top);
    try {
      await createDio().post('/favourites/${master.id}');
    } catch (_) {}
    if (!mounted) return;
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }
}

// ─── Переключатель режима ─────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final _FeedMode mode;
  final ValueChanged<_FeedMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: kBorder2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.list_rounded,
            label: 'Лента',
            active: mode == _FeedMode.list,
            onTap: () => onChanged(_FeedMode.list),
          ),
          _ToggleBtn(
            icon: Icons.swap_horiz_rounded,
            label: 'Свайп',
            active: mode == _FeedMode.swipe,
            onTap: () => onChanged(_FeedMode.swipe),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? kGold : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? kBgPrimary : kTextSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: active ? kBgPrimary : kTextSecondary,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Горизонтальная карточка мастера (режим Лента) ───────────────
class _MasterListCard extends StatelessWidget {
  const _MasterListCard({required this.master});
  final FeedMaster master;

  static const _catLabels = {
    'MANICURE': 'Маникюр', 'PEDICURE': 'Педикюр',
    'HAIRCUT': 'Стрижка',  'COLORING': 'Окрашивание',
    'MAKEUP': 'Макияж',    'LASHES': 'Ресницы',
    'BROWS': 'Брови',      'SKINCARE': 'Уход', 'OTHER': 'Другое',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.masterPublicProfile(master.id)),
      child: Container(
        decoration: BoxDecoration(
          color: kBgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Фото ────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.md),
                    bottomLeft: Radius.circular(AppRadius.md),
                  ),
                  child: master.coverUrl != null
                      ? Image.network(
                          master.coverUrl!,
                          width: 110,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
                if (master.isBoosted)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: kGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ТОП',
                          style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0F))),
                    ),
                  ),
              ],
            ),

            // ─── Информация ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя + расстояние
                    Row(
                      children: [
                        Expanded(
                          child: Text(master.name,
                              style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(master.distanceLabel,
                            style: AppTextStyles.caption
                                .copyWith(color: kGold)),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Рейтинг
                    if (master.rating != null) ...[
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: kGold, size: 13),
                        const SizedBox(width: 2),
                        Text(master.rating!.toStringAsFixed(1),
                            style: AppTextStyles.caption
                                .copyWith(color: kGold)),
                        const SizedBox(width: 4),
                        Text('(${master.reviewCount})',
                            style: AppTextStyles.caption),
                      ]),
                      const SizedBox(height: 4),
                    ],

                    // Специализации
                    if (master.specializations.isNotEmpty) ...[
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: master.specializations
                            .take(3)
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kBgTertiary,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    border:
                                        Border.all(color: kBorder2),
                                  ),
                                  child: Text(
                                      _catLabels[s] ?? s,
                                      style: AppTextStyles.caption
                                          .copyWith(fontSize: 10)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Цена + кнопка
                    Row(
                      children: [
                        if (master.minPrice != null)
                          Text(
                            'от ${master.minPrice} ₸',
                            style: AppTextStyles.caption.copyWith(
                                color: kTextSecondary),
                          ),
                        const Spacer(),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () => context.push(
                                AppRoutes.masterPublicProfile(
                                    master.id)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGold,
                              foregroundColor: kBgPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              shape: const StadiumBorder(),
                              textStyle: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: kBgPrimary,
                              ),
                            ),
                            child: const Text('Записаться'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 110,
      height: 130,
      color: kBgTertiary,
      child: Center(
        child: Text(
          master.name.isNotEmpty ? master.name[0].toUpperCase() : 'M',
          style: AppTextStyles.h1.copyWith(color: kGold),
        ),
      ),
    );
  }
}

// ─── Кнопки свайп-режима ─────────────────────────────────────────
class _SwipeActionBar extends StatelessWidget {
  const _SwipeActionBar({
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
          _CircleBtn(onTap: onSkip, icon: Icons.close_rounded, color: kTextSecondary),
          const SizedBox(width: AppSpacing.md),
          _CircleBtn(onTap: onFavourite, icon: Icons.favorite_border_rounded, color: kRose),
          const SizedBox(width: AppSpacing.md),
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
  const _CircleBtn(
      {required this.onTap, required this.icon, required this.color});
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
  final _maxPriceCtrl = TextEditingController();
  ServiceTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _local = ref.read(feedFilterProvider);
    if (_local.maxPrice != null) {
      _maxPriceCtrl.text = _local.maxPrice.toString();
    }
  }

  @override
  void dispose() {
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final maxPrice = int.tryParse(_maxPriceCtrl.text.trim());
    final filter = FeedFilter(
      serviceTemplateId: _selectedTemplate?.id,
      maxPrice: maxPrice,
      radius: _local.radius,
    );
    ref.read(feedFilterProvider.notifier).state = filter;
    ref.read(feedProvider.notifier).reload(filter);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _selectedTemplate = null;
      _maxPriceCtrl.clear();
      _local = const FeedFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(serviceTemplatesProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                  color: kBorder2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(children: [
            Text('Фильтры', style: AppTextStyles.title),
            const Spacer(),
            TextButton(
              onPressed: _reset,
              child: Text('Сбросить',
                  style: AppTextStyles.caption
                      .copyWith(color: kTextTertiary)),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          Text('Услуга', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          templatesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: kGold)),
            error: (_, __) => const SizedBox.shrink(),
            data: (templates) => _ServiceDropdown(
              templates: templates,
              selected: _selectedTemplate,
              onChanged: (t) => setState(() => _selectedTemplate = t),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Максимальная цена (₸)', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _maxPriceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Например: 5000',
              hintStyle:
                  AppTextStyles.body.copyWith(color: kTextTertiary),
              suffixText: '₸',
              suffixStyle:
                  AppTextStyles.body.copyWith(color: kTextSecondary),
              filled: true,
              fillColor: kBgTertiary,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: kGold)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Радиус поиска', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Slider(
            value: _local.radius.toDouble(),
            min: 500,
            max: 20000,
            divisions: 39,
            activeColor: kGold,
            inactiveColor: kBorder2,
            label: '${(_local.radius / 1000).toStringAsFixed(1)} км',
            onChanged: (v) =>
                setState(() => _local = _local.copyWith(radius: v.round())),
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
                  style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700, color: kBgPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceDropdown extends StatelessWidget {
  const _ServiceDropdown({
    required this.templates,
    required this.selected,
    required this.onChanged,
  });
  final List<ServiceTemplate> templates;
  final ServiceTemplate? selected;
  final ValueChanged<ServiceTemplate?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: kBgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: selected != null ? kGold : kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ServiceTemplate?>(
          value: selected,
          isExpanded: true,
          dropdownColor: kBgSecondary,
          style: AppTextStyles.body,
          icon: const Icon(Icons.expand_more,
              color: kTextTertiary, size: 20),
          hint: Text('Любая услуга',
              style: AppTextStyles.body.copyWith(color: kTextTertiary)),
          items: [
            DropdownMenuItem<ServiceTemplate?>(
              value: null,
              child: Text('Любая услуга',
                  style:
                      AppTextStyles.body.copyWith(color: kTextTertiary)),
            ),
            ...templates.map((t) => DropdownMenuItem<ServiceTemplate?>(
                  value: t,
                  child: Text(t.name, style: AppTextStyles.body),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
