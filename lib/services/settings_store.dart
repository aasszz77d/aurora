import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

/// 应用设置。
class SettingsStore {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  static const _themeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';
  static const _virtKeysKey = 'virt_keys';

  AppThemeMode themeMode = AppThemeMode.system;
  double fontSize = 14;
  bool showVirtKeys = true;

  final List<void Function()> _listeners = [];

  void addListener(void Function() fn) => _listeners.add(fn);
  void removeListener(void Function() fn) => _listeners.remove(fn);
  void _notify() {
    for (final fn in List.of(_listeners)) {
      fn();
    }
  }

  ThemeMode get materialThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_themeKey);
    themeMode = switch (t) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
    fontSize = prefs.getDouble(_fontSizeKey) ?? 14;
    showVirtKeys = prefs.getBool(_virtKeysKey) ?? true;
    _notify();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      switch (mode) {
        AppThemeMode.system => 'system',
        AppThemeMode.light => 'light',
        AppThemeMode.dark => 'dark',
      },
    );
    _notify();
  }

  Future<void> setFontSize(double size) async {
    fontSize = size.clamp(10, 24);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
    _notify();
  }

  Future<void> setShowVirtKeys(bool value) async {
    showVirtKeys = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_virtKeysKey, value);
    _notify();
  }
}
