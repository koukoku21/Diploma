import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../data/profile_models.dart';

final _profileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  final res = await createDio().get('/users/me');
  return UserProfile.fromJson(res.data as Map<String, dynamic>);
});

// C-8: Профиль клиента
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_profileProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Профиль', style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kTextSecondary),
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _SettingsSheet(ref: ref),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _isUploadingAvatar = false;
  final _picker = ImagePicker();
  late String _name;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _name = widget.profile.name;
    _avatarUrl = widget.profile.avatarUrl;
  }

  Future<void> _pickAvatar() async {
  if (_isUploadingAvatar) return;

  final img = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  if (img == null) return;

  setState(() => _isUploadingAvatar = true);

  try {
    final bytes = await img.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: img.name),
    });

    final res = await createDio().patch('/users/me/avatar', data: formData);

    if (!mounted) return;
    setState(() => _avatarUrl = res.data['avatarUrl'] as String?);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Аватар обновлён',
          style: AppTextStyles.caption.copyWith(color: kTextPrimary),
        ),
        backgroundColor: kBgSecondary,
      ),
    );
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Не удалось загрузить аватар',
          style: AppTextStyles.caption.copyWith(color: kTextPrimary),
        ),
        backgroundColor: kBgSecondary,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isUploadingAvatar = false);
    }
  }
}


  void _showEditName() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _EditNameSheet(
        ref: ref,
        currentName: _name,
        onSaved: (newName) => setState(() => _name = newName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      children: [
        const SizedBox(height: AppSpacing.xl),

        // ─── Avatar + name ─────────────────────────────────────
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploadingAvatar ? null : _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: kBgTertiary,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _isUploadingAvatar
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kGold,
                              ),
                            )
                          : _avatarUrl == null
                              ? const Icon(
                                  Icons.person_outline,
                                  color: kTextTertiary,
                                  size: 48,
                                )
                              : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                            color: kGold, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            color: kBgPrimary, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_name, style: AppTextStyles.h1),
                  const SizedBox(width: AppSpacing.xs),
                  GestureDetector(
                    onTap: _showEditName,
                    child: const Icon(Icons.edit_outlined,
                        color: kTextTertiary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(profile.phone,
                  style: AppTextStyles.body.copyWith(color: kTextSecondary)),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        const Divider(color: kBorder),
        const SizedBox(height: AppSpacing.md),

        // ─── Стать мастером / статус ───────────────────────────
        if (!profile.hasMasterProfile)
          _BecomeMasterCard(
              onTap: () => context.push(AppRoutes.masterSpecializations))
        else if (profile.masterStatus == 'APPROVED')
          _BecomeMasterCard(
            label: 'Режим мастера',
            subtitle: 'Переключиться в кабинет мастера',
            icon: Icons.swap_horiz_rounded,
            onTap: () => context.go(AppRoutes.masterDashboard),
          )
        else if (profile.masterStatus == 'PENDING')
          const _MasterStatusCard(
            icon: Icons.hourglass_bottom_rounded,
            color: kGold,
            title: 'Заявка на проверке',
            subtitle: 'Одобрение занимает до 24 часов',
          )
        else if (profile.masterStatus == 'REJECTED')
          const _MasterStatusCard(
            icon: Icons.cancel_outlined,
            color: kRose,
            title: 'Заявка отклонена',
            subtitle: 'Свяжитесь с поддержкой',
          ),

        const SizedBox(height: AppSpacing.xl),
        const Divider(color: kBorder),

        // ─── Menu items ────────────────────────────────────────
        _MenuItem(
          icon: Icons.calendar_today_outlined,
          label: 'Мои записи',
          onTap: () => context.push(AppRoutes.bookings),
        ),
        _MenuItem(
          icon: Icons.favorite_border_rounded,
          label: 'Избранные мастера',
          onTap: () => context.go(AppRoutes.favourites),
        ),
        _MenuItem(
          icon: Icons.chat_bubble_outline,
          label: 'Чаты',
          onTap: () => context.go(AppRoutes.chats),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─── Edit name bottom sheet ───────────────────────────────────────
class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({
    required this.ref,
    required this.currentName,
    required this.onSaved,
  });

  final WidgetRef ref;
  final String currentName;
  final ValueChanged<String> onSaved;


  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canSave => _ctrl.text.trim().length >= 2;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await createDio().patch('/users/me', data: {'name': _ctrl.text.trim()});
      if (!mounted) return;
      widget.onSaved(_ctrl.text.trim());
      widget.ref.invalidate(_profileProvider);
      Navigator.pop(context);
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
    return Padding(
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
          Text('Изменить имя', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _ctrl,
            hint: 'Ваше имя',
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _canSave ? _save() : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSave && !_loading ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                disabledBackgroundColor: kGold.withValues(alpha: 0.4),
                foregroundColor: kBgPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: kBgPrimary, strokeWidth: 2))
                  : Text('Сохранить',
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700, color: kBgPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Become Master card ───────────────────────────────────────────
class _BecomeMasterCard extends StatelessWidget {
  const _BecomeMasterCard({
    required this.onTap,
    this.label = 'Стать мастером',
    this.subtitle = 'Начните принимать клиентов',
    this.icon = Icons.star_border_rounded,
  });
  final VoidCallback onTap;
  final String label;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: kBgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: kGold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kGold),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          AppTextStyles.caption.copyWith(color: kTextSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kTextTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Master status card ───────────────────────────────────────────
class _MasterStatusCard extends StatelessWidget {
  const _MasterStatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        AppTextStyles.caption.copyWith(color: kTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu item ────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: kTextSecondary),
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right, color: kTextTertiary, size: 20),
    );
  }
}

// ─── Settings bottom sheet ────────────────────────────────────────
class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text('Настройки', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xl),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: kRose),
            title: Text('Выйти',
                style: AppTextStyles.body.copyWith(color: kRose)),
            onTap: () async {
              Navigator.pop(context);
              await TokenStorage().clear();
              if (context.mounted) context.go(AppRoutes.phone);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
