import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller pengelola mode tema aplikasi (Light, Dark, System)
/// dengan persistensi lokal via SharedPreferences.
class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeController({ThemeMode initialMode = ThemeMode.system}) : _themeMode = initialMode;

  ThemeMode get themeMode => _themeMode;

  /// Memeriksa apakah saat ini aplikasi aktif dalam mode gelap.
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Memuat preferensi tema dari SharedPreferences.
  Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        if (saved == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (saved == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
        notifyListeners();
      }
    } catch (_) {
      // Fallback aman ke ThemeMode.system jika penyimpanan lokal belum siap
    }
  }

  /// Mengatur mode tema baru dan menyimpannya ke persistensi lokal.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {
      // Abaikan kegagalan I/O pada testing environment
    }
  }

  /// Melakukan toggle cepat antara Light dan Dark mode.
  void toggleTheme(BuildContext context) {
    final currentDark = isDark(context);
    setThemeMode(currentDark ? ThemeMode.light : ThemeMode.dark);
  }
}
