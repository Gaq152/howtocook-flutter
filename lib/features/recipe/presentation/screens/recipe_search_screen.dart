import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/recipe_providers.dart';
import '../../domain/entities/recipe.dart';
import '../widgets/recipe_card.dart';
import '../../../../core/theme/app_colors.dart';

/// 搜索关键词状态 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 菜谱搜索页面
///
/// 提供搜索输入框和结果列表
class RecipeSearchScreen extends ConsumerStatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  ConsumerState<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends ConsumerState<RecipeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: '搜索菜谱、食材...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          style: const TextStyle(fontSize: 16),
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
          onSubmitted: (value) {
            // 提交搜索
            if (value.trim().isNotEmpty) {
              ref.read(searchQueryProvider.notifier).state = value.trim();
            }
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
                _searchFocusNode.requestFocus();
              },
            ),
        ],
      ),
      body: searchQuery.trim().isEmpty
          ? _buildEmptyState(context)
          : _buildSearchResults(searchQuery.trim()),
    );
  }

  /// 构建空状态（未输入搜索词）
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '搜索菜谱',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入菜谱名称、分类或食材',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults(String query) {
    final searchResultsAsync = ref.watch(searchRecipesProvider(query));

    return searchResultsAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return _buildNoResults(context, query);
        }
        return _buildResultsList(recipes, query);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  /// 构建结果列表
  Widget _buildResultsList(List<Recipe> recipes, String query) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 结果计数
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '找到 ${recipes.length} 个结果',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        // 结果网格
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              childAspectRatio: 0.58,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return RecipeCard(recipe: recipes[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 构建无结果状态
  Widget _buildNoResults(BuildContext context, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到相关菜谱',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '搜索关键词: "$query"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
                _searchFocusNode.requestFocus();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('清空搜索'),
            ),
          ],
        ),
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
          Text('正在搜索...'),
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
            Text(
              '搜索失败',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // 重新搜索
                final query = ref.read(searchQueryProvider);
                if (query.trim().isNotEmpty) {
                  ref.invalidate(searchRecipesProvider(query.trim()));
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
