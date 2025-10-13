# MCP 服务说明

## MCPService

封装与腾讯云 MCP (Model Context Protocol) 服务的交互。

### 配置

在 `.env` 文件中配置：
```
MCP_BASE_URL=https://1324174178-52eq86zzdl.in.ap-guangzhou.tencentscf.com
```

### 响应格式

MCP 服务返回格式：
```json
{
  "params": {...},
  "response": {
    "content": [
      {
        "type": "text",
        "text": "{...JSON...}"
      }
    ]
  }
}
```

需要进行二次 JSON 解码才能获取实际数据。

### 提供的工具函数

1. **searchRecipes(query)** - 搜索菜谱
   - 参数：`query` (String) - 搜索关键词
   - 返回：`List<Recipe>` - 菜谱列表

2. **getRecipeDetail(recipeId)** - 获取菜谱详情
   - 参数：`recipeId` (String) - 菜谱 ID
   - 返回：`Recipe` - 菜谱详情

3. **getRandomRecipes(count)** - 获取随机菜谱
   - 参数：`count` (int) - 数量（默认 5）
   - 返回：`List<Recipe>` - 随机菜谱列表

4. **getRecipesByCategory(category)** - 按分类获取菜谱
   - 参数：`category` (String) - 分类名称
   - 返回：`List<Recipe>` - 该分类的菜谱列表

5. **getFavoriteRecipes(favoriteIds)** - 获取收藏的菜谱
   - 参数：`favoriteIds` (List<String>) - 收藏的菜谱 ID 列表
   - 返回：`List<Recipe>` - 收藏的菜谱列表

### 使用示例

```dart
// 通过 Provider 使用
final mcpService = ref.watch(mcpServiceProvider);

// 搜索菜谱
final recipes = await mcpService.searchRecipes('红烧肉');

// 获取菜谱详情
final recipe = await mcpService.getRecipeDetail('meat_dish_bc5b39f0');

// 获取随机菜谱
final randomRecipes = await mcpService.getRandomRecipes(count: 10);

// 按分类获取菜谱
final meatDishes = await mcpService.getRecipesByCategory('meat_dish');

// 获取收藏的菜谱
final favorites = await mcpService.getFavoriteRecipes(['id1', 'id2']);
```

### 错误处理

所有方法都会在失败时抛出异常，建议使用 try-catch 处理：

```dart
try {
  final recipes = await mcpService.searchRecipes(query);
} catch (e) {
  print('搜索失败: $e');
}
```
