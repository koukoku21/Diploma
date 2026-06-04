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
import '../../../core/providers/settings_provider.dart';
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
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.profile, style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.colors.textSecondary),
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
      backgroundColor: context.colors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _SettingsSheet(),
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
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: img.name),
    });
    final res = await createDio().patch('/users/me/avatar', data: formData);
    if (mounted) setState(() => _avatarUrl = res.data['avatarUrl'] as String?);
  }

  void _showEditName() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _EditNameSheet(
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
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: context.colors.bgTertiary,
                      backgroundImage:
                          _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Icon(Icons.person_outline,
                              color: context.colors.textTertiary, size: 48)
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
                        child: Icon(Icons.camera_alt,
                            color: context.colors.bgPrimary, size: 16),
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
                    child: Icon(Icons.edit_outlined,
                        color: context.colors.textTertiary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(profile.phone,
                  style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        Divider(color: context.colors.border),
        const SizedBox(height: AppSpacing.md),

        // ─── Стать мастером / статус ───────────────────────────
        if (!profile.hasMasterProfile)
          _BecomeMasterCard(
              label: context.l10n.becomeMaster,
              onTap: () => context.push(AppRoutes.masterSpecializations))
        else if (profile.masterStatus == 'APPROVED')
          _BecomeMasterCard(
            label: context.l10n.masterMode,
            subtitle: context.l10n.masterModeDesc,
            icon: Icons.swap_horiz_rounded,
            onTap: () => context.go(AppRoutes.masterDashboard),
          )
        else if (profile.masterStatus == 'PENDING')
          _MasterStatusCard(
            icon: Icons.hourglass_bottom_rounded,
            color: kGold,
            title: context.l10n.applicationOnReview,
            subtitle: context.l10n.applicationOnReviewDesc,
          )
        else if (profile.masterStatus == 'REJECTED')
          _RejectedCard(
            reason: profile.rejectionReason,
            onResubmit: () async {
              try {
                await createDio().post('/masters/me/resubmit');
                if (context.mounted) {
                  ref.invalidate(_profileProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.applicationResent,
                          style: AppTextStyles.caption),
                      backgroundColor: context.colors.bgSecondary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString(), style: AppTextStyles.caption),
                      backgroundColor: context.colors.bgSecondary,
                    ),
                  );
                }
              }
            },
          ),

        const SizedBox(height: AppSpacing.xl),
        Divider(color: context.colors.border),

        // ─── Menu items ────────────────────────────────────────
        _MenuItem(
          icon: Icons.calendar_today_outlined,
          label: context.l10n.myBookings,
          onTap: () => context.push(AppRoutes.bookings),
        ),
        _MenuItem(
          icon: Icons.favorite_border_rounded,
          label: context.l10n.favouriteMasters,
          onTap: () => context.go(AppRoutes.favourites),
        ),
        _MenuItem(
          icon: Icons.chat_bubble_outline,
          label: context.l10n.chats,
          onTap: () => context.go(AppRoutes.chats),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─── Edit name bottom sheet ───────────────────────────────────────
class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.currentName, required this.onSaved});
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
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: AppTextStyles.caption),
            backgroundColor: context.colors.bgSecondary,
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
                  color: context.colors.border2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(context.l10n.editNameTitle, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _ctrl,
            hint: context.l10n.namePlaceholder,
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
                foregroundColor: context.colors.bgPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: context.colors.bgPrimary, strokeWidth: 2))
                  : Text(context.l10n.saveBtn,
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700, color: context.colors.bgPrimary)),
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
    required this.label,
    this.subtitle,
    this.icon = Icons.star_border_rounded,
  });
  final VoidCallback onTap;
  final String label;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.bgSecondary,
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
                  Text(subtitle ?? context.l10n.startAcceptingClients,
                      style:
                          AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.textTertiary, size: 20),
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
        color: context.colors.bgSecondary,
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
                        AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
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
      leading: Icon(icon, color: context.colors.textSecondary),
      title: Text(label, style: AppTextStyles.body),
      trailing: Icon(Icons.chevron_right, color: context.colors.textTertiary, size: 20),
    );
  }
}

// ─── Settings bottom sheet ────────────────────────────────────────
class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final themeLabels = {
      ThemeMode.dark: context.l10n.darkTheme,
      ThemeMode.light: context.l10n.lightTheme,
      ThemeMode.system: context.l10n.systemTheme,
    };
    const langLabels = {
      'ru': '🇷🇺  Русский',
      'kk': '🇰🇿  Қазақша',
      'en': '🇬🇧  English',
    };

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
                color: context.colors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(context.l10n.settings, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),
          // ─── Тема ─────────────────────────────────────────────
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              themeMode == ThemeMode.light
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: kGold,
            ),
            title: Text(context.l10n.theme, style: AppTextStyles.body),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              dropdownColor: context.colors.bgSecondary,
              style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
              items: ThemeMode.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(themeLabels[m]!),
                      ))
                  .toList(),
              onChanged: (m) => ref.read(themeProvider.notifier).set(m!),
            ),
          ),
          // ─── Язык ─────────────────────────────────────────────
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language_rounded, color: kGold),
            title: Text(context.l10n.language, style: AppTextStyles.body),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              underline: const SizedBox(),
              dropdownColor: context.colors.bgSecondary,
              style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
              items: langLabels.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (code) =>
                  ref.read(localeProvider.notifier).set(Locale(code!)),
            ),
          ),
          Divider(color: context.colors.border),
          // ─── Выйти ────────────────────────────────────────────
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: kRose),
            title: Text(context.l10n.logout,
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

// ─── Rejected card with reason + resubmit ────────────────────────
class _RejectedCard extends StatefulWidget {
  const _RejectedCard({required this.onResubmit, this.reason});
  final String? reason;
  final VoidCallback onResubmit;

  @override
  State<_RejectedCard> createState() => _RejectedCardState();
}

class _RejectedCardState extends State<_RejectedCard> {
  bool _loading = false;

  Future<void> _tap() async {
    setState(() => _loading = true);
    try {
      widget.onResubmit();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: kRose.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: kRose, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.applicationRejected, style: AppTextStyles.label),
                    if (widget.reason != null && widget.reason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.reason!,
                        style: AppTextStyles.caption.copyWith(color: kRose),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.fixAndResubmit,
                        style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _loading ? null : _tap,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRose,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kRose.withValues(alpha: 0.4),
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(context.l10n.resendCode,
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
