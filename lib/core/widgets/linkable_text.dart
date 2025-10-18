import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// 可链接文本组件
///
/// 自动识别文本中的URL并转换为可点击的链接
class LinkableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _parseTextWithLinks(text, style ?? const TextStyle());
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// 解析文本中的URL链接
  List<InlineSpan> _parseTextWithLinks(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];

    // URL正则表达式：匹配http/https开头的URL
    final urlPattern = RegExp(
      r'https?://[^\s\)\]]+',
      caseSensitive: false,
    );

    int lastMatchEnd = 0;
    final matches = urlPattern.allMatches(text);

    for (final match in matches) {
      // 添加URL之前的普通文本
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      // 添加URL链接
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: baseStyle.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchURL(url),
      ));

      lastMatchEnd = match.end;
    }

    // 添加最后一段普通文本
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: baseStyle)]
        : spans;
  }

  /// 打开URL
  Future<void> _launchURL(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 在外部浏览器中打开
        );
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }
}

/// 可链接文本组件（富文本版本，支持Markdown格式的链接）
///
/// 支持识别Markdown格式的链接：[文本](URL)
/// 支持http/https外部链接和tips://应用内链接
class LinkableTextRich extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkableTextRich(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _parseTextWithLinks(context, text, style ?? const TextStyle());
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// 解析文本中的URL链接（包括Markdown格式）
  List<InlineSpan> _parseTextWithLinks(BuildContext context, String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];

    // Markdown链接正则：[文本](URL)
    // 支持 http://, https://, tips:// 等协议
    final markdownLinkPattern = RegExp(
      r'\[([^\]]+)\]\(((?:https?|tips)://[^\)]+)\)',
      caseSensitive: false,
    );

    int lastMatchEnd = 0;

    // 先处理Markdown格式的链接
    final markdownMatches = markdownLinkPattern.allMatches(text);

    if (markdownMatches.isEmpty) {
      // 如果没有Markdown链接，则用普通URL匹配
      return _parseSimpleURLs(text, baseStyle);
    }

    for (final match in markdownMatches) {
      // 添加链接之前的普通文本（可能包含普通URL）
      if (match.start > lastMatchEnd) {
        final beforeText = text.substring(lastMatchEnd, match.start);
        spans.addAll(_parseSimpleURLs(beforeText, baseStyle));
      }

      // 添加Markdown链接
      final linkText = match.group(1)!;
      final url = match.group(2)!;

      spans.add(TextSpan(
        text: linkText,
        style: baseStyle.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _handleLinkTap(context, url),
      ));

      lastMatchEnd = match.end;
    }

    // 添加最后一段文本
    if (lastMatchEnd < text.length) {
      final afterText = text.substring(lastMatchEnd);
      spans.addAll(_parseSimpleURLs(afterText, baseStyle));
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: baseStyle)]
        : spans;
  }

  /// 解析普通URL（不含Markdown格式）
  List<InlineSpan> _parseSimpleURLs(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final urlPattern = RegExp(
      r'https?://[^\s\)\]]+',
      caseSensitive: false,
    );

    int lastMatchEnd = 0;
    final matches = urlPattern.allMatches(text);

    for (final match in matches) {
      // 添加URL之前的普通文本
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      // 添加URL链接
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: baseStyle.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchURL(url),
      ));

      lastMatchEnd = match.end;
    }

    // 添加最后一段普通文本
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: baseStyle)]
        : spans;
  }

  /// 处理链接点击
  void _handleLinkTap(BuildContext context, String urlString) {
    if (urlString.startsWith('tips://')) {
      // 应用内链接，使用GoRouter导航
      _navigateToTips(context, urlString);
    } else {
      // 外部链接，使用浏览器打开
      _launchURL(urlString);
    }
  }

  /// 导航到应用内的tips页面
  void _navigateToTips(BuildContext context, String urlString) {
    try {
      // 解析tips://协议的URL
      // 格式: tips://learn/tips_learn_50ddd8bd.json

      // 移除协议部分
      if (!urlString.startsWith('tips://')) {
        debugPrint('Invalid tips URL format: $urlString');
        return;
      }

      // 提取路径部分: learn/tips_learn_50ddd8bd.json
      final pathPart = urlString.substring('tips://'.length);

      // 分割路径
      final pathSegments = pathPart.split('/');

      if (pathSegments.length >= 2) {
        final category = pathSegments[0]; // learn
        var tipsId = pathSegments.sublist(1).join('/'); // tips_learn_50ddd8bd.json

        // 移除.json后缀（如果存在）
        if (tipsId.endsWith('.json')) {
          tipsId = tipsId.substring(0, tipsId.length - 5);
        }

        // 构建路由路径
        // tips://learn/tips_learn_50ddd8bd.json → /tips/learn/tips_learn_50ddd8bd
        final routePath = '/tips/$category/$tipsId';

        debugPrint('Navigating to tips: $routePath (from: $urlString)');
        context.push(routePath);
      } else {
        debugPrint('Invalid tips URL format: $urlString (not enough segments)');
      }
    } catch (e) {
      debugPrint('Failed to navigate to tips: $e');
    }
  }

  /// 打开外部URL
  Future<void> _launchURL(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 在外部浏览器中打开
        );
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }
}
