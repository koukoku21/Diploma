import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../widgets/address_autocomplete_field.dart';
import '../../chat/screens/master_chats_screen.dart';
import 'master_portfolio_manage_screen.dart';
import 'master_services_screen.dart';
import 'master_schedule_screen.dart';
import 'master_schedule_overrides_screen.dart';

final _masterProfileProvider = FutureProvider.autoDispose((ref) async {
  final res = await createDio().get('/masters/me');
  return res.data as Map<String, dynamic>;
});

final _visibilityStatusProvider = FutureProvider.autoDispose((ref) async {
  final res = await createDio().get('/visibility/status');
  return res.data as Map<String, dynamic>;
});

// M-9 / M-12: Профиль мастера + настройки
class MasterProfileScreen extends ConsumerWidget {
  const MasterProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_masterProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(context.l10n.profile, style: AppTextStyles.title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  final _picker = ImagePicker();
  String? _avatarUrl;
  late String _name;
  late String _bio;
  late String _address;
  String? _username;
  late bool _isBookingLinkActive;

  @override
  void initState() {
    super.initState();
    final user = widget.profile['user'] as Map<String, dynamic>? ?? {};
    _avatarUrl          = user['avatarUrl'] as String?;
    _name               = user['name'] as String? ?? '—';
    _bio                = widget.profile['bio'] as String? ?? '';
    _address            = widget.profile['address'] as String? ?? '';
    _username           = widget.profile['username'] as String?;
    _isBookingLinkActive = widget.profile['isBookingLinkActive'] as bool? ?? true;
  }

  Future<void> _openEditSheet() async {
    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _EditProfileSheet(name: _name, bio: _bio, address: _address),
    );
    if (result == null) return;
    setState(() {
      _name    = result['name']!;
      _bio     = result['bio']!;
      _address = result['address']!;
    });
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
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Icon(Icons.person_outline, color: context.colors.textTertiary, size: 48)
                          : null,
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(
                            color: kGold, shape: BoxShape.circle),
                        child: Icon(Icons.camera_alt, color: context.colors.bgPrimary, size: 16),
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
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _openEditSheet,
                    child: Icon(Icons.edit_outlined, size: 18, color: context.colors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _VerifiedBadge(status: profile['status'] as String? ?? 'PENDING'),
              if (_bio.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_bio,
                    style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
                    textAlign: TextAlign.center),
              ],
              if (_address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: context.colors.textTertiary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _address,
                        style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        Divider(color: context.colors.border),
        const SizedBox(height: AppSpacing.md),

        // ─── Menu ──────────────────────────────────────────────
        _MenuItem(
          icon: Icons.photo_library_outlined,
          label: context.l10n.portfolio,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const MasterPortfolioManageScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.content_cut_outlined,
          label: context.l10n.myServices,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterServicesScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.schedule_outlined,
          label: context.l10n.schedule,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterScheduleScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.event_busy_outlined,
          label: context.l10n.specialDays,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterScheduleOverridesScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: context.l10n.messages,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterChatsScreen()),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        Divider(color: context.colors.border),
        const SizedBox(height: AppSpacing.md),

        // ─── Моя ссылка для записи ────────────────────────────
        _BookingLinkBlock(
          username: _username,
          isActive: _isBookingLinkActive,
          onUsernameChanged: (v) => setState(() => _username = v),
          onActiveChanged: (v) => setState(() => _isBookingLinkActive = v),
        ),

        const SizedBox(height: AppSpacing.md),
        Divider(color: context.colors.border),
        const SizedBox(height: AppSpacing.md),

        // ─── Видимость в ленте ────────────────────────────────
        const _VisibilityBlock(),

        const SizedBox(height: AppSpacing.md),
        Divider(color: context.colors.border),

        // ─── Переключить роль ──────────────────────────────────
        _MenuItem(
          icon: Icons.swap_horiz_rounded,
          label: context.l10n.clientMode,
          onTap: () => context.go(AppRoutes.feed),
        ),

        // ─── Тема ─────────────────────────────────────────────
        _ThemeTile(),

        // ─── Язык ─────────────────────────────────────────────
        _LanguageTile(),

        // ─── Выйти ────────────────────────────────────────────
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout_rounded, color: kRose),
          title: Text(context.l10n.logout,
              style: AppTextStyles.body.copyWith(color: kRose)),
          onTap: () async {
            await TokenStorage().clear();
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
      'APPROVED' => (context.l10n.masterVerified, kGold),
      'PENDING'  => (context.l10n.masterOnReview, context.colors.textSecondary),
      _          => (context.l10n.masterRejected, kRose),
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
      leading: Icon(icon, color: context.colors.textSecondary),
      title: Text(label, style: AppTextStyles.body),
      trailing: Icon(Icons.chevron_right, color: context.colors.textTertiary, size: 20),
    );
  }
}

