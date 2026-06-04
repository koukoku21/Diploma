import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'app_theme.dart';

// ─── Фоны ────────────────────────────────────────────────────────
const Color kBgPrimary   = Color(0xFF0A0A0F);
const Color kBgSecondary = Color(0xFF111118);
const Color kBgTertiary  = Color(0xFF16161F);

// ─── Акценты ─────────────────────────────────────────────────────
const Color kGold      = Color(0xFFC9A96E);
const Color kGoldLight = Color(0xFFE8C99A);
const Color kRose      = Color(0xFFD4748A);

// ─── Текст ───────────────────────────────────────────────────────
const Color kTextPrimary   = Color(0xFFF0EDE8);
const Color kTextSecondary = Color(0xFF9B9690);
const Color kTextTertiary  = Color(0xFF5A5750);

// ─── Семантика ───────────────────────────────────────────────────
const Color kSuccess = Color(0xFF1D9E75);
const Color kError   = Color(0xFFD4748A);

// ─── Границы ─────────────────────────────────────────────────────
const Color kBorder  = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
const Color kBorder2 = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)

// ─── Context extensions ───────────────────────────────────────────
extension AppColorExt on BuildContext {
  AppColorScheme get colors => AppColorScheme.of(this);
}

extension AppL10nExt on BuildContext {
  S get l10n => S.of(this)!;
}
