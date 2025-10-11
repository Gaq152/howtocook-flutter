import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  // 主色调（橙色系）
  static const primary = Color(0xFFFF6B35);
  static const primaryLight = Color(0xFFFF8C61);
  static const primaryDark = Color(0xFFE55A2B);

  // 辅助色
  static const secondary = Color(0xFF4ECDC4);
  static const secondaryLight = Color(0xFF7FE0D9);
  static const secondaryDark = Color(0xFF2BA8A0);

  // 功能色
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  // 中性色（浅色模式）
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textDisabled = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0E0E0);
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);

  // 中性色（深色模式）
  static const textPrimaryDark = Color(0xFFE0E0E0);
  static const textSecondaryDark = Color(0xFFB0B0B0);
  static const textDisabledDark = Color(0xFF757575);
  static const dividerDark = Color(0xFF424242);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);

  // 难度颜色
  static const difficultyEasy = Color(0xFF4CAF50);
  static const difficultyMedium = Color(0xFFFFC107);
  static const difficultyHard = Color(0xFFFF9800);
  static const difficultyVeryHard = Color(0xFFF44336);

  // AI 聊天相关
  static const aiGradientStart = primary;
  static const aiGradientEnd = primaryLight;
  static const userMessageBg = Color(0xFFE3F2FD);
  static const assistantMessageBg = Color(0xFFF5F5F5);

  // 菜谱卡片
  static const cardShadow = Color(0x1F000000);
  static const favoriteIcon = Color(0xFFFF6B6B);

  // 工具方法

  /// 根据难度获取颜色
  static Color getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return difficultyEasy;
      case 2:
        return difficultyMedium;
      case 3:
        return difficultyHard;
      case 4:
        return difficultyVeryHard;
      default:
        return difficultyMedium;
    }
  }

  /// 根据难度获取文本
  static String getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return '简单';
      case 2:
        return '中等';
      case 3:
        return '困难';
      case 4:
        return '极难';
      default:
        return '未知';
    }
  }
}
