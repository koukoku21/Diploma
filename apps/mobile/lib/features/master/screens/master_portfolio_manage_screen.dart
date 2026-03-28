import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';

final _portfolioProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await createDio().get('/master/portfolio');
  return (res.data as List).cast<Map<String, dynamic>>();
});

// M-10: Управление портфолио
class MasterPortfolioManageScreen extends ConsumerStatefulWidget {
  const MasterPortfolioManageScreen({super.key});

  @override
  ConsumerState<MasterPortfolioManageScreen> createState() =>
      _MasterPortfolioManageScreenState();
}

class _MasterPortfolioManageScreenState
    extends ConsumerState<MasterPortfolioManageScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _addPhoto() async {
    final result = await _picker.pickMultiImage(imageQuality: 85);
    if (result.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final dio = createDio();
      for (final photo in result) {
        final bytes = await photo.readAsBytes();
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: photo.name),
        });
        await dio.post('/master/portfolio/upload', data: formData);
      }
      // ignore: unused_result
      ref.refresh(_portfolioProvider);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(String id) async {
    await createDio().delete('/master/portfolio/$id');
    // ignore: unused_result
    ref.refresh(_portfolioProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_portfolioProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Портфолио', style: AppTextStyles.title),
        leading: BackButton(color: kTextPrimary, onPressed: () => Navigator.pop(context)),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: kGold, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined, color: kGold),
              onPressed: _addPhoto,
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (photos) {
          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      color: kTextTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет фото', style: AppTextStyles.subtitle.copyWith(color: kTextSecondary)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: photos.length,
            itemBuilder: (_, i) {
              final photo = photos[i];
              final url = photo['url'] as String;
              final id = photo['id'] as String;
              final isCover = photo['isCover'] as bool? ?? false;

              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                  if (isCover)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Обложка',
                            style: AppTextStyles.caption.copyWith(
                                color: kBgPrimary, fontSize: 10)),
                      ),
                    ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => _delete(id),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
