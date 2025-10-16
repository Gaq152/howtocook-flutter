import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/providers/recipe_providers.dart';
import '../../domain/entities/recipe.dart';
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

  /// 滚动到顶部
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据选中的分类获取菜谱列表
    final recipesAsync = _selectedCategory == null
        ? ref.watch(allRecipesProvider)
        : ref.watch(recipesByCategoryProvider(_selectedCategory!));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onDoubleTap: _scrollToTop,
          child: Text(
            '菜谱',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: '教程中心',
            onPressed: () {
              context.push('/tips');
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: '扫一扫',
            onPressed: () {
              context.push('/qr-scanner');
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () {
              context.push('/search');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          _buildFilterBar(),
          Expanded(
            child: recipesAsync.when(
              data: (recipes) {
                final filteredRecipes = _selectedDifficulty == null
                    ? recipes
                    : recipes
                        .where((r) => r.difficulty == _selectedDifficulty)
                        .toList();
                return _buildRecipeList(context, filteredRecipes);
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-recipe'),
        child: const Icon(Icons.add),
      ),
    );
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
                color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text('难度', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(width: 12),
          // 小巧的下拉菜单
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedDifficulty,
                isDense: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
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
                            color: Colors.orange,
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

  /// 构建菜谱列表
  Widget _buildRecipeList(BuildContext context, List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // 刷新菜谱列表
        ref.invalidate(allRecipesProvider);
        // 等待数据重新加载
        await ref.read(allRecipesProvider.future);
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 0.75, // 调整为0.75，卡片更短更紧凑
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return RecipeCard(recipe: recipes[index]);
        },
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载菜谱...'),
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
