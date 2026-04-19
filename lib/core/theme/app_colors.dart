import 'package:flutter/material.dart';

/// 应用颜色常量 — 温暖治愈系 · 奶油米色
class AppColors {
  // 主色调（陶土色系）
  static const primary = Color(0xFFD06A4C);
  static const primaryLight = Color(0xFFF4D9CE);
  static const primaryDark = Color(0xFF8E3F26);

  // 辅助色（鼠尾草绿）
  static const secondary = Color(0xFF8CA471);
  static const secondaryLight = Color(0xFFBCD4A4);
  static const secondaryDark = Color(0xFF5E7A42);

  // 装饰色
  static const plum = Color(0xFFB47C8A);
  static const butter = Color(0xFFE8B962);

  // 功能色
  static const success = Color(0xFF8CA471);
  static const warning = Color(0xFFE8B962);
  static const error = Color(0xFFD06A4C);
  static const info = Color(0xFF8CA471);

  // 中性色（浅色模式）— 奶油色系
  static const textPrimary = Color(0xFF2A241E);
  static const textSecondary = Color(0xFF5C5248);
  static const textDisabled = Color(0xFF938577);
  static const divider = Color(0x142A241E); // rgba(42,36,30,0.08)
  static const background = Color(0xFFFBF7F1); // 奶油底色
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF4EEE4); // 嵌套卡片用

  // 中性色（深色模式）
  static const textPrimaryDark = Color(0xFFF1EADF);
  static const textSecondaryDark = Color(0xFFC6BBAE);
  static const textDisabledDark = Color(0xFF847A6E);
  static const dividerDark = Color(0x17F1EADF); // rgba(241,234,223,0.09)
  static const backgroundDark = Color(0xFF1A1614);
  static const surfaceDark = Color(0xFF231E1A);
  static const surfaceAltDark = Color(0xFF2B2520);

  // 难度颜色
  static const difficultyEasy = Color(0xFF8CA471);
  static const difficultyMedium = Color(0xFFE8B962);
  static const difficultyHard = Color(0xFFD06A4C);
  static const difficultyVeryHard = Color(0xFF8E3F26);

  // AI 聊天相关
  static const aiGradientStart = primary;
  static const aiGradientEnd = plum;
  static const userMessageBg = Color(0xFF2A241E);
  static const assistantMessageBg = Color(0xFFF4EEE4);

  // 菜谱卡片
  static const cardShadow = Color(0x0F2A241E);
  static const favoriteIcon = Color(0xFFD06A4C);

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
