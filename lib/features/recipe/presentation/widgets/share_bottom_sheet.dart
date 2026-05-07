import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/recipe.dart';
import '../../infrastructure/services/recipe_share_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';

Future<void> showRecipeShareSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Recipe recipe,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ShareBottomSheet(recipe: recipe, ref: ref),
  );
}

class _ShareBottomSheet extends StatefulWidget {
  final Recipe recipe;
  final WidgetRef ref;

  const _ShareBottomSheet({required this.recipe, required this.ref});

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  Uint8List? _imageBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateImage();
  }

  Future<void> _generateImage() async {
    try {
      final service = widget.ref.read(recipeShareServiceProvider);
      final bytes =
          await service.generateRecipeImageBytes(widget.recipe, context);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _loading = false;
        if (bytes == null) _error = '图片生成失败';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _shareImage() async {
    if (_imageBytes == null) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/recipe_${widget.recipe.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(_imageBytes!);
      await Share.shareXFiles([XFile(file.path)],
          text: '分享食谱：${widget.recipe.name}');
      try {
        await file.delete();
      } catch (_) {}
    } catch (e) {
      AppSnackBar.showWithMessenger(messenger, '分享失败: $e',
          backgroundColor: AppColors.error);
    }
  }

  Future<void> _shareText() async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      final service = widget.ref.read(recipeShareServiceProvider);
      await service.shareAsText(widget.recipe);
    } catch (e) {
      AppSnackBar.showWithMessenger(messenger, '分享失败: $e',
          backgroundColor: AppColors.error);
    }
  }

  Future<void> _saveToGallery() async {
    if (_imageBytes == null) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      await Gal.putImageBytes(
        _imageBytes!,
        name: 'recipe_${widget.recipe.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      AppSnackBar.showWithMessenger(messenger, '已保存到相册',
          backgroundColor: AppColors.success);
    } catch (e) {
      AppSnackBar.showWithMessenger(messenger, '保存失败: $e',
          backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text('分享菜谱', style: AppTextStyles.h3),
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
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _error != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(_error!,
                                style:
                                    const TextStyle(color: AppColors.error)),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.divider),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(_imageBytes!,
                                  fit: BoxFit.contain),
                            ),
                          ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.image,
                    label: '分享图片',
                    color: AppColors.primary,
                    enabled: _imageBytes != null,
                    onTap: _shareImage,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.text_fields,
                    label: '分享文本',
                    color: AppColors.secondary,
                    enabled: true,
                    onTap: _shareText,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.save_alt,
                    label: '保存相册',
                    color: AppColors.success,
                    enabled: _imageBytes != null,
                    onTap: _saveToGallery,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
