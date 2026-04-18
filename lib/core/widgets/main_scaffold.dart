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

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: '菜谱',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '我的',
        ),
      ],
    );
  }
}
