import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/dio_client.dart';
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

  @override
  void initState() {
    super.initState();
    final user = widget.profile['user'] as Map<String, dynamic>? ?? {};
    _avatarUrl = user['avatarUrl'] as String?;
    _name    = user['name'] as String? ?? '—';
    _bio     = widget.profile['bio'] as String? ?? '';
    _address = widget.profile['address'] as String? ?? '';
  }

  Future<void> _openEditSheet() async {
    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgSecondary,
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
                      backgroundColor: kBgTertiary,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? const Icon(Icons.person_outline, color: kTextTertiary, size: 48)
                          : null,
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(
                            color: kGold, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: kBgPrimary, size: 16),
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
                    child: const Icon(Icons.edit_outlined, size: 18, color: kTextTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _VerifiedBadge(status: profile['status'] as String? ?? 'PENDING'),
              if (_bio.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_bio,
                    style: AppTextStyles.caption.copyWith(color: kTextSecondary),
                    textAlign: TextAlign.center),
              ],
              if (_address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: kTextTertiary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _address,
                        style: AppTextStyles.caption.copyWith(color: kTextTertiary),
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
        _MenuItem(
          icon: Icons.schedule_outlined,
          label: 'Расписание',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterScheduleScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.event_busy_outlined,
          label: 'Особые дни',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterScheduleOverridesScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Сообщения',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterChatsScreen()),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        const Divider(color: kBorder),
        const SizedBox(height: AppSpacing.md),

        // ─── Видимость в ленте ────────────────────────────────
        const _VisibilityBlock(),

        const SizedBox(height: AppSpacing.md),
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

// ─── Visibility block ─────────────────────────────────────────────────────
class _VisibilityBlock extends ConsumerStatefulWidget {
  const _VisibilityBlock();

  @override
  ConsumerState<_VisibilityBlock> createState() => _VisibilityBlockState();
}

class _VisibilityBlockState extends ConsumerState<_VisibilityBlock> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _activating = false;
  String? _selectedPackage; // 'WEEK' | 'MONTH' | 'BOOST'

  static const _packages = [
    (label: 'Неделя', sub: '990 ₸ / 7 дней', pkg: 'WEEK'),
    (label: 'Месяц', sub: '2 990 ₸ / 30 дней', pkg: 'MONTH'),
    (label: 'Буст топ', sub: '490 ₸ / 24 часа', pkg: 'BOOST'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await createDio().get('/visibility/status');
      if (mounted) setState(() { _status = res.data as Map<String, dynamic>; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showKaspiSheet(String pkg) async {
    setState(() => _selectedPackage = pkg);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _KaspiSheet(
        package: pkg,
        onPaid: _activate,
      ),
    );
  }

  Future<void> _activate() async {
    if (_selectedPackage == null) return;
    setState(() => _activating = true);
    try {
      await createDio().post('/visibility/activate', data: {'package': _selectedPackage});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Видимость активирована!'), backgroundColor: kBgSecondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: kBgSecondary),
        );
      }
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Видимость в ленте', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),

        // Status card
        if (_loading)
          const Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2))
        else
          _StatusCard(status: _status),

        const SizedBox(height: AppSpacing.md),

        // Package buttons
        ...(_packages.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _PackageButton(
            label: p.label,
            sub: p.sub,
            onTap: () => _showKaspiSheet(p.pkg),
            loading: _activating && _selectedPackage == p.pkg,
          ),
        ))),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final Map<String, dynamic>? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: kBgTertiary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: kBorder),
        ),
        child: Text('Не удалось загрузить статус', style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
      );
    }

    final isVisible = status!['isVisible'] as bool? ?? false;
    final activePackage = status!['activePackage'] as Map<String, dynamic>?;
    final isBoosted = status!['isBoosted'] as bool? ?? false;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isBoosted) {
      statusText = 'Буст активен — вы в топе ленты';
      statusColor = kGold;
      statusIcon = Icons.rocket_launch_rounded;
    } else if (isVisible && activePackage != null) {
      final expiresAt = activePackage['expiresAt'] as String?;
      String dateStr = '';
      if (expiresAt != null) {
        final dt = DateTime.tryParse(expiresAt);
        if (dt != null) dateStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
      }
      statusText = dateStr.isNotEmpty ? 'Видны клиентам до $dateStr' : 'Видны клиентам';
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.visibility_rounded;
    } else {
      statusText = 'Скрыты из ленты';
      statusColor = kTextTertiary;
      statusIcon = Icons.visibility_off_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(statusText, style: AppTextStyles.body.copyWith(color: statusColor)),
          ),
        ],
      ),
    );
  }
}

class _PackageButton extends StatelessWidget {
  const _PackageButton({
    required this.label,
    required this.sub,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final String sub;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: kBgTertiary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: kGold, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  Text(sub, style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
                ],
              ),
            ),
            if (loading)
              const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: kGold, strokeWidth: 2))
            else
              const Icon(Icons.chevron_right, color: kTextTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _KaspiSheet extends StatefulWidget {
  const _KaspiSheet({required this.package, required this.onPaid});
  final String package;
  final VoidCallback onPaid;

  @override
  State<_KaspiSheet> createState() => _KaspiSheetState();
}

class _KaspiSheetState extends State<_KaspiSheet> {
  static const _kaspiPhone = '+77001234567'; // Заменить на реальный номер

  static const _prices = {
    'WEEK': '990 ₸',
    'MONTH': '2 990 ₸',
    'BOOST': '490 ₸',
  };

  @override
  Widget build(BuildContext context) {
    final price = _prices[widget.package] ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH, AppSpacing.md,
        AppSpacing.screenH,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                  color: kBorder2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Оплата через Kaspi', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Переведите $price на номер:',
            style: AppTextStyles.body.copyWith(color: kTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // Phone number highlight
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: kGold.withValues(alpha: 0.4)),
            ),
            child: Text(
              _kaspiPhone,
              style: AppTextStyles.h1.copyWith(color: kGold, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Instruction
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: kBgTertiary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Instruction('1', 'Откройте приложение Kaspi.kz'),
                _Instruction('2', 'Переводы → По номеру телефона'),
                _Instruction('3', 'Введите номер $_kaspiPhone'),
                _Instruction('4', 'Сумма: $price, комментарий: «Miraku»'),
                _Instruction('5', 'Подтвердите перевод и нажмите «Я оплатил»'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onPaid();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: kBgPrimary,
                shape: const StadiumBorder(),
              ),
              child: Text('Я оплатил',
                  style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700, color: kBgPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction(this.step, this.text);
  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            margin: const EdgeInsets.only(right: AppSpacing.sm, top: 1),
            decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
            child: Center(
              child: Text(step,
                  style: const TextStyle(
                      fontFamily: 'Mulish', fontSize: 10,
                      fontWeight: FontWeight.w800, color: Color(0xFF0A0A0F))),
            ),
          ),
          Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(color: kTextSecondary))),
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
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: kBgSecondary),
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
                  color: kBorder2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Редактировать профиль', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),

          Text('Имя', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(controller: _nameCtrl, hint: 'Ваше имя'),
          const SizedBox(height: AppSpacing.md),

          Text('О себе', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 300,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Расскажите о своём опыте и специализации',
              hintStyle: AppTextStyles.body.copyWith(color: kTextTertiary),
              filled: true,
              fillColor: kBgTertiary,
              counterStyle: AppTextStyles.caption.copyWith(color: kTextTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: kBorder),
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
                foregroundColor: kBgPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: kBgPrimary, strokeWidth: 2))
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
