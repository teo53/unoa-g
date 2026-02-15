import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/utils/app_logger.dart';

/// Theme mode notifier for managing app theme
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';

  // Cached box instance to avoid repeated openBox calls
  Box? _settingsBox;

  ThemeNotifier() : super(ThemeMode.system) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Open box once and cache it
      _settingsBox = await Hive.openBox(_boxName);
      final themeIndex = _settingsBox!.get(_themeKey, defaultValue: 0) as int;
      state = ThemeMode.values[themeIndex];
    } catch (e, stackTrace) {
      // Default to system theme if loading fails
      AppLogger.warning('Failed to initialize theme: $e', tag: 'ThemeNotifier');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      // Use cached box if available, otherwise open it
      _settingsBox ??= await Hive.openBox(_boxName);
      await _settingsBox!.put(_themeKey, mode.index);
    } catch (e, stackTrace) {
      // Log storage errors instead of silently ignoring
      AppLogger.warning('Failed to save theme: $e', tag: 'ThemeNotifier');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  void setLightMode() => setThemeMode(ThemeMode.light);
  void setDarkMode() => setThemeMode(ThemeMode.dark);
  void setSystemMode() => setThemeMode(ThemeMode.system);
}

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Is dark mode provider (convenience)
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  if (themeMode == ThemeMode.system) {
    // This will be updated based on system brightness
    return false;
  }
  return themeMode == ThemeMode.dark;
});
