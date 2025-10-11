import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 教程提示页面
///
/// 显示cooking tips和学习教程
/// TODO: 后续开发完整的教程内容展示
class TipsScreen extends StatelessWidget {
  final String category; // 例如: "learn"
  final String tipsId;   // 例如: "tips_learn_50ddd8bd"

  const TipsScreen({
    super.key,
    required this.category,
    required this.tipsId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 80,
                color: AppColors.info,
              ),
              const SizedBox(height: 24),
              Text(
                '教程功能开发中',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('分类', category),
                      const Divider(height: 24),
                      _buildInfoRow('Tips ID', tipsId),
                      const Divider(height: 24),
                      _buildInfoRow('文件路径', 'assets/tips/$category/$tipsId.json'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '该功能将在后续版本中提供详细的烹饪技巧和教程内容',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取页面标题
  String _getTitle() {
    switch (category) {
      case 'learn':
        return '学习教程';
      case 'technique':
        return '烹饪技巧';
      case 'ingredient':
        return '食材知识';
      default:
        return '烹饪提示';
    }
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
