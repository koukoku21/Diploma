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
    // Defer state update to post-frame so the swiper animation finishes
    // cleanly before the widget tree rebuilds (avoids setState-after-dispose).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(feedProvider.notifier).removeTop();
    });
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
              numberOfCardsDisplayed: (state.cards.length - 1).clamp(1, 3),
              backCardOffset: const Offset(0, 20),
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              cardBuilder: (ctx, index, _, __) {
                // Guard against library bug: swiper may request out-of-bounds
                // indices during swipe animation transitions
                if (index >= state.cards.length) return const SizedBox.shrink();
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

  Future<void> _handleFavourite(FeedMaster master) async {
    _swiperCtrl.swipe(CardSwiperDirection.top);
    try {
      await createDio().post('/favourites/${master.id}');
    } catch (_) {
      // ignore — favourite may already exist
    }
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

          Row(
            children: [
              Text('Фильтры', style: AppTextStyles.title),
              const Spacer(),
              TextButton(
                onPressed: _reset,
                child: Text('Сбросить',
                    style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Услуга ─────────────────────────────────────────────
          Text('Услуга', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          templatesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: kGold)),
            error: (_, __) => const SizedBox.shrink(),
            data: (templates) => _ServiceDropdown(
              templates: templates,
              selected: _selectedTemplate,
              onChanged: (t) => setState(() => _selectedTemplate = t),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Цена до ────────────────────────────────────────────
          Text('Максимальная цена (₸)', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _maxPriceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Например: 5000',
              hintStyle: AppTextStyles.body.copyWith(color: kTextTertiary),
              suffixText: '₸',
              suffixStyle: AppTextStyles.body.copyWith(color: kTextSecondary),
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

          // ─── Радиус ─────────────────────────────────────────────
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
                  style: AppTextStyles.label
                      .copyWith(fontWeight: FontWeight.w700, color: kBgPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Дропдаун услуг ──────────────────────────────────────────────
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
          icon: const Icon(Icons.expand_more, color: kTextTertiary, size: 20),
          hint: Text('Любая услуга',
              style: AppTextStyles.body.copyWith(color: kTextTertiary)),
          items: [
            // Пункт "Любая" — сбрасывает фильтр
            DropdownMenuItem<ServiceTemplate?>(
              value: null,
              child: Text('Любая услуга',
                  style: AppTextStyles.body.copyWith(color: kTextTertiary)),
            ),
            // Разделитель по категориям
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
