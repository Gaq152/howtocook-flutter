import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  final String qrNote;

  const RecipeShareCard({
    super.key,
    required this.recipe,
    required this.qrData,
    required this.qrNote,
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
          colors: [AppColors.background, AppColors.primaryLight],
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

                if (recipe.description?.trim().isNotEmpty == true ||
                    recipe.estimatedCaloriesKcal != null) ...[
                  _buildOverviewSection(),
                  const SizedBox(height: 16),
                ],

                if (recipe.requirements.isNotEmpty ||
                    recipe.tools.isNotEmpty) ...[
                  _buildRequirementsSection(),
                  const SizedBox(height: 16),
                ],

                _buildIngredientsSection(),
                const SizedBox(height: 16),

                _buildStepsSection(),

                // 小贴士（如果有）
                if (recipe.tips != null && recipe.tips!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildTipsSection(),
                ],
                if (recipe.warnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildWarningsSection(),
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

  Widget _buildOverviewSection() {
    return _sectionCard(
      title: '📖 菜谱简介',
      children: [
        if (recipe.estimatedCaloriesKcal != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '估算总热量 ${recipe.estimatedCaloriesKcal} kcal',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        if (recipe.description?.trim().isNotEmpty == true)
          MarkdownBody(
            data: recipe.description!.trim(),
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRequirementsSection() {
    final entries = <String>[
      ...recipe.requirements.map((item) => item.text),
      ...recipe.tools.where(
        (tool) => !recipe.requirements.any((item) => item.text == tool),
      ),
    ];
    return _sectionCard(
      title: '🧺 必备原料和工具',
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $entry',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
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
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
            '🧮 用量与计算',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...recipe.calculationNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          // ✨ 显示所有食材（长截图）
          ...recipe.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data:
                              '${ingredient.text}${ingredient.optional ? ' （可选）' : ''}',
                          shrinkWrap: true,
                          fitContent: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (ingredient.table.isNotEmpty)
                          Text(
                            ingredient.table.entries
                                .map((entry) => '${entry.key}: ${entry.value}')
                                .join('  |  '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            '👨‍🍳 操作',
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
    for (final step in recipe.steps) {
      final match = _headingPattern.firstMatch(step.description);
      if (step.kind == 'heading' || step.title != null || match != null) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 8, bottom: 4),
            child: Text(
              step.title ?? match?.group(1) ?? step.description,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: MarkdownBody(
                    data: step.description,
                    shrinkWrap: true,
                    fitContent: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildWarningsSection() {
    return _sectionCard(
      title: '⚠️ 注意事项',
      color: AppColors.butter.withValues(alpha: 0.12),
      children: recipe.warnings
          .map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $warning',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          )
          .toList(),
    );
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
          MarkdownBody(
            data: recipe.tips!,
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
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
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 20,
      ), // 20 → 16
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
          // 二维码（大安静区 + 高对比度 + 定位增强边框）
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textPrimary, width: 3),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200,
              errorCorrectionLevel: QrErrorCorrectLevel.L,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
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
            qrNote,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // App 名称
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '分享自 ',
                style: TextStyle(fontSize: 11, color: AppColors.textDisabled),
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
