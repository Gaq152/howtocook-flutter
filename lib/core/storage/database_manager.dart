import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Sqflite 数据库管理器
/// 负责菜谱数据的持久化存储
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  static Database? _database;

  factory DatabaseManager() => _instance;

  DatabaseManager._internal();

  /// 数据库版本
  static const int _databaseVersion = 1;

  /// 数据库名称
  static const String _databaseName = 'howtocook.db';

  /// 表名
  static const String recipesTable = 'recipes';

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表（首次安装）
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $recipesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        source_path TEXT,
        image_path TEXT,
        images TEXT,                    -- JSON 数组字符串
        category TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        tags TEXT,                      -- JSON 数组字符串
        servings INTEGER,
        ingredients TEXT NOT NULL,      -- JSON 数组字符串
        steps TEXT NOT NULL,            -- JSON 数组字符串
        prep_time_minutes INTEGER,
        cook_time_minutes INTEGER,
        total_time_minutes INTEGER,
        additional_notes TEXT,          -- JSON 数组字符串
        is_favorite INTEGER DEFAULT 0,
        user_note TEXT,
        source TEXT NOT NULL,           -- bundled/cloud/userCreated/userModified
        created_at INTEGER,
        updated_at INTEGER,

        -- 索引字段（用于快速查询）
        UNIQUE(id)
      )
    ''');

    // 创建索引以提升查询性能
    await db.execute(
      'CREATE INDEX idx_category ON $recipesTable(category)',
    );

    await db.execute(
      'CREATE INDEX idx_difficulty ON $recipesTable(difficulty)',
    );

    await db.execute(
      'CREATE INDEX idx_favorite ON $recipesTable(is_favorite)',
    );

    await db.execute(
      'CREATE INDEX idx_source ON $recipesTable(source)',
    );
  }

  /// 数据库升级（版本变更时）
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时在此处理 schema 变更
    // 例如：
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $recipesTable ADD COLUMN new_field TEXT');
    // }
  }

  /// 插入菜谱
  Future<int> insertRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    return await db.insert(
      recipesTable,
      recipe,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入菜谱（事务）
  Future<void> insertRecipes(List<Map<String, dynamic>> recipes) async {
    final db = await database;
    final batch = db.batch();

    for (final recipe in recipes) {
      batch.insert(
        recipesTable,
        recipe,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// 根据 ID 查询菜谱
  Future<Map<String, dynamic>?> getRecipeById(String id) async {
    final db = await database;
    final results = await db.query(
      recipesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// 查询所有菜谱
  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    final db = await database;
    return await db.query(recipesTable);
  }

  /// 根据分类查询菜谱
  Future<List<Map<String, dynamic>>> getRecipesByCategory(
    String category,
  ) async {
    final db = await database;
    return await db.query(
      recipesTable,
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  /// 查询收藏菜谱
  Future<List<Map<String, dynamic>>> getFavoriteRecipes() async {
    final db = await database;
    return await db.query(
      recipesTable,
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
  }

  /// 搜索菜谱（按名称）
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    final db = await database;
    return await db.query(
      recipesTable,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  /// 更新菜谱
  Future<int> updateRecipe(String id, Map<String, dynamic> recipe) async {
    final db = await database;
    return await db.update(
      recipesTable,
      recipe,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除菜谱
  Future<int> deleteRecipe(String id) async {
    final db = await database;
    return await db.delete(
      recipesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有菜谱（仅用于测试）
  Future<int> clearAllRecipes() async {
    final db = await database;
    return await db.delete(recipesTable);
  }

  /// 获取菜谱总数
  Future<int> getRecipeCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $recipesTable',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取所有分类
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT DISTINCT category FROM $recipesTable ORDER BY category',
    );
    return results.map((row) => row['category'] as String).toList();
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
