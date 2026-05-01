import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, dark, light }

enum KeyboardLayoutMode { translit, malayalam, handwriting }

class AppSettings extends ChangeNotifier {
  AppSettings({
    required this.themeMode,
    required this.keyboardHeightFactor,
    required this.showKeyBorders,
    required this.layoutMode,
    required this.isMalayalamMode,
  });

  static const _prefsThemeMode = 'themeMode';
  static const _prefsKeyboardHeightFactor = 'keyboardHeightFactor';
  static const _prefsShowKeyBorders = 'showKeyBorders';
  static const _prefsLayoutMode = 'layoutMode';
  static const _prefsIsMalayalamMode = 'isMalayalamMode';

  static const _nativeSettingsChannel = MethodChannel('englam/settings');

  AppThemeMode themeMode;
  double keyboardHeightFactor;
  bool showKeyBorders;
  KeyboardLayoutMode layoutMode;
  bool isMalayalamMode;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeRaw = prefs.getString(_prefsThemeMode) ?? 'system';
    final layoutRaw = prefs.getString(_prefsLayoutMode) ?? 'translit';
    final height = prefs.getDouble(_prefsKeyboardHeightFactor) ?? 0.58;
    final borders = prefs.getBool(_prefsShowKeyBorders) ?? false;
    final isMalayalamMode = prefs.getBool(_prefsIsMalayalamMode) ?? true;

    final settings = AppSettings(
      themeMode: _themeFromString(themeRaw),
      keyboardHeightFactor: height.clamp(0.45, 0.75),
      showKeyBorders: borders,
      layoutMode: _layoutFromString(layoutRaw),
      isMalayalamMode: isMalayalamMode,
    );
    await settings._pushToAndroidIme();
    return settings;
  }

  static AppThemeMode _themeFromString(String v) {
    return switch (v) {
      'dark' => AppThemeMode.dark,
      'light' => AppThemeMode.light,
      _ => AppThemeMode.system,
    };
  }

  static KeyboardLayoutMode _layoutFromString(String v) {
    return switch (v) {
      'malayalam' => KeyboardLayoutMode.malayalam,
      'handwriting' => KeyboardLayoutMode.handwriting,
      _ => KeyboardLayoutMode.translit,
    };
  }

  static String _themeToString(AppThemeMode v) {
    return switch (v) {
      AppThemeMode.dark => 'dark',
      AppThemeMode.light => 'light',
      AppThemeMode.system => 'system',
    };
  }

  static String _layoutToString(KeyboardLayoutMode v) {
    return switch (v) {
      KeyboardLayoutMode.malayalam => 'malayalam',
      KeyboardLayoutMode.handwriting => 'handwriting',
      KeyboardLayoutMode.translit => 'translit',
    };
  }

  Future<void> setThemeMode(AppThemeMode v) async {
    if (themeMode == v) return;
    themeMode = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsThemeMode, _themeToString(v));
  }

  Future<void> setKeyboardHeightFactor(double v) async {
    final clamped = v.clamp(0.45, 0.75);
    if (keyboardHeightFactor == clamped) return;
    keyboardHeightFactor = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKeyboardHeightFactor, clamped);
    await _pushToAndroidIme();
  }

  Future<void> setShowKeyBorders(bool v) async {
    if (showKeyBorders == v) return;
    showKeyBorders = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsShowKeyBorders, v);
    await _pushToAndroidIme();
  }

  Future<void> setLayoutMode(KeyboardLayoutMode v) async {
    if (layoutMode == v) return;
    layoutMode = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLayoutMode, _layoutToString(v));
    await _pushToAndroidIme();
  }

  Future<void> setMalayalamMode(bool v) async {
    if (isMalayalamMode == v) return;
    isMalayalamMode = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsIsMalayalamMode, v);
    await _pushToAndroidIme();
  }

  Future<void> _pushToAndroidIme() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _nativeSettingsChannel
          .invokeMethod<void>('setSettings', <String, Object?>{
            _prefsKeyboardHeightFactor: keyboardHeightFactor,
            _prefsShowKeyBorders: showKeyBorders,
            _prefsLayoutMode: _layoutToString(layoutMode),
            _prefsIsMalayalamMode: isMalayalamMode,
          });
    } catch (_) {}
  }
}
