import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/data/service_template.dart';
import '../../feed/data/feed_models.dart';

// ─── Фильтр каталога ─────────────────────────────────────────────
class _CatalogFilter {
  const _CatalogFilter({
    this.serviceTemplate,
    this.maxPrice,
    this.query = '',
  });
  final ServiceTemplate? serviceTemplate;
  final int? maxPrice;
  final String query;

  _CatalogFilter copyWith({
    Object? serviceTemplate = _sentinel,
    Object? maxPrice = _sentinel,
    String? query,
  }) =>
      _CatalogFilter(
        serviceTemplate: serviceTemplate == _sentinel
            ? this.serviceTemplate
            : serviceTemplate as ServiceTemplate?,
        maxPrice:
            maxPrice == _sentinel ? this.maxPrice : maxPrice as int?,
        query: query ?? this.query,
      );
}

const _sentinel = Object();

final _catalogFilterProvider =
    StateProvider<_CatalogFilter>((ref) => const _CatalogFilter());

final _catalogProvider =
    FutureProvider.autoDispose.family<List<FeedMaster>, _CatalogFilter>(
  (ref, filter) async {
    final params = <String, dynamic>{
      'lat': 51.1694,
      'lng': 71.4491,
      'radius': 25000,
      'offset': 0,
    };
    if (filter.serviceTemplate != null) {
      params['serviceTemplateId'] = filter.serviceTemplate!.id;
    }
    if (filter.maxPrice != null) params['maxPrice'] = filter.maxPrice;
    if (filter.query.isNotEmpty) params['q'] = filter.query;

    final res = await createDio().get('/feed', queryParameters: params);
    return FeedResponse.fromJson(res.data as Map<String, dynamic>).items;
  },
);

// ─── Screen ──────────────────────────────────────────────────────

