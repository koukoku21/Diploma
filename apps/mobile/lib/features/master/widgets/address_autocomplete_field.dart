import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';

class AddressSuggestion {
  final String name;
  final String fullName;
  final double lat;
  final double lng;
  const AddressSuggestion(
      {required this.name,
      required this.fullName,
      required this.lat,
      required this.lng});

  factory AddressSuggestion.fromJson(Map<String, dynamic> j) =>
      AddressSuggestion(
        name: j['name'] as String,
        fullName: j['fullName'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}

/// Поле адреса с 2GIS автоподсказкой.
/// [onSelected] вызывается при выборе варианта.
/// [initialValue] — предзаполненный текст (без lat/lng, только отображение).
class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    this.initialValue = '',
    required this.onSelected,
  });

  final String initialValue;
  final void Function(AddressSuggestion s) onSelected;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  late final TextEditingController _ctrl;
  final _focus = FocusNode();

  List<AddressSuggestion> _suggestions = [];
  bool _searching    = false;
  bool _hasSelection = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _hasSelection = widget.initialValue.isNotEmpty;
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_hasSelection) setState(() => _hasSelection = false);
    final q = _ctrl.text.trim();
    _debounce?.cancel();
    if (q.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _fetch(q));
  }

  Future<void> _fetch(String q) async {
    setState(() => _searching = true);
    try {
      final res =
          await createDio().get('/geocode/suggest', queryParameters: {'q': q});
      final list = (res.data as List)
          .map((e) => AddressSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _suggestions = list);
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _select(AddressSuggestion s) {
    setState(() {
      _suggestions  = [];
      _hasSelection = true;
    });
    _ctrl.text = s.fullName;
    _ctrl.selection =
        TextSelection.collapsed(offset: _ctrl.text.length);
    _focus.unfocus();
    widget.onSelected(s);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'ул. Кенесары 40, Астана',
            hintStyle: AppTextStyles.body.copyWith(color: kTextTertiary),
            filled: true,
            fillColor: kBgTertiary,
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kGold)),
                  )
                : _hasSelection
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
      ],
    );
  }
}
