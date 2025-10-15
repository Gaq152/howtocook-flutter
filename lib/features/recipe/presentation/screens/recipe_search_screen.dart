import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/recipe_providers.dart';
import '../../domain/entities/recipe.dart';
import '../../infrastructure/services/search_history_service.dart';
import '../widgets/recipe_card.dart';
import '../../../../core/theme/app_colors.dart';

/// 搜索关键词状态 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 搜索历史服务 Provider
final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  return SearchHistoryService();
});

/// 搜索历史 Provider
final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(searchHistoryServiceProvider);
  return service.getSearchHistory();
});

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

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // 添加到搜索历史
    final service = ref.read(searchHistoryServiceProvider);
    await service.addSearchRecord(query.trim());

    // 更新搜索状态
    ref.read(searchQueryProvider.notifier).state = query.trim();

    // 刷新搜索历史
    ref.invalidate(searchHistoryProvider);
  }

  /// 删除搜索记录
  Future<void> _deleteSearchRecord(String query) async {
    final service = ref.read(searchHistoryServiceProvider);
    await service.deleteSearchRecord(query);

    // 刷新搜索历史
    ref.invalidate(searchHistoryProvider);
  }

  /// 清空搜索历史
  Future<void> _clearSearchHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '清空搜索历史',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          '确定要清空所有搜索记录吗？',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(searchHistoryServiceProvider);
      await service.clearSearchHistory();

      // 刷新搜索历史
      ref.invalidate(searchHistoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清空搜索历史')),
        );
      }
    }
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
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                      _searchFocusNode.requestFocus();
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 16),
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {}); // 仅用于刷新UI，显示/隐藏清空按钮
          },
          onSubmitted: (value) {
            // 提交搜索
            _performSearch(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('搜索'),
            ),
        ],
      ),
      body: searchQuery.trim().isEmpty
          ? _buildSearchHistoryState(context)
          : _buildSearchResults(searchQuery.trim()),
    );
  }

  /// 构建搜索历史状态
  Widget _buildSearchHistoryState(BuildContext context) {
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildSearchHistory(history);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyState(context),
    );
  }

  /// 构建空状态（无搜索历史）
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

  /// 构建搜索历史列表
  Widget _buildSearchHistory(List<String> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                '搜索历史',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearSearchHistory,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('清空'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
        // 搜索历史列表
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final query = history[index];
              return ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _deleteSearchRecord(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            },
          ),
        ),
      ],
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
