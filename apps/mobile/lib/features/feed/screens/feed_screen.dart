import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).init(ref.read(feedFilterProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        centerTitle: true,
        title: Text(
          'MIRAKU',
          style: AppTextStyles.title.copyWith(
            letterSpacing: 4,
            color: kGold,
          ),
        ),
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
            Text(
              'Мастеров не найдено',
              style: AppTextStyles.subtitle.copyWith(color: kTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Попробуйте изменить фильтры',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kGold,
      backgroundColor: kBgSecondary,
      onRefresh: () async {
        await ref.read(feedProvider.notifier).reload(ref.read(feedFilterProvider));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        itemCount: state.cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, index) {
          final master = state.cards[index];
          return _MasterListCard(
            master: master,
            onTap: () => context.push(AppRoutes.masterPublicProfile(master.id)),
            onFavourite: () => _handleFavourite(master),
            onBook: () => context.push(AppRoutes.masterPublicProfile(master.id)),
          );
        },
      ),
    );
  }

  Future<void> _handleFavourite(FeedMaster master) async {
  try {
    await createDio().post('/favourites/${master.id}');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${master.name} добавлен в избранное',
          style: AppTextStyles.caption.copyWith(color: kTextPrimary),
        ),
        backgroundColor: kBgSecondary,
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Не удалось добавить в избранное',
          style: AppTextStyles.caption.copyWith(color: kTextPrimary),
        ),
        backgroundColor: kBgSecondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
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

class _MasterListCard extends StatelessWidget {
  const _MasterListCard({
    required this.master,
    required this.onTap,
    required this.onFavourite,
    required this.onBook,
  });

  final FeedMaster master;
  final VoidCallback onTap;
  final VoidCallback onFavourite;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kBgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: master.coverUrl != null
                  ? Image.network(
                      master.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(master.name, style: AppTextStyles.subtitle),
                  const SizedBox(height: 4),
                  if (master.specializations.isNotEmpty)
                    Text(
                      master.specializations.take(3).join(' · '),
                      style: AppTextStyles.caption.copyWith(color: kGold),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    master.address,
                    style: AppTextStyles.caption.copyWith(color: kTextSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (master.rating != null) ...[
                        const Icon(Icons.star_rounded, color: kGold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${master.rating!.toStringAsFixed(1)} (${master.reviewCount})',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      const Icon(
                        Icons.location_on_outlined,
                        color: kTextTertiary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(master.distanceLabel, style: AppTextStyles.caption),
                      const Spacer(),
                      if (master.minPrice != null)
                        Text(
                          'от ${master.minPrice}₸',
                          style: AppTextStyles.label.copyWith(color: kGold),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onFavourite,
                          icon: const Icon(Icons.favorite_border_rounded, size: 18),
                          label: const Text('Избранное'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onBook,
                          icon: const Icon(Icons.calendar_month_outlined, size: 18),
                          label: const Text('Записаться'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: kBgTertiary,
      child: const Center(
        child: Icon(Icons.person_outline, color: kTextTertiary, size: 56),
      ),
    );
  }
}

// ─── Боттом-шит фильтров ─────────────────────────────────────────
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
                child: Text(
                  'Сбросить',
                  style: AppTextStyles.caption.copyWith(color: kTextTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Услуга', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          templatesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: kGold),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (templates) {
              ServiceTemplate? selected = _selectedTemplate;

              if (selected == null && _local.serviceTemplateId != null) {
                for (final template in templates) {
                  if (template.id == _local.serviceTemplateId) {
                    selected = template;
                    break;
                  }
                }
              }

              return _ServiceDropdown(
                templates: templates,
                selected: _selectedTemplate,
                onChanged: (t) => setState(() => _selectedTemplate = t),
              );
            },
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
            onChanged: (v) {
              setState(() => _local = _local.copyWith(radius: v.round()));
            },
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
              child: Text(
                'Применить',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: kBgPrimary,
                ),
              ),
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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
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
          hint: Text(
            'Любая услуга',
            style: AppTextStyles.body.copyWith(color: kTextTertiary),
          ),
          items: [
            DropdownMenuItem<ServiceTemplate?>(
              value: null,
              child: Text(
                'Любая услуга',
                style: AppTextStyles.body.copyWith(color: kTextTertiary),
              ),
            ),
            ...templates.map(
              (t) => DropdownMenuItem<ServiceTemplate?>(
                value: t,
                child: Text(t.name, style: AppTextStyles.body),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
