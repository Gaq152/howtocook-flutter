import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主框架页面
/// 包含底部导航栏和突出的 AI 聊天按钮
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // 根据当前路由路径确定选中的导航索引
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/recipes')) {
      return 0;
    } else if (location.startsWith('/ai-chat')) {
      return 1;
    } else if (location.startsWith('/user')) {
      return 2;
    }

    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/recipes');
        break;
      case 1:
        context.go('/ai-chat');
        break;
      case 2:
        context.go('/user');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _currentIndex = _calculateSelectedIndex(context);

    // 检测键盘是否弹出
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigationBar(),
      // 键盘弹出时隐藏FAB，防止遮挡输入框
      floatingActionButton: keyboardVisible ? null : _buildAIChatFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 左侧：菜谱
            Expanded(
              child: _buildNavItem(
                icon: Icons.restaurant_menu,
                label: '菜谱',
                index: 0,
              ),
            ),

            // 中间：占位（为 FAB 留空间）
            const Spacer(),

            // 右侧：我的
            Expanded(
              child: _buildNavItem(
                icon: Icons.person,
                label: '我的',
                index: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导航项
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Theme.of(context).primaryColor
        : Colors.grey[600];

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 AI 聊天 FAB（突出显示）
  Widget _buildAIChatFAB() {
    final isSelected = _currentIndex == 1;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [const Color(0xFFFF6B35), const Color(0xFFFF8C61)]
              : [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isSelected ? const Color(0xFFFF6B35) : Colors.grey[400]!)
                .withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(1),
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.smart_toy : Icons.chat,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 2),
              Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
