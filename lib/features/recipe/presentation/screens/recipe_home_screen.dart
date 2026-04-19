import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/providers/recipe_providers.dart';
import '../widgets/recipe_card.dart';
import '../../../../core/theme/app_colors.dart';

/// 菜谱首页
///
/// 显示所有菜谱的网格列表，支持分类筛选
class RecipeHomeScreen extends ConsumerStatefulWidget {
  const RecipeHomeScreen({super.key});

  @override
  ConsumerState<RecipeHomeScreen> createState() => _RecipeHomeScreenState();
}

class _RecipeHomeScreenState extends ConsumerState<RecipeHomeScreen> {
  /// 当前选中的分类ID，null表示"全部"
  String? _selectedCategory;

  /// 当前选中的难度，null表示"全部"
  int? _selectedDifficulty;

  /// 滚动控制器，用于双击滚动到顶部
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = _selectedCategory == null
        ? ref.watch(allRecipesProvider)
        : ref.watch(recipesByCategoryProvider(_selectedCategory!));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allRecipesProvider);
          await ref.read(allRecipesProvider.future);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildCollapsibleHeader(context),
            SliverToBoxAdapter(child: _buildCategoryFilter()),
            SliverToBoxAdapter(child: _buildFilterBar()),
            ...recipesAsync.when(
              data: (recipes) {
                final filtered = _selectedDifficulty == null
                    ? recipes
                    : recipes
                        .where((r) => r.difficulty == _selectedDifficulty)
                        .toList();
                if (filtered.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(context),
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          RecipeCard(recipe: filtered[index]),
                    ),
                  ),
                ];
              },
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(context, error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建可折叠的顶部区域
  Widget _buildCollapsibleHeader(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return SliverAppBar(
      expandedHeight: 200,
      toolbarHeight: 72,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final maxExtent = 200.0 + statusBarHeight;
          final minExtent = 72.0 + statusBarHeight;
          final t = ((constraints.maxHeight - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12 * (1 - t), sigmaY: 12 * (1 - t)),
              child: Container(
                color: scaffoldBg.withValues(alpha: 0.7 + 0.3 * t),
                child: Padding(
                  padding: EdgeInsets.only(top: statusBarHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 128 * t,
                          child: ClipRect(
                            child: OverflowBox(
                              maxHeight: double.infinity,
                              alignment: Alignment.bottomLeft,
                              child: Opacity(
                                opacity: t,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting · 今日 ${now.month}月${now.day}日',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      '今天\n想做点什么？',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        height: 1.3,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildSearchRow(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建搜索栏行（搜索框 + 教程按钮）
  Widget _buildSearchRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => context.push('/search'),
              child: SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '搜索菜谱...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: SizedBox(
                          width: 20,
                          height: 20,
                          child: CustomPaint(
                            painter: _ScanIconPainter(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        tooltip: '扫一扫',
                        onPressed: () => context.push('/qr-scanner'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/tips'),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.menu_book_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'recipe') {
                context.push('/create-recipe');
              } else if (value == 'tip') {
                context.push('/tips/create');
              }
            },
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recipe',
                child: Row(
                  children: [
                    Icon(Icons.restaurant_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('新建菜谱'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tip',
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('新建教程'),
                  ],
                ),
              ),
            ],
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.add,
                color: AppColors.surface,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 根据时间获取问候语
  String _getGreeting(int hour) {
    if (hour < 6) return '深夜好';
    if (hour < 11) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  /// 构建分类筛选栏
  Widget _buildCategoryFilter() {
    final manifestAsync = ref.watch(manifestProvider);

    return manifestAsync.when(
      data: (manifest) {
        // 构建分类列表：全部 + 各分类
        final categories = <MapEntry<String?, String>>[
          const MapEntry(null, '全部'),
          ...manifest.categories.entries.map(
            (e) => MapEntry(e.key, e.value.name),
          ),
        ];

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = categories[index];
              final categoryId = entry.key;
              final categoryName = entry.value;
              final isSelected = _selectedCategory == categoryId;

              return FilterChip(
                label: Text(
                  categoryName,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = categoryId;
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                showCheckmark: false, // 不显示勾选标记
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text('难度', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          // 小巧的下拉菜单
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedDifficulty,
                isDense: true,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('全部')),
                  ...List.generate(5, (index) {
                    final difficulty = index + 1;
                    return DropdownMenuItem<int?>(
                      value: difficulty,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          difficulty,
                          (i) => const Icon(
                            Icons.star,
                            color: AppColors.butter,
                            size: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // 重新加载
                if (_selectedCategory == null) {
                  ref.invalidate(allRecipesProvider);
                } else {
                  ref.invalidate(recipesByCategoryProvider(_selectedCategory!));
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空列表状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text('暂无菜谱', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('点击右下角按钮创建第一个菜谱', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// 根据屏幕宽度计算列数
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 4; // 超大屏
    } else if (width > 800) {
      return 3; // 大屏
    } else if (width > 600) {
      return 2; // 中屏
    } else {
      return 2; // 小屏
    }
  }
}

class _ScanIconPainter extends CustomPainter {
  final Color color;

  _ScanIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final corner = w * 0.3;

    // 四个角
    // 左上
    canvas.drawLine(Offset(0, corner), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(corner, 0), paint);
    // 右上
    canvas.drawLine(Offset(w - corner, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, corner), paint);
    // 左下
    canvas.drawLine(Offset(0, h - corner), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(corner, h), paint);
    // 右下
    canvas.drawLine(Offset(w, h - corner), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w - corner, h), paint);

    // 中间扫描线
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.15, h / 2),
      Offset(w * 0.85, h / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanIconPainter old) => old.color != color;
}
