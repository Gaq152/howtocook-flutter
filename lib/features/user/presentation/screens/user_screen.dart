import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../recipe/application/providers/recipe_providers.dart';
import '../../../recipe/domain/entities/recipe.dart';

class UserScreen extends ConsumerWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIdsAsync = ref.watch(favoriteIdsProvider);
    final allRecipesAsync = ref.watch(allRecipesProvider);

    final favoriteCount = favoriteIdsAsync.valueOrNull?.length ?? 0;
    final allRecipes = allRecipesAsync.valueOrNull ?? [];
    final totalCount = allRecipes.length;
    final creationCount = allRecipes
        .where((r) =>
            r.source == RecipeSource.userCreated ||
            r.source == RecipeSource.userModified ||
            r.source == RecipeSource.aiGenerated ||
            r.source == RecipeSource.scanned)
        .length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildStatsRow(favoriteCount, totalCount, creationCount),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '偏好',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textDisabled,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(context, favoriteCount, creationCount),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              '小',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '小厨房',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                '美食爱好者',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/settings'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '设置',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int favoriteCount, int totalCount, int creationCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '$favoriteCount',
            '收藏',
            AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '$totalCount',
            '菜谱',
            AppColors.secondary.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '$creationCount',
            '自创',
            AppColors.butter.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, int favoriteCount, int creationCount) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.favorite_outline_rounded,
            iconColor: AppColors.primary,
            title: '我的收藏',
            badge: favoriteCount > 0 ? '$favoriteCount' : null,
            isFirst: true,
            onTap: () => context.push('/favorites'),
          ),
          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.divider),
          _buildMenuItem(
            context,
            icon: Icons.menu_book_outlined,
            iconColor: AppColors.secondary,
            title: '教程中心',
            onTap: () => context.push('/tips'),
          ),
          Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.divider),
          _buildMenuItem(
            context,
            icon: Icons.workspace_premium_outlined,
            iconColor: AppColors.butter,
            title: '我的创作',
            badge: creationCount > 0 ? '$creationCount' : null,
            isLast: true,
            onTap: () => context.push('/my-creations'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badge,
    bool isFirst = false,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.vertical(
      top: Radius.circular(isFirst ? 20 : 0),
      bottom: Radius.circular(isLast ? 20 : 0),
    );

    return Material(
      color: AppColors.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.textDisabled, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
