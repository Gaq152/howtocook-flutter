import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/recipe/presentation/screens/recipe_home_screen.dart';
import '../../features/recipe/presentation/screens/recipe_detail_screen.dart';
import '../../features/recipe/presentation/screens/recipe_search_screen.dart';
import '../../features/recipe/presentation/screens/recipe_edit_screen.dart';
import '../../features/recipe/presentation/screens/recipe_create_screen.dart';
import '../../features/recipe/presentation/screens/favorite_recipes_screen.dart';
import '../../features/recipe/presentation/screens/tips_screen.dart';
import '../../features/recipe/presentation/screens/qr_scanner_screen.dart';
import '../../features/recipe/presentation/screens/recipe_preview_screen.dart';
import '../../features/recipe/domain/entities/recipe.dart';
import '../../features/ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../features/user/presentation/screens/user_screen.dart';
import '../widgets/main_scaffold.dart';

/// 路由配置 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/recipes',
    routes: [
      // Shell 路由：包含底部导航的主框架
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          // 菜谱首页
          GoRoute(
            path: '/recipes',
            name: 'recipes',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const RecipeHomeScreen(),
            ),
          ),

          // AI 聊天页面
          GoRoute(
            path: '/ai-chat',
            name: 'ai-chat',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AIChatScreen(),
            ),
          ),

          // 用户页面
          GoRoute(
            path: '/user',
            name: 'user',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const UserScreen(),
            ),
          ),
        ],
      ),

      // 菜谱详情（全屏页面，不显示底部导航）
      GoRoute(
        path: '/recipe/:id',
        name: 'recipe-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RecipeDetailScreen(recipeId: id);
        },
      ),

      // 菜谱编辑
      GoRoute(
        path: '/recipe/:id/edit',
        name: 'recipe-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RecipeEditScreen(recipeId: id);
        },
      ),

      // 搜索页面
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          return const RecipeSearchScreen();
        },
      ),

      // 创建菜谱
      GoRoute(
        path: '/create-recipe',
        name: 'create-recipe',
        builder: (context, state) {
          return const RecipeCreateScreen();
        },
      ),

      // 收藏列表
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) {
          return const FavoriteRecipesScreen();
        },
      ),

      // 我的菜谱
      GoRoute(
        path: '/my-recipes',
        name: 'my-recipes',
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('我的菜谱')),
            body: const Center(
              child: Text('我的菜谱\n\n（待实现）'),
            ),
          );
        },
      ),

      // 模型管理
      GoRoute(
        path: '/model-management',
        name: 'model-management',
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('模型管理')),
            body: const Center(
              child: Text('模型管理\n\n（待实现）'),
            ),
          );
        },
      ),

      // 设置
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('设置')),
            body: const Center(
              child: Text('设置\n\n（待实现）'),
            ),
          );
        },
      ),

      // 教程提示页面
      // 格式: /tips/:category/:tipsId
      // 例如: /tips/learn/tips_learn_50ddd8bd
      GoRoute(
        path: '/tips/:category/:tipsId',
        name: 'tips',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? '';
          final tipsId = state.pathParameters['tipsId'] ?? '';
          return TipsScreen(
            category: category,
            tipsId: tipsId,
          );
        },
      ),

      // 二维码扫描
      GoRoute(
        path: '/qr-scanner',
        name: 'qr-scanner',
        builder: (context, state) {
          return const QRScannerScreen();
        },
      ),

      // 食谱预览（扫码导入）
      GoRoute(
        path: '/recipe/preview',
        name: 'recipe-preview',
        builder: (context, state) {
          final recipe = state.extra as Recipe;
          return RecipePreviewScreen(recipe: recipe);
        },
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '404',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('页面不存在'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/recipes'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});