// C-Catalog: Каталог мастеров
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet(
      BuildContext context, List<ServiceTemplate> templates) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _CatalogFilterSheet(
        templates: templates,
        current: ref.read(_catalogFilterProvider),
        onApply: (f) {
          ref.read(_catalogFilterProvider.notifier).state = f;
          _priceCtrl.text = f.maxPrice?.toString() ?? '';
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(_catalogFilterProvider);
    final async = ref.watch(_catalogProvider(filter));
    final templatesAsync = ref.watch(serviceTemplatesProvider);

    final hasFilters =
        filter.serviceTemplate != null || filter.maxPrice != null;

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.catalogTitle, style: AppTextStyles.title),
        actions: [
          templatesAsync.whenData((templates) => IconButton(
                icon: Badge(
                  isLabelVisible: hasFilters,
                  backgroundColor: kGold,
                  child: Icon(Icons.tune_rounded, color: context.colors.textSecondary),
                ),
                onPressed: () => _showFilterSheet(context, templates),
              )).valueOrNull ??
              const SizedBox.shrink(),
          if (hasFilters)
            TextButton(
              onPressed: () {
                ref.read(_catalogFilterProvider.notifier).state =
                    _CatalogFilter(query: filter.query);
              },
              child: Text(context.l10n.resetFilter,
                  style: AppTextStyles.caption.copyWith(color: kGold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.sm),
            child: TextField(
              controller: _searchCtrl,
              style: AppTextStyles.body,
              onChanged: (v) => ref
                  .read(_catalogFilterProvider.notifier)
                  .update((s) => s.copyWith(query: v)),
              decoration: InputDecoration(
                hintText: context.l10n.searchMaster,
                hintStyle:
                    AppTextStyles.body.copyWith(color: context.colors.textTertiary),
                prefixIcon:
                    Icon(Icons.search, color: context.colors.textTertiary, size: 20),
                suffixIcon: filter.query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          ref
                              .read(_catalogFilterProvider.notifier)
                              .update((s) => s.copyWith(query: ''));
                        },
                        child: Icon(Icons.close,
                            color: context.colors.textTertiary, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: context.colors.bgSecondary,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: kGold),
                ),
              ),
            ),
          ),

          // ─── Active filter chip ────────────────────────────────
          if (filter.serviceTemplate != null || filter.maxPrice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (filter.serviceTemplate != null)
                      _ActiveChip(
                        label: filter.serviceTemplate!.name,
                        onRemove: () => ref
                            .read(_catalogFilterProvider.notifier)
                            .update(
                                (s) => s.copyWith(serviceTemplate: null)),
                      ),
                    if (filter.maxPrice != null)
                      _ActiveChip(
                        label: 'до ${filter.maxPrice} ₸',
                        onRemove: () => ref
                            .read(_catalogFilterProvider.notifier)
                            .update((s) => s.copyWith(maxPrice: null)),
                      ),
                  ],
                ),
              ),
            ),

          Divider(color: context.colors.border, height: 1),

          // ─── Master list ───────────────────────────────────────
          Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: kGold)),
              error: (e, _) => Center(
                  child: Text(context.l10n.errorWithDetails(e.toString()),
                      style: AppTextStyles.caption
                          .copyWith(color: context.colors.textSecondary))),
              data: (masters) {
                if (masters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            color: context.colors.textTertiary, size: 48),
                        const SizedBox(height: AppSpacing.md),
                        Text(context.l10n.mastersNotFound,
                            style: AppTextStyles.body
                                .copyWith(color: context.colors.textSecondary)),
                        if (hasFilters) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(context.l10n.tryChangeFilters,
                              style: AppTextStyles.caption
                                  .copyWith(color: context.colors.textTertiary)),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH,
                      vertical: AppSpacing.md),
                  itemCount: masters.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) =>
                      _MasterListTile(master: masters[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active filter chip ───────────────────────────────────────────
class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: kGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: kGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  AppTextStyles.caption.copyWith(color: kGold)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: kGold),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────
class _CatalogFilterSheet extends StatefulWidget {
  const _CatalogFilterSheet({
    required this.templates,
    required this.current,
    required this.onApply,
  });
  final List<ServiceTemplate> templates;
  final _CatalogFilter current;
  final ValueChanged<_CatalogFilter> onApply;

  @override
  State<_CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<_CatalogFilterSheet> {
  ServiceTemplate? _selectedTemplate;
  final _maxPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.current.serviceTemplate;
    if (widget.current.maxPrice != null) {
      _maxPriceCtrl.text = widget.current.maxPrice.toString();
    }
  }

  @override
  void dispose() {
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: context.colors.border2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              Text(context.l10n.filterTitle, style: AppTextStyles.title),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _selectedTemplate = null;
                  _maxPriceCtrl.clear();
                }),
                child: Text(context.l10n.resetFilter,
                    style:
                        AppTextStyles.caption.copyWith(color: context.colors.textTertiary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Тип услуги ─────────────────────────────────────
          Text(context.l10n.serviceType, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: context.colors.bgTertiary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                  color: _selectedTemplate != null ? kGold : context.colors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServiceTemplate?>(
                value: _selectedTemplate,
                isExpanded: true,
                dropdownColor: context.colors.bgSecondary,
                style: AppTextStyles.body.copyWith(color: context.colors.textPrimary),
                icon: Icon(Icons.expand_more,
                    color: context.colors.textTertiary, size: 20),
                hint: Text(context.l10n.anyService,
                    style:
                        AppTextStyles.body.copyWith(color: context.colors.textTertiary)),
                items: [
                  DropdownMenuItem<ServiceTemplate?>(
                    value: null,
                    child: Text(context.l10n.anyService,
                        style: AppTextStyles.body
                            .copyWith(color: context.colors.textTertiary)),
                  ),
                  ...widget.templates.map((t) =>
                      DropdownMenuItem<ServiceTemplate?>(
                        value: t,
                        child: Text(t.name, style: AppTextStyles.body.copyWith(color: context.colors.textPrimary)),
                      )),
                ],
                onChanged: (t) => setState(() => _selectedTemplate = t),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Цена до ────────────────────────────────────────
          Text(context.l10n.maxPriceFilter, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _maxPriceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: context.l10n.priceHint,
              hintStyle:
                  AppTextStyles.body.copyWith(color: context.colors.textTertiary),
              suffixText: '₸',
              suffixStyle:
                  AppTextStyles.body.copyWith(color: context.colors.textSecondary),
              filled: true,
              fillColor: context.colors.bgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: context.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: context.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: kGold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_CatalogFilter(
                  serviceTemplate: _selectedTemplate,
                  maxPrice: int.tryParse(_maxPriceCtrl.text.trim()),
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: context.colors.bgPrimary,
                shape: const StadiumBorder(),
              ),
              child: Text(context.l10n.applyFilter,
                  style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700, color: context.colors.bgPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Master list tile ─────────────────────────────────────────────
class _MasterListTile extends StatelessWidget {
  const _MasterListTile({required this.master});
  final FeedMaster master;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.masterPublicProfile(master.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            // ─── Avatar / Cover ────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 64,
                height: 64,
                child: master.coverUrl != null
                    ? CachedNetworkImage(imageUrl: master.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, __, ___) => _placeholder(ctx))
                    : master.avatarUrl != null
                        ? CachedNetworkImage(imageUrl: master.avatarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (ctx, __, ___) => _placeholder(ctx))
                        : _placeholder(context),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // ─── Info ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(master.name, style: AppTextStyles.label),
                  if (master.specializations.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      master.specializations
                          .map(ServiceTemplate.categoryLabel)
                          .take(2)
                          .join(' · '),
                      style: AppTextStyles.caption
                          .copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (master.rating != null) ...[
                        const Icon(Icons.star_rounded,
                            size: 12, color: kGold),
                        const SizedBox(width: 2),
                        Text(
                          master.rating!.toStringAsFixed(1),
                          style: AppTextStyles.caption
                              .copyWith(color: kGold),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Icon(Icons.location_on_outlined,
                          size: 12, color: context.colors.textTertiary),
                      const SizedBox(width: 2),
                      Text(master.distanceLabel,
                          style: AppTextStyles.caption
                              .copyWith(color: context.colors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Price ─────────────────────────────────────────
            if (master.minPrice != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(context.l10n.fromPrice,
                      style: AppTextStyles.caption
                          .copyWith(color: context.colors.textTertiary)),
                  Text(
                    '${master.minPrice}₸',
                    style: AppTextStyles.label.copyWith(color: kGold),
                  ),
                ],
              ),
            ],

            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right,
                color: context.colors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        color: context.colors.bgTertiary,
        child: Icon(Icons.person_outline,
            color: context.colors.textTertiary, size: 32),
      );
}
