import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用文本样式
class AppTextStyles {
  // 标题样式
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // 正文样式
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // 标签样式
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // 按钮样式
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // 特殊用途样式

  /// 菜谱标题
  static const TextStyle recipeTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// 菜谱描述
  static const TextStyle recipeDescription = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.6,
    color: AppColors.textSecondary,
  );

  /// 食材列表
  static const TextStyle ingredient = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.8,
  );

  /// 烹饪步骤
  static const TextStyle cookingStep = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.7,
  );

  /// 标签/徽章
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// AI 消息
  static const TextStyle aiMessage = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.6,
  );

  /// 卡片标题
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// 卡片副标题
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// 导航栏标题
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 底部导航标签
  static const TextStyle bottomNavLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}
