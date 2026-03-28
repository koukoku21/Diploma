import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/network/dio_client.dart';

// M-3: Загрузка портфолио (минимум 3 фото)
class MasterPortfolioScreen extends ConsumerStatefulWidget {
  const MasterPortfolioScreen({super.key});

  @override
  ConsumerState<MasterPortfolioScreen> createState() =>
      _MasterPortfolioScreenState();
}

class _MasterPortfolioScreenState
    extends ConsumerState<MasterPortfolioScreen> {
  final _picker = ImagePicker();

  // Храним пары (XFile, байты) — байты нужны для предпросмотра и загрузки
  final _photos = <({XFile file, Uint8List bytes})>[];
  bool _loading = false;

  Future<void> _pick() async {
    final result = await _picker.pickMultiImage(imageQuality: 85);
    if (result.isEmpty) return;
    final newItems = await Future.wait(
      result.map((f) async => (file: f, bytes: await f.readAsBytes())),
    );
    setState(() {
      _photos.addAll(newItems);
      if (_photos.length > 20) _photos.removeRange(20, _photos.length);
    });
  }

  void _remove(int i) => setState(() => _photos.removeAt(i));

  Future<void> _upload() async {
    if (_photos.length < 3) return;
    setState(() => _loading = true);
    try {
      final dio = createDio();
      for (final photo in _photos) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            photo.bytes,
            filename: photo.file.name,
          ),
        });
        await dio.post('/master/portfolio/upload', data: formData);
      }
      if (mounted) context.push(AppRoutes.masterService);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: AppTextStyles.caption),
            backgroundColor: kBgSecondary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _photos.length >= 3;

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Портфолио', style: AppTextStyles.title),
        leading:
            BackButton(color: kTextPrimary, onPressed: () => context.pop()),
      ),
      body: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text('Добавьте работы', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Минимум 3 фото. Первое фото станет обложкой профиля.',
              style: AppTextStyles.body.copyWith(color: kTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ─── Photo grid ──────────────────────────────────────
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemCount: _photos.length + 1,
                itemBuilder: (_, i) {
                  if (i == _photos.length) {
                    return _AddPhotoCell(
                        onTap: _photos.length < 20 ? _pick : null);
                  }
                  return _PhotoCell(
                    bytes: _photos[i].bytes,
                    isCover: i == 0,
                    onRemove: () => _remove(i),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
            if (_photos.isNotEmpty && _photos.length < 3)
              Center(
                child: Text(
                  'Добавьте ещё ${3 - _photos.length} фото',
                  style: AppTextStyles.caption
                      .copyWith(color: kTextSecondary),
                ),
              ),

            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Загрузить (${_photos.length})',
              onPressed: _upload,
              loading: _loading,
              enabled: canContinue,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoCell extends StatelessWidget {
  const _AddPhotoCell({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kBgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: kBorder2),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined,
            color: kTextTertiary, size: 32),
      ),
    );
  }
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({
    required this.bytes,
    required this.isCover,
    required this.onRemove,
  });
  final Uint8List bytes;
  final bool isCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
        if (isCover)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kGold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Обложка',
                  style: AppTextStyles.caption
                      .copyWith(color: kBgPrimary, fontSize: 10)),
            ),
          ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child:
                  const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
