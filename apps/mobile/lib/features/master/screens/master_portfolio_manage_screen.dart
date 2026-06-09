import 'package:cached_network_image/cached_network_image.dart';
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
      ref.refresh(_portfolioProvider);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(String id) async {
    await createDio().delete('/master/portfolio/$id');
    ref.refresh(_portfolioProvider);
  }

  Future<void> _reorder(List<String> ids) async {
    try {
      await createDio().put('/master/portfolio/reorder', data: {'ids': ids});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_portfolioProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.portfolio, style: AppTextStyles.title),
        leading: BackButton(
            color: context.colors.textPrimary,
            onPressed: () => Navigator.pop(context)),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                  width: 20,
                  height: 20,
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
                  Icon(Icons.photo_library_outlined,
                      color: context.colors.textTertiary, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text('Нет фото',
                      style: AppTextStyles.subtitle
                          .copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Зажмите фото для перетаскивания',
                      style: AppTextStyles.caption
                          .copyWith(color: context.colors.textTertiary)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, 0),
                child: Text(
                  'Зажмите и перетащите · первое фото — обложка',
                  style: AppTextStyles.caption
                      .copyWith(color: context.colors.textTertiary),
                ),
              ),
              Expanded(
                child: _DraggablePhotoGrid(
                  photos: photos,
                  onReorder: _reorder,
                  onDelete: _delete,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DraggablePhotoGrid extends StatefulWidget {
  const _DraggablePhotoGrid({
    required this.photos,
    required this.onReorder,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> photos;
  final Future<void> Function(List<String> ids) onReorder;
  final Future<void> Function(String id) onDelete;

  @override
  State<_DraggablePhotoGrid> createState() => _DraggablePhotoGridState();
}

class _DraggablePhotoGridState extends State<_DraggablePhotoGrid> {
  late List<Map<String, dynamic>> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
  }

  @override
  void didUpdateWidget(_DraggablePhotoGrid old) {
    super.didUpdateWidget(old);
    if (old.photos != widget.photos) {
      _photos = List.from(widget.photos);
    }
  }

  void _move(String fromId, String toId) {
    final fromIndex = _photos.indexWhere((p) => p['id'] == fromId);
    final toIndex = _photos.indexWhere((p) => p['id'] == toId);
    if (fromIndex == -1 || toIndex == -1 || fromIndex == toIndex) return;
    setState(() {
      final item = _photos.removeAt(fromIndex);
      _photos.insert(toIndex, item);
    });
    widget.onReorder(_photos.map((p) => p['id'] as String).toList());
  }

  @override
  Widget build(BuildContext context) {
    const cols = 3;
    final screenW = MediaQuery.of(context).size.width;
    final cellSize =
        (screenW - 2 * AppSpacing.screenH - (cols - 1) * AppSpacing.sm) / cols;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: _photos.length,
      itemBuilder: (ctx, i) {
        final photo = _photos[i];
        final url = photo['url'] as String;
        final id = photo['id'] as String;
        final isCover = i == 0;

        return DragTarget<String>(
          key: ValueKey(id),
          onWillAcceptWithDetails: (details) => details.data != id,
          onAcceptWithDetails: (details) => _move(details.data, id),
          builder: (ctx, candidates, _) {
            return LongPressDraggable<String>(
              data: id,
              delay: const Duration(milliseconds: 300),
              feedback: SizedBox(
                width: cellSize,
                height: cellSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Opacity(
                    opacity: 0.9,
                    child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                  ),
                ),
              ),
              childWhenDragging: Container(
                decoration: BoxDecoration(
                  color: context.colors.bgTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                      color: kGold.withValues(alpha: 0.3), width: 1.5),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Drop-target highlight
                  if (candidates.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: kGold, width: 2),
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                  ),
                  // Обложка
                  if (isCover)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: kGold,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          'Обложка',
                          style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF0A0A0F), fontSize: 10),
                        ),
                      ),
                    ),
                  // Удалить
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => widget.onDelete(id),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
