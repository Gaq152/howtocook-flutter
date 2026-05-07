import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/entities/recipe.dart';
import '../../../../core/theme/app_colors.dart';

/// 食谱分享卡片 Widget
///
/// 用于生成美观的食谱卡片图片，底部包含 App 专用二维码
/// 此 Widget 专门用于 screenshot 包截图
///
/// ✨ 长截图设计：不限制高度，完整展示所有内容
class RecipeShareCard extends StatelessWidget {
  final Recipe recipe;
  final String qrData; // 二维码内容（Custom Scheme）

  const RecipeShareCard({
    super.key,
    required this.recipe,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    // ✨ 直接返回Column，不使用Container避免任何约束传递问题
    return Container(
      width: 375, // 固定宽度（适合手机屏幕）
      // 不设置height，让内容自然延展
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.primaryLight,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 让Column自适应内容高度
        children: [
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和难度
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // 分类
                  _buildCategory(),
                  const SizedBox(height: 16),

                  // 食材列表
                  _buildIngredientsSection(),
                  const SizedBox(height: 16),

                  // 工具列表（如果有）
                  if (recipe.tools.isNotEmpty) ...[
                    _buildToolsSection(),
                    const SizedBox(height: 16),
                  ],

                  // 步骤列表
                  _buildStepsSection(),

                  // 小贴士（如果有）
                  if (recipe.tips != null && recipe.tips!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTipsSection(),
                  ],
                ],
              ),
            ),

            // 二维码区域
            _buildQRSection(),
        ],
      ),
    );
  }

  /// 构建标题和难度
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            recipe.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // 难度星级
          Row(
            children: [
              const Text(
                '🔥 难度: ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '⭐' * recipe.difficulty,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建分类
  Widget _buildCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '📂 ${recipe.categoryName}',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建食材部分
  Widget _buildIngredientsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 食材',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // ✨ 显示所有食材（长截图）
          ...recipe.ingredients.map((ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${ingredient.text}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// 构建工具部分
  Widget _buildToolsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 所需工具',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.tools.map((tool) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tool,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryDark,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建步骤部分
  Widget _buildStepsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👨‍🍳 制作步骤',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildStepItems(),
        ],
      ),
    );
  }

  static final _headingPattern = RegExp(r'^#{1,4}\s+(.+)$');

  List<Widget> _buildStepItems() {
    final widgets = <Widget>[];
    int stepNumber = 0;
    for (final step in recipe.steps) {
      final match = _headingPattern.firstMatch(step.description);
      if (match != null) {
        widgets.add(Padding(
          padding: EdgeInsets.only(
            top: widgets.isEmpty ? 0 : 8,
            bottom: 4,
          ),
          child: Text(
            match.group(1)!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ));
      } else {
        stepNumber++;
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
      }
    }
    return widgets;
  }

  /// 构建小贴士部分
  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.butter.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.butter.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 小贴士',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // ✨ 显示完整小贴士（长截图）
          Text(
            recipe.tips!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建二维码区域
  Widget _buildQRSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // 20 → 16
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 二维码
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textDisabled.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200, // 增大二维码尺寸从 120 → 200（图片中将是 400x400）
              errorCorrectionLevel: QrErrorCorrectLevel.M, // 保持中等纠错级别，平衡尺寸和容错
              backgroundColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 12),

          // 提示文字
          Text(
            '使用「智能菜谱助手」扫描',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '可添加/更新到我的食谱',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // App 名称
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '分享自 ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textDisabled,
                ),
              ),
              Text(
                '智能菜谱助手',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
