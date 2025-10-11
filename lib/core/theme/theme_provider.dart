import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题模式枚举
enum AppThemeMode {
  light,   // 浅色模式
  dark,    // 深色模式
  system,  // 跟随系统
}

/// 主题模式状态通知器
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.system);

  /// 设置主题模式
  void setThemeMode(AppThemeMode mode) {
    state = mode;
  }

  /// 切换到浅色模式
  void setLightMode() {
    state = AppThemeMode.light;
  }

  /// 切换到深色模式
  void setDarkMode() {
    state = AppThemeMode.dark;
  }

  /// 切换到跟随系统
  void setSystemMode() {
    state = AppThemeMode.system;
  }

  /// 转换为 ThemeMode
  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// 主题模式 Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// 当前主题模式 Provider（转换为 ThemeMode）
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final appThemeMode = ref.watch(themeModeProvider);
  switch (appThemeMode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});

/// 是否为深色模式 Provider（用于 UI 判断）
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);

  if (themeMode == AppThemeMode.dark) {
    return true;
  } else if (themeMode == AppThemeMode.light) {
    return false;
  }

  // 跟随系统时，需要在 Widget 中通过 MediaQuery 判断
  // 这里返回 false 作为默认值
  return false;
});
