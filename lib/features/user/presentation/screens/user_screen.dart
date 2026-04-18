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
            icon: Icons.settings,
            title: '设置',
            subtitle: '模型管理、数据同步、检查更新与关于',
            onTap: () {
              context.push('/settings');
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
}
