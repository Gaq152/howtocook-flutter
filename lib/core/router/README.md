# 路由系统说明

## 路由结构

### 主路由（包含底部导航）
使用 `ShellRoute` 包裹，共享 `MainScaffold` 框架：

- `/recipes` - 菜谱首页
- `/ai-chat` - AI 聊天页面
- `/user` - 用户页面

### 全屏路由（无底部导航）
- `/recipe/:id` - 菜谱详情
- `/search` - 搜索页面
- `/create-recipe` - 创建菜谱
- `/favorites` - 收藏列表
- `/my-recipes` - 我的菜谱
- `/model-management` - 模型管理
- `/settings` - 设置

## 底部导航设计

### 布局
```
┌────────────────────────────────┐
│  菜谱     [AI 聊天 FAB]    我的  │
└────────────────────────────────┘
```

### AI 聊天 FAB 特性
- 64x64 圆形按钮
- 渐变色：#FF6B35 → #FF8C61
- 阴影：16px 模糊，8px 垂直偏移
- 选中时显示 `smart_toy` 图标
- 未选中时显示 `chat` 图标

## 使用示例

### 导航到特定页面
```dart
// 导航到菜谱首页
context.go('/recipes');

// 导航到 AI 聊天
context.go('/ai-chat');

// 导航到菜谱详情
context.go('/recipe/recipe-001');

// 返回上一页
context.pop();
```

### 在 ConsumerWidget 中使用
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用路由导航
    ElevatedButton(
      onPressed: () => context.go('/ai-chat'),
      child: Text('打开 AI 聊天'),
    );
  }
}
```

## 路由状态管理

当前路由索引通过 `GoRouterState.of(context).uri.path` 自动计算，无需手动管理状态。

## 页面切换动画

主导航页面使用 `NoTransitionPage` 实现无动画切换，提升用户体验。
