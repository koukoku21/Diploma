import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';

final _favouritesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await createDio().get('/favourites');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_favouritesProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Избранное', style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Text(
              'Не удалось загрузить избранное. Проверьте интернет и попробуйте ещё раз.',
              style: AppTextStyles.body.copyWith(color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (favs) {
          if (favs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_border, color: kTextTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет избранных мастеров',
                      style: AppTextStyles.subtitle.copyWith(color: kTextSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Нажмите ♡ в ленте, чтобы сохранить мастера',
                      style: AppTextStyles.caption, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kGold,
            backgroundColor: kBgSecondary,
            onRefresh: () => ref.refresh(_favouritesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final fav    = favs[i];
                final master = fav['master'] as Map<String, dynamic>;
                final user   = master['user'] as Map<String, dynamic>?;
                final photos = master['portfolioPhotos'] as List?;
                final specs  = master['specializations'] as List?;
                final masterId = master['id'] as String;
                final name  = user?['name'] as String? ?? '';
                final cover = (photos?.isNotEmpty == true)
                    ? (photos!.first as Map)['url'] as String? : null;

                return GestureDetector(
                  onTap: () => context.push(AppRoutes.masterPublicProfile(masterId)),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: kBgSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: cover != null
                              ? Image.network(cover, width: 64, height: 64, fit: BoxFit.cover)
                              : Container(width: 64, height: 64, color: kBgTertiary,
                                  child: const Icon(Icons.person_outline,
                                      color: kTextTertiary, size: 32)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTextStyles.subtitle),
                              if (specs?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  (specs!.take(2).map((s) =>
                                      (s as Map)['category'].toString()
                                  )).join(' · ').toUpperCase(),
                                  style: AppTextStyles.overline,
                                ),
                              ],
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            try {
                              await createDio().delete('/favourites/$masterId'); 
                            
                            // ignore: unused_result
                            ref.refresh(_favouritesProvider);

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$name удалён из избранного',
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
                                    'Не удалось удалить из избранного',
                                    style: AppTextStyles.caption.copyWith(color: kTextPrimary),
                                  ),
                                  backgroundColor: kBgSecondary,
                                ),
                              );
                            }
                          },
                          child: const Icon(Icons.favorite, color: kRose, size: 22),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
