import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.phone});
  final String phone;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _ctrl   = TextEditingController();
  final _picker = ImagePicker();

  XFile?         _avatarFile;
  Uint8List?     _avatarBytes; // для предпросмотра через Image.memory
  bool _loading  = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _ctrl.text.trim().length >= 2;

  Future<void> _pickAvatar() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() {
      _avatarFile  = img;
      _avatarBytes = bytes;
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      // 1. Сохраняем имя
      await createDio()
          .patch('/users/me', data: {'name': _ctrl.text.trim()});

      // 2. Загружаем аватар (необязательно)
      if (_avatarFile != null && _avatarBytes != null) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            _avatarBytes!,
            filename: _avatarFile!.name,
          ),
        });
        await createDio().patch('/users/me/avatar', data: formData);
      }

      if (!mounted) return;
      context.go(AppRoutes.location);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              Text('Расскажите о себе', style: AppTextStyles.display),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Мастера и клиенты будут видеть ваш профиль.',
                style: AppTextStyles.body.copyWith(color: kTextSecondary),
              ),

              const SizedBox(height: 40),

              // ─── Аватар ───────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: kBgTertiary,
                            backgroundImage: _avatarBytes != null
                                ? MemoryImage(_avatarBytes!)
                                : null,
                            child: _avatarBytes == null
                                ? const Icon(Icons.person_outline,
                                    color: kTextTertiary, size: 48)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                  color: kGold, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt,
                                  color: kBgPrimary, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Фото профиля (необязательно)',
                      style: AppTextStyles.caption
                          .copyWith(color: kTextTertiary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ─── Имя ─────────────────────────────────────────
              Text('Имя', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _ctrl,
                autofocus: false,
                hint: 'Айгерим',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _canSubmit ? _submit() : null,
              ),

              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: 'Продолжить',
                onPressed: _submit,
                loading: _loading,
                enabled: _canSubmit,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
