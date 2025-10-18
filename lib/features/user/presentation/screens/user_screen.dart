import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 用户页面（占位页面）
class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // 用户头像区域
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 48, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text('美食爱好者', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),

          const Divider(height: 1),

          // 功能列表
          _buildMenuItem(
            context,
            icon: Icons.favorite,
            title: '我的收藏',
            onTap: () {
              context.push('/favorites');
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.workspace_premium_outlined,
            title: '我的自创',
            subtitle: '管理自创菜谱与教程',
            onTap: () {
              context.push('/my-creations');
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.menu_book_outlined,
            title: '教程中心',
            subtitle: '查看烹饪技巧与教程',
            onTap: () {
              context.push('/tips');
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.qr_code_scanner,
            title: '扫一扫',
            subtitle: '扫描二维码导入食谱',
            onTap: () {
              context.push('/qr-scanner');
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.model_training,
            title: '模型管理',
            onTap: () {
              context.push('/model-management');
            },
          ),

          const Divider(height: 1, thickness: 8),

          _buildMenuItem(
            context,
            icon: Icons.sync,
            title: '数据同步',
            subtitle: '同步菜谱数据和图片',
            onTap: () {
              context.push('/data-sync');
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: '设置',
            onTap: () {
              context.push('/settings');
            },
          ),

          const Divider(height: 1, thickness: 8),

          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: '关于',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '智能菜谱助手',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.restaurant_menu, size: 48),
      children: [
        const Text(
          '智能菜谱助手是一款基于 AI 的菜谱管理和烹饪助手应用。\n\n'
          '功能特性：\n'
          '• 菜谱浏览和搜索\n'
          '• AI 智能问答\n'
          '• 收藏和备注管理\n'
          '• 跨设备数据同步\n',
        ),
      ],
    );
  }
}
