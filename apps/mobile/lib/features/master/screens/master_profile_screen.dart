import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';
import 'master_portfolio_manage_screen.dart';
import 'master_services_screen.dart';

final _masterProfileProvider = FutureProvider.autoDispose((ref) async {
  final res = await createDio().get('/masters/me');
  return res.data as Map<String, dynamic>;
});

// M-9 / M-12: Профиль мастера + настройки
class MasterProfileScreen extends ConsumerWidget {
  const MasterProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_masterProfileProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Профиль', style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = profile['user'] as Map<String, dynamic>? ?? {};
    final photos = profile['portfolioPhotos'] as List? ?? [];
    final coverUrl = photos.isNotEmpty ? (photos.first as Map)['url'] as String? : null;

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
                backgroundImage:
                    coverUrl != null ? NetworkImage(coverUrl) : null,
                child: coverUrl == null
                    ? const Icon(Icons.person_outline,
                        color: kTextTertiary, size: 48)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(user['name'] as String? ?? '—', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              _VerifiedBadge(
                  status: profile['status'] as String? ?? 'PENDING'),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        const Divider(color: kBorder),
        const SizedBox(height: AppSpacing.md),

        // ─── Menu ──────────────────────────────────────────────
        _MenuItem(
          icon: Icons.photo_library_outlined,
          label: 'Портфолио',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const MasterPortfolioManageScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.content_cut_outlined,
          label: 'Мои услуги',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterServicesScreen()),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        const Divider(color: kBorder),

        // ─── Переключить роль ──────────────────────────────────
        _MenuItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Режим клиента',
          onTap: () => context.go(AppRoutes.feed),
        ),

        // ─── Выйти ────────────────────────────────────────────
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout_rounded, color: kRose),
          title: Text('Выйти',
              style: AppTextStyles.body.copyWith(color: kRose)),
          onTap: () async {
            const storage = FlutterSecureStorage();
            await storage.deleteAll();
            if (context.mounted) context.go(AppRoutes.phone);
          },
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      'APPROVED' => ('Верифицирован', kGold),
      'PENDING'  => ('На проверке', kTextSecondary),
      _          => ('Отклонён', kRose),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

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
