import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/network/dio_client.dart';

class _Suggestion {
  final String name;
  final String fullName;
  final double lat;
  final double lng;
  const _Suggestion(
      {required this.name,
      required this.fullName,
      required this.lat,
      required this.lng});

  factory _Suggestion.fromJson(Map<String, dynamic> j) => _Suggestion(
        name: j['name'] as String,
        fullName: j['fullName'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}

// M-2: Адрес работы мастера с 2GIS автоподсказкой
class MasterAddressScreen extends StatefulWidget {
  const MasterAddressScreen({super.key});

  @override
  State<MasterAddressScreen> createState() => _MasterAddressScreenState();
}

class _MasterAddressScreenState extends State<MasterAddressScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  List<_Suggestion> _suggestions = [];
  _Suggestion? _selected;
  Timer? _debounce;
  bool _searching = false;
  bool _loading   = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Если пользователь начал редактировать после выбора — сбрасываем выбор
    if (_selected != null && _ctrl.text != _selected!.fullName) {
      setState(() => _selected = null);
    }
    _debounce?.cancel();
    final q = _ctrl.text.trim();
    if (q.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(q));
  }

  Future<void> _fetchSuggestions(String q) async {
    setState(() => _searching = true);
    try {
      final res = await createDio().get('/geocode/suggest', queryParameters: {'q': q});
      final list = (res.data as List)
          .map((e) => _Suggestion.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _suggestions = list);
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _select(_Suggestion s) {
    setState(() {
      _selected    = s;
      _suggestions = [];
    });
    _ctrl.text = s.fullName;
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _focus.unfocus();
  }

  bool get _canSubmit => _selected != null;

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await createDio().patch('/masters/me', data: {
        'address': _selected!.fullName,
        'lat': _selected!.lat,
        'lng': _selected!.lng,
      });
      if (mounted) context.push(AppRoutes.masterPortfolio);
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
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text('Адрес работы', style: AppTextStyles.title),
        leading: BackButton(color: kTextPrimary, onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text('Где вы принимаете?', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Укажите адрес — клиенты увидят расстояние до вас.',
              style: AppTextStyles.body.copyWith(color: kTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ─── Поле ввода ──────────────────────────────────────
            TextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: true,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'ул. Кенесары 40, Астана',
                hintStyle: AppTextStyles.body.copyWith(color: kTextTertiary),
                filled: true,
                fillColor: kBgSecondary,
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: kGold)),
                      )
                    : _selected != null
                        ? const Icon(Icons.check_circle_outline,
                            color: kSuccess, size: 20)
                        : null,
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
              ),
            ),

            // ─── Список подсказок ────────────────────────────────
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: kBgSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: kBorder),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: kBorder),
                  itemBuilder: (_, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 4),
                      leading: const Icon(Icons.location_on_outlined,
                          color: kTextTertiary, size: 18),
                      title: Text(s.name, style: AppTextStyles.label),
                      subtitle: s.fullName != s.name
                          ? Text(s.fullName,
                              style: AppTextStyles.caption
                                  .copyWith(color: kTextTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          : null,
                      onTap: () => _select(s),
                    );
                  },
                ),
              ),

            // ─── Подсказка если ничего не нашли ─────────────────
            if (!_searching &&
                _ctrl.text.trim().length >= 3 &&
                _suggestions.isEmpty &&
                _selected == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Ничего не найдено. Уточните запрос.',
                  style:
                      AppTextStyles.caption.copyWith(color: kTextTertiary),
                ),
              ),

            const Spacer(),
            PrimaryButton(
              label: 'Далее',
              onPressed: _save,
              loading: _loading,
              enabled: _canSubmit,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
