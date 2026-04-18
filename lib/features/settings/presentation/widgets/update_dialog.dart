import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/update_service.dart';

/// 显示升级对话框并编排「下载 → 安装」流程。
///
/// - [currentVersionName] 当前版本名，用于对比显示
/// - 返回值仅表示对话框是否 dismiss；后续安装由系统完成
Future<void> showUpdateDialog({
  required BuildContext context,
  required WidgetRef ref,
  required UpdateInfo info,
  required String currentVersionName,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(
      info: info,
      currentVersionName: currentVersionName,
      service: ref.read(updateServiceProvider),
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({
    required this.info,
    required this.currentVersionName,
    required this.service,
  });

  final UpdateInfo info;
  final String currentVersionName;
  final UpdateService service;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = 0.0;
  bool _downloading = false;
  String? _error;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('dialog disposed');
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0.0;
    });
    _cancelToken = CancelToken();
    try {
      final path = await widget.service.downloadUpdate(
        widget.info,
        cancelToken: _cancelToken,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      await widget.service.installApk(path);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _skipThisVersion() async {
    await widget.service.skipVersion(widget.info.versionCode);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final sizeMB = info.size > 0 ? (info.size / 1024 / 1024).toStringAsFixed(1) : '--';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue),
          const SizedBox(width: 8),
          Text('发现新版本 ${info.versionName}'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本：${widget.currentVersionName}', style: _dimStyle(context)),
            Text('安装包大小：约 $sizeMB MB', style: _dimStyle(context)),
            const SizedBox(height: 12),
            if (info.notes.trim().isNotEmpty) ...[
              const Text('更新内容', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: info.notes.trim(),
                      selectable: true,
                      shrinkWrap: true,
                      onTapLink: (text, href, title) {
                        if (href == null || href.isEmpty) return;
                        final uri = Uri.tryParse(href);
                        if (uri != null) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_downloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 6),
              Text('下载中 ${(_progress * 100).toStringAsFixed(0)}%',
                  style: _dimStyle(context)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text('下载失败：$_error',
                  style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: _downloading
          ? [
              TextButton(
                onPressed: () {
                  _cancelToken?.cancel('用户取消');
                  setState(() => _downloading = false);
                },
                child: const Text('取消'),
              ),
            ]
          : [
              TextButton(onPressed: _skipThisVersion, child: const Text('跳过本版')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('稍后'),
              ),
              FilledButton(onPressed: _startDownload, child: const Text('立即更新')),
            ],
    );
  }

  TextStyle? _dimStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]);
}
