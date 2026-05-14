import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme ───────────────────────────────────────────────────────

const _themeKey = 'app_theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_themeKey);
    state = switch (val) {
      'light'  => ThemeMode.light,
      'system' => ThemeMode.system,
      _        => ThemeMode.dark,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, switch (mode) {
      ThemeMode.light  => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark   => 'dark',
    });
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

// ─── Locale ──────────────────────────────────────────────────────

const _localeKey = 'app_locale';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ru');

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_localeKey);
    if (val != null) state = Locale(val);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
