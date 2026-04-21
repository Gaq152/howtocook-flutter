import 'package:flutter/material.dart';

/// 统一的 SnackBar 封装，自动避让底部胶囊导航栏与页面内底部固定操作区。
///
/// 设计动机：
/// - 全局主题使用 [SnackBarBehavior.floating]，默认贴内层 Scaffold 底部，
///   会遮挡外层 [MainScaffold] 的胶囊导航栏（76px）、AI 聊天输入框、
///   详情页的三按钮操作栏等页面内固定底部元素。
/// - 通过统一封装，调用方仅需根据页面类型传入 [bottomOffset] 即可安全避让。
///
/// 典型用法：
/// - 普通 Tab 页（有外层胶囊栏）：[AppSnackBar.show]，[bottomOffset] 保持默认 0
/// - AI 聊天页（输入框 + 胶囊栏）：[bottomOffset] 传 [kChatBottomOffset]
/// - 菜谱/教程详情页（三按钮栏）：[bottomOffset] 传 [kDetailBottomOffset]
class AppSnackBar {
  AppSnackBar._();

  /// 基础底部边距：避开外层胶囊导航栏（76px）并留呼吸空间。
  static const double _baseBottomMargin = 80.0;
  static const double _horizontalMargin = 16.0;

  /// AI 聊天页需要的额外偏移（输入框高度 ~56 + 间隔）。
  static const double kChatBottomOffset = 60;

  /// 菜谱/教程详情页的 Positioned 三按钮操作栏需要的额外偏移。
  static const double kDetailBottomOffset = 30;

  /// 显示简单文本提示。
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    double bottomOffset = 0,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      _build(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        bottomOffset: bottomOffset,
      ),
    );
  }

  /// 显示自定义 content（如带进度指示器的 Row）。
  static void showCustom(
    BuildContext context, {
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    double bottomOffset = 0,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      _build(
        content: content,
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        bottomOffset: bottomOffset,
      ),
    );
  }

  /// 使用已保存的 [ScaffoldMessengerState] 显示提示，适用于异步操作前
  /// 预先获取 messenger 以避免 `context` 失效的场景。
  static void showWithMessenger(
    ScaffoldMessengerState messenger,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    double bottomOffset = 0,
  }) {
    messenger.showSnackBar(
      _build(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        bottomOffset: bottomOffset,
      ),
    );
  }

  static SnackBar _build({
    required Widget content,
    required Color? backgroundColor,
    required Duration duration,
    required SnackBarAction? action,
    required double bottomOffset,
  }) {
    return SnackBar(
      content: content,
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
      margin: EdgeInsets.only(
        left: _horizontalMargin,
        right: _horizontalMargin,
        bottom: _baseBottomMargin + bottomOffset,
      ),
    );
  }
}
