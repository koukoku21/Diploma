import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      children: [
        const SizedBox(height: AppSpacing.xl),

        // ─── Avatar + name ─────────────────────────────────────
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: kBgTertiary,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? const Icon(Icons.person_outline, color: kTextTertiary, size: 48)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(profile.name, style: AppTextStyles.h1),
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
          _BecomeMasterCard(onTap: () => context.push(AppRoutes.masterSpecializations))
        else if (profile.masterStatus == 'APPROVED')
          _BecomeMasterCard(
            label: 'Режим мастера',
            subtitle: 'Переключиться в кабинет мастера',
            icon: Icons.swap_horiz_rounded,
            onTap: () => context.go(AppRoutes.masterDashboard),
          )
        else if (profile.masterStatus == 'PENDING')
          _MasterStatusCard(
            icon: Icons.hourglass_bottom_rounded,
            color: kGold,
            title: 'Заявка на проверке',
            subtitle: 'Одобрение занимает до 24 часов',
          )
        else if (profile.masterStatus == 'REJECTED')
          _MasterStatusCard(
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
          onTap: () => context.go(AppRoutes.bookings),
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
                      style: AppTextStyles.caption.copyWith(color: kTextSecondary)),
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
                    style: AppTextStyles.caption.copyWith(color: kTextSecondary)),
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
            title: Text('Выйти', style: AppTextStyles.body.copyWith(color: kRose)),
            onTap: () async {
              Navigator.pop(context);
              const storage = FlutterSecureStorage();
              await storage.deleteAll();
              if (context.mounted) context.go(AppRoutes.phone);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
