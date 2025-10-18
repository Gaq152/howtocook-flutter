import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/providers/tip_providers.dart';
import '../../domain/entities/tip.dart';
import '../../infrastructure/services/tip_share_service.dart';

Future<void> showTipShareSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Tip tip,
}) async {
  final shareService = ref.read(tipShareServiceProvider);
  final messenger = ScaffoldMessenger.of(context);

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('教程分享', style: AppTextStyles.h3),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.content_copy, color: AppColors.primary),
              title: const Text('复制纯文本'),
              subtitle: const Text('复制格式化后的教程内容到剪贴板'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final result = await shareService.shareAsText(tip);
                _showShareResult(
                  messenger,
                  result,
                  successMessage: '教程已复制到剪贴板',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.secondary),
              title: const Text('生成分享图片'),
              subtitle: const Text('生成带二维码的长图，可预览后保存或分享'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _handleShareImage(
                  context: context,
                  ref: ref,
                  tip: tip,
                  shareService: shareService,
                  messenger: messenger,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> _handleShareImage({
  required BuildContext context,
  required WidgetRef ref,
  required Tip tip,
  required TipShareService shareService,
  required ScaffoldMessengerState messenger,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _LoadingDialog(),
  );

  Uint8List? imageBytes;
  try {
    imageBytes = await shareService.generateTipImageBytes(tip, context);
  } catch (e) {
    debugPrint('生成教程分享图片异常: $e');
  } finally {
    try {
      if (navigator.mounted) {
        navigator.pop();
      }
    } catch (_) {}
  }

  if (imageBytes == null) {
    messenger.showSnackBar(const SnackBar(content: Text('生成分享图片失败，请稍后重试')));
    return;
  }

  if (!context.mounted) {
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _TipSharePreviewDialog(
      imageBytes: imageBytes!,
      tipTitle: tip.title,
      onSave: () async {
        final result = await shareService.saveImageBytes(imageBytes!, tip);
        _showShareResult(messenger, result, successMessage: '图片已保存到相册');
      },
      onShare: () async {
        final result = await shareService.shareImageBytes(imageBytes!, tip);
        _showShareResult(messenger, result, successMessage: '教程图片已分享');
      },
    ),
  );
}

void _showShareResult(
  ScaffoldMessengerState messenger,
  TipShareResult result, {
  required String successMessage,
}) {
  switch (result) {
    case TipShareResult.success:
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      break;
    case TipShareResult.failed:
      messenger.showSnackBar(const SnackBar(content: Text('操作失败，请稍后重试')));
      break;
    case TipShareResult.cancelled:
      break;
  }
}

class _TipSharePreviewDialog extends StatelessWidget {
  const _TipSharePreviewDialog({
    required this.imageBytes,
    required this.tipTitle,
    required this.onSave,
    required this.onShare,
  });

  final Uint8List imageBytes;
  final String tipTitle;
  final Future<void> Function() onSave;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('分享预览', style: AppTextStyles.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageBytes, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await onSave();
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('保存到相册'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ShareButton(
                        icon: Icons.wechat,
                        label: '微信',
                        color: const Color(0xFF07C160),
                        onTap: () async {
                          Navigator.pop(context);
                          await onShare();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ShareButton(
                        icon: Icons.chat_bubble,
                        label: 'QQ',
                        color: const Color(0xFF12B7F5),
                        onTap: () async {
                          Navigator.pop(context);
                          await onShare();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ShareButton(
                        icon: Icons.share,
                        label: '更多',
                        color: AppColors.secondary,
                        onTap: () async {
                          Navigator.pop(context);
                          await onShare();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 48),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在生成分享图片...'),
            ],
          ),
        ),
      ),
    );
  }
}