// ─── Visibility block ─────────────────────────────────────────────────────
class _VisibilityBlock extends ConsumerWidget {
  const _VisibilityBlock();

  static const _months = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  String _fmt(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day} ${_months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_visibilityStatusProvider);

    return async.when(
      loading: () => const SizedBox(height: 56,
          child: Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) {
        final isVisible       = s['isVisible'] as bool? ?? false;
        final isFreeTrial     = s['isFreeTrialActive'] as bool? ?? false;
        final freeTrialEndsAt = s['freeTrialEndsAt'] as String?;
        final activePackage   = s['activePackage'] as Map?;
        final isBoosted       = s['isBoosted'] as bool? ?? false;
        final activeEndsAt    = activePackage?['endsAt'] as String?;

        if (isVisible) {
          final (statusText, subText) = isFreeTrial && freeTrialEndsAt != null
              ? (context.l10n.visibleToClients, 'Бесплатный период до ${_fmt(freeTrialEndsAt)}')
              : activeEndsAt != null
                  ? (context.l10n.visibleToClients, 'Пакет активен до ${_fmt(activeEndsAt)}')
                  : (context.l10n.visibleToClients, '');

          return Column(
            children: [
              _VisibilityStatusCard(
                icon: Icons.visibility_rounded,
                color: kSuccess,
                title: statusText,
                subtitle: subText,
              ),
              if (isBoosted) ...[
                const SizedBox(height: AppSpacing.sm),
                _VisibilityStatusCard(
                  icon: Icons.rocket_launch_rounded,
                  color: kGold,
                  title: context.l10n.boostActive,
                  subtitle: context.l10n.boostActiveDesc,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _PackageButtons(onActivated: () => ref.invalidate(_visibilityStatusProvider)),
            ],
          );
        }

        // Hidden
        return Column(
          children: [
            _VisibilityStatusCard(
              icon: Icons.visibility_off_rounded,
              color: kRose,
              title: 'Скрыты из ленты',
              subtitle: context.l10n.hiddenFromFeedDesc,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PackageButtons(onActivated: () => ref.invalidate(_visibilityStatusProvider)),
          ],
        );
      },
    );
  }
}

class _VisibilityStatusCard extends StatelessWidget {
  const _VisibilityStatusCard({
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(color: color)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageButtons extends StatefulWidget {
  const _PackageButtons({required this.onActivated});
  final VoidCallback onActivated;

  @override
  State<_PackageButtons> createState() => _PackageButtonsState();
}

class _PackageButtonsState extends State<_PackageButtons> {
  bool _loading = false;

  List<(String, String, String, int)> _packages(BuildContext context) => [
    ('WEEK',  context.l10n.weekLabel,  '990 ₸',  7),
    ('MONTH', context.l10n.monthLabel, '2 990 ₸', 30),
    ('BOOST', context.l10n.boostPackage, '490 ₸', 1),
  ];

  Future<void> _activate(String packageType, int amount) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgSecondary,
        title: Text(context.l10n.kaspiPayment, style: AppTextStyles.title),
        content: Text(
          'После оплаты нажмите «Активировать».\n\nПакет: $packageType\nСумма: $amount ₸',
          style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancelBtn,
                style: AppTextStyles.label.copyWith(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.activateBtn,
                style: AppTextStyles.label.copyWith(color: kGold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await createDio().post('/visibility/activate', data: {
        'packageType': packageType,
        'paidAmount': amount,
      });
      widget.onActivated();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorActivation)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.visibilityPackages,
            style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: _packages(context).map((p) {
            final (type, label, price, amount) = p;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _loading
                    ? const SizedBox(height: 44,
                        child: Center(
                          child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: kGold, strokeWidth: 2)),
                        ))
                    : OutlinedButton(
                        onPressed: () => _activate(type, amount),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kGold,
                          side: BorderSide(color: context.colors.border2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label,
                                style: AppTextStyles.caption
                                    .copyWith(color: context.colors.textSecondary),
                                textAlign: TextAlign.center),
                            Text(price,
                                style: AppTextStyles.caption.copyWith(
                                    color: kGold,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Booking link block ───────────────────────────────────────────────────
class _BookingLinkBlock extends StatefulWidget {
  const _BookingLinkBlock({
    required this.username,
    required this.isActive,
    required this.onUsernameChanged,
    required this.onActiveChanged,
  });

  final String? username;
  final bool isActive;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<bool> onActiveChanged;

  @override
  State<_BookingLinkBlock> createState() => _BookingLinkBlockState();
}

class _BookingLinkBlockState extends State<_BookingLinkBlock> {
  bool _saving = false;

  String get _link =>
      widget.username != null ? 'diploma-api-dt1b.vercel.app/p/${widget.username}' : '';

  Future<void> _copyLink() async {
    if (widget.username == null) return;
    await Clipboard.setData(ClipboardData(text: 'https://$_link'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.linkCopied), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _shareWhatsApp() async {
    if (widget.username == null) return;
    final text = Uri.encodeComponent('Запишись ко мне: https://$_link');
    await launchUrl(Uri.parse('https://wa.me/?text=$text'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _shareTelegram() async {
    if (widget.username == null) return;
    final text = Uri.encodeComponent('Запишись ко мне:');
    final url  = Uri.encodeComponent('https://$_link');
    await launchUrl(Uri.parse('https://t.me/share/url?url=$url&text=$text'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleActive(bool value) async {
    setState(() => _saving = true);
    try {
      await createDio().patch('/masters/me', data: {'isBookingLinkActive': value});
      widget.onActiveChanged(value);
    } catch (_) {
      // оставляем старое значение при ошибке
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openUsernameSheet() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _UsernameSheet(current: widget.username),
    );
    if (result != null && mounted) widget.onUsernameChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasUsername = widget.username != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: kGold, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(context.l10n.myBookingLink, style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Ссылка или призыв задать handle
          GestureDetector(
            onTap: _openUsernameSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.bgTertiary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasUsername ? _link : context.l10n.setHandle,
                      style: hasUsername
                          ? AppTextStyles.body.copyWith(color: kGold)
                          : AppTextStyles.body.copyWith(color: context.colors.textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 16, color: context.colors.textTertiary),
                ],
              ),
            ),
          ),

          if (hasUsername) ...[
            const SizedBox(height: AppSpacing.md),

            // Кнопки: копировать, WhatsApp, Telegram
            Row(
              children: [
                _LinkActionButton(
                  icon: Icons.copy_rounded,
                  label: context.l10n.copyBtn,
                  onTap: _copyLink,
                ),
                const SizedBox(width: AppSpacing.sm),
                _LinkActionButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  onTap: _shareWhatsApp,
                ),
                const SizedBox(width: AppSpacing.sm),
                _LinkActionButton(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  onTap: _shareTelegram,
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Divider(color: context.colors.border),
          const SizedBox(height: AppSpacing.sm),

          // Тогл
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.acceptByLink,
                        style: AppTextStyles.body),
                    Text(
                      widget.isActive ? context.l10n.linkEnabledDesc : context.l10n.linkDisabled,
                      style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: kGold, strokeWidth: 2))
                  : Switch(
                      value: widget.isActive,
                      onChanged: _toggleActive,
                      activeColor: kGold,
                      inactiveThumbColor: context.colors.textTertiary,
                      inactiveTrackColor: context.colors.bgTertiary,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkActionButton extends StatelessWidget {
  const _LinkActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.colors.bgTertiary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: context.colors.textSecondary),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Username sheet ────────────────────────────────────────────────────────
class _UsernameSheet extends StatefulWidget {
  const _UsernameSheet({required this.current});
  final String? current;

  @override
  State<_UsernameSheet> createState() => _UsernameSheetState();
}

class _UsernameSheetState extends State<_UsernameSheet> {
  late final TextEditingController _ctrl;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isValidUsername(String v) =>
      RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(v);

  Future<void> _save() async {
    final value = _ctrl.text.trim().toLowerCase();
    if (!_isValidUsername(value)) {
      setState(() => _error = context.l10n.handleInvalid);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await createDio().patch('/masters/me', data: {'username': value});
      if (mounted) Navigator.pop(context, value);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      setState(() => _error = msg ?? context.l10n.handleTaken);
    } catch (_) {
      setState(() => _error = context.l10n.errorSave);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(color: context.colors.border2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(context.l10n.handleLabel, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.handleHint,
              style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _ctrl,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              TextInputFormatter.withFunction(
                (old, val) => val.copyWith(text: val.text.toLowerCase()),
              ),
            ],
            style: AppTextStyles.body,
            decoration: InputDecoration(
              prefixText: '@',
              prefixStyle: AppTextStyles.body.copyWith(color: kGold),
              hintText: 'username',
              hintStyle: AppTextStyles.body.copyWith(color: context.colors.textTertiary),
              errorText: _error,
              filled: true,
              fillColor: context.colors.bgTertiary,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: context.colors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: context.colors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: kGold)),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          // превью ссылки
          ValueListenableBuilder(
            valueListenable: _ctrl,
            builder: (_, val, __) => val.text.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    'diploma-api-dt1b.vercel.app/p/${val.text.toLowerCase()}',
                    style: AppTextStyles.caption.copyWith(color: context.colors.textTertiary),
                  ),
          ),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                disabledBackgroundColor: kGold.withValues(alpha: 0.4),
                foregroundColor: context.colors.bgPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: context.colors.bgPrimary, strokeWidth: 2))
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

// ─── Edit profile bottom sheet ─────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.name,
    required this.bio,
    required this.address,
  });
  final String name;
  final String bio;
  final String address;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  bool _loading = false;
  // адрес + координаты из autocomplete
  late String _address;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _bioCtrl  = TextEditingController(text: widget.bio);
    _address  = widget.address;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final name = _nameCtrl.text.trim();
      final bio  = _bioCtrl.text.trim();

      if (name != widget.name) {
        await createDio().patch('/users/me', data: {'name': name});
      }

      final patchData = <String, dynamic>{'bio': bio};
      if (_address.isNotEmpty) patchData['address'] = _address;
      if (_lat != null)        patchData['lat'] = _lat;
      if (_lng != null)        patchData['lng'] = _lng;

      await createDio().patch('/masters/me', data: patchData);

      if (mounted) {
        Navigator.pop(context, {
          'name': name,
          'bio': bio,
          'address': _address,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: context.colors.bgSecondary),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                  color: context.colors.border2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(context.l10n.editProfile, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),

          Text(context.l10n.nameLabel, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(controller: _nameCtrl, hint: context.l10n.namePlaceholder),
          const SizedBox(height: AppSpacing.md),

          Text(context.l10n.bioLabel, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 300,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: context.l10n.bioHint,
              hintStyle: AppTextStyles.body.copyWith(color: context.colors.textTertiary),
              filled: true,
              fillColor: context.colors.bgTertiary,
              counterStyle: AppTextStyles.caption.copyWith(color: context.colors.textTertiary),
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
          const SizedBox(height: AppSpacing.md),

          Text('Адрес', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          AddressAutocompleteField(
            initialValue: _address,
            onSelected: (s) {
              _address = s.fullName;
              _lat     = s.lat;
              _lng     = s.lng;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                disabledBackgroundColor: kGold.withValues(alpha: 0.4),
                foregroundColor: context.colors.bgPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: context.colors.bgPrimary, strokeWidth: 2))
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

// ─── Тема ────────────────────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final labels = {
      ThemeMode.dark:   context.l10n.darkTheme,
      ThemeMode.light:  context.l10n.lightTheme,
      ThemeMode.system: context.l10n.systemTheme,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        mode == ThemeMode.light ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: kGold,
      ),
      title: Text(context.l10n.theme, style: AppTextStyles.body),
      trailing: DropdownButton<ThemeMode>(
        value: mode,
        underline: const SizedBox(),
        dropdownColor: context.colors.bgSecondary,
        style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
        items: ThemeMode.values.map((m) => DropdownMenuItem(
          value: m,
          child: Text(labels[m]!),
        )).toList(),
        onChanged: (m) => ref.read(themeProvider.notifier).set(m!),
      ),
    );
  }
}

// ─── Язык ────────────────────────────────────────────────────────

class _LanguageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    const langs = {
      'ru': '🇷🇺  Русский',
      'kk': '🇰🇿  Қазақша',
      'en': '🇬🇧  English',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.language_rounded, color: kGold),
      title: Text(context.l10n.language, style: AppTextStyles.body),
      trailing: DropdownButton<String>(
        value: locale.languageCode,
        underline: const SizedBox(),
        dropdownColor: context.colors.bgSecondary,
        style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
        items: langs.entries.map((e) => DropdownMenuItem(
          value: e.key,
          child: Text(e.value),
        )).toList(),
        onChanged: (code) => ref.read(localeProvider.notifier).set(Locale(code!)),
      ),
    );
  }
}
