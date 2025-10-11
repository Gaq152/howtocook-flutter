import '../entities/recipe.dart';

/// 菜谱仓储接口
///
/// 定义所有菜谱数据访问操作的契约
abstract class RecipeRepository {
  /// 获取所有菜谱
  ///
  /// 合并内置菜谱和用户创建/修改的菜谱
  /// 本地数据优先（可覆盖同 ID 的内置菜谱）
  Future<List<Recipe>> getAllRecipes();

  /// 根据 ID 获取单个菜谱
  ///
  /// 优先查询本地数据库，若无则从内置数据加载
  Future<Recipe?> getRecipeById(String id);

  /// 根据分类获取菜谱
  ///
  /// category: 分类 ID（如 "meat_dish"、"aquatic"）
  Future<List<Recipe>> getRecipesByCategory(String category);

  /// 搜索菜谱
  ///
  /// 根据菜谱名称、食材、分类名称进行模糊搜索
  Future<List<Recipe>> searchRecipes(String query);

  /// 获取收藏的菜谱
  ///
  /// 从 Hive 读取收藏 ID 列表，然后获取对应菜谱
  Future<List<Recipe>> getFavoriteRecipes();

  /// 保存菜谱
  ///
  /// 新增或更新菜谱到本地数据库
  /// 用于用户创建的菜谱或修改内置菜谱
  Future<void> saveRecipe(Recipe recipe);

  /// 删除菜谱
  ///
  /// 仅删除本地数据库中的菜谱（内置菜谱无法删除）
  Future<void> deleteRecipe(String id);

  /// 切换收藏状态
  ///
  /// 如果已收藏则取消，否则添加收藏
  Future<void> toggleFavorite(String id);

  /// 检查是否已收藏
  ///
  /// 从 Hive favorites box 检查
  Future<bool> isFavorite(String id);

  /// 更新用户笔记
  ///
  /// 为指定菜谱添加或更新用户笔记（传null或空字符串表示删除笔记）
  Future<void> updateUserNote(String id, String? note);

  /// 获取用户笔记
  ///
  /// 从 Hive user_notes box 获取
  Future<String?> getUserNote(String id);

  /// 获取收藏 ID 列表
  ///
  /// 返回所有已收藏的菜谱 ID
  Future<List<String>> getFavoriteIds();

  /// 批量保存菜谱
  ///
  /// 用于首次从内置数据导入到数据库（可选功能）
  Future<void> saveRecipes(List<Recipe> recipes);
}
