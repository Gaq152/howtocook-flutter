# 主题和样式系统

## 文件结构

```
lib/core/theme/
├── app_colors.dart         # 颜色常量
├── app_text_styles.dart    # 文本样式
├── app_theme.dart          # 主题配置
├── theme_provider.dart     # 主题状态管理
└── README.md              # 文档说明
```

## 颜色方案

### 主色调
- **Primary**: `#FF6B35` (橙色) - 主色调，用于按钮、FAB、强调元素
- **Primary Light**: `#FF8C61` - 浅橙色，用于渐变效果
- **Primary Dark**: `#E55A2B` - 深橙色，用于悬停状态

### 辅助色
- **Secondary**: `#4ECDC4` (青色) - 辅助色，用于次要按钮
- **Success**: `#4CAF50` (绿色) - 成功状态
- **Warning**: `#FFC107` (黄色) - 警告状态
- **Error**: `#F44336` (红色) - 错误状态
- **Info**: `#2196F3` (蓝色) - 信息提示

### 难度颜色
- **简单**: `#4CAF50` (绿色)
- **中等**: `#FFC107` (黄色)
- **困难**: `#FF9800` (橙色)
- **极难**: `#F44336` (红色)

### 浅色模式
- **文本主色**: `#212121`
- **文本次色**: `#757575`
- **背景色**: `#FAFAFA`
- **表面色**: `#FFFFFF`
- **分割线**: `#E0E0E0`

### 深色模式
- **文本主色**: `#E0E0E0`
- **文本次色**: `#B0B0B0`
- **背景色**: `#121212`
- **表面色**: `#1E1E1E`
- **分割线**: `#424242`

## 文本样式

### 标题样式
- **h1**: 32px, Bold - 大标题
- **h2**: 28px, Bold - 次级标题
- **h3**: 24px, Bold - 三级标题
- **h4**: 20px, Semibold - 四级标题
- **h5**: 18px, Semibold - 五级标题
- **h6**: 16px, Semibold - 六级标题

### 正文样式
- **bodyLarge**: 16px - 大号正文
- **bodyMedium**: 14px - 中号正文
- **bodySmall**: 12px - 小号正文

### 特殊样式
- **recipeTitle**: 菜谱标题样式
- **ingredient**: 食材列表样式
- **cookingStep**: 烹饪步骤样式
- **aiMessage**: AI 消息样式
- **badge**: 标签/徽章样式

## 使用示例

### 使用颜色

```dart
import 'package:howtocook/core/theme/app_colors.dart';

// 使用主色调
Container(
  color: AppColors.primary,
  child: Text('主色调背景'),
);

// 根据难度获取颜色
final color = AppColors.getDifficultyColor(2); // 中等难度
final text = AppColors.getDifficultyText(2);   // "中等"
```

### 使用文本样式

```dart
import 'package:howtocook/core/theme/app_text_styles.dart';

Text(
  '标题文本',
  style: AppTextStyles.h3,
);

Text(
  '正文内容',
  style: AppTextStyles.bodyMedium,
);

// 自定义颜色
Text(
  '菜谱标题',
  style: AppTextStyles.recipeTitle.copyWith(
    color: AppColors.primary,
  ),
);
```

### 切换主题模式

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:howtocook/core/theme/theme_provider.dart';

class ThemeSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return DropdownButton<AppThemeMode>(
      value: themeMode,
      onChanged: (mode) {
        if (mode != null) {
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        }
      },
      items: [
        DropdownMenuItem(
          value: AppThemeMode.light,
          child: Text('浅色模式'),
        ),
        DropdownMenuItem(
          value: AppThemeMode.dark,
          child: Text('深色模式'),
        ),
        DropdownMenuItem(
          value: AppThemeMode.system,
          child: Text('跟随系统'),
        ),
      ],
    );
  }
}
```

### 快捷方法

```dart
// 设置浅色模式
ref.read(themeModeProvider.notifier).setLightMode();

// 设置深色模式
ref.read(themeModeProvider.notifier).setDarkMode();

// 设置跟随系统
ref.read(themeModeProvider.notifier).setSystemMode();
```

## Material 3 设计

本应用采用 **Material 3** 设计规范：
- ✅ 圆角卡片（12px border radius）
- ✅ 柔和阴影效果
- ✅ 动态颜色方案
- ✅ 统一的间距系统
- ✅ 无障碍支持

## 自定义组件样式

### 卡片
- 圆角：12px
- 阴影：elevation 2
- 边距：水平 16px，垂直 8px

### 按钮
- 圆角：8px
- 内边距：水平 24px，垂直 12px
- 文字样式：14px, Semibold, 字间距 0.5

### 输入框
- 圆角：8px
- 边框：1px (默认灰色，聚焦时主色调 2px)
- 内边距：水平 16px，垂直 12px

### 对话框
- 圆角：16px
- 阴影：elevation 8
- 标题样式：h5
- 内容样式：bodyMedium

## 响应式设计

主题系统支持所有屏幕尺寸：
- 📱 手机（< 600dp）
- 🖥️ 平板（600-1240dp）
- 💻 桌面（> 1240dp）

所有组件样式自动适配当前设备。

## 深色模式

深色模式完全支持，特性：
- ✅ 所有颜色经过优化，确保可读性
- ✅ 自动跟随系统主题
- ✅ 手动切换支持
- ✅ 状态持久化（未来版本）

## 无障碍支持

- ✅ 符合 WCAG 2.1 AA 级标准
- ✅ 对比度 ≥ 4.5:1（正文）
- ✅ 对比度 ≥ 3:1（大文本）
- ✅ 支持缩放（字体大小）
