import 'package:hive_flutter/hive_flutter.dart';
import '../../features/ai_chat/domain/entities/ai_model_config.dart';
import '../../features/ai_chat/infrastructure/adapters/api_call_record_adapter.dart';

/// Hive 存储服务
/// 负责初始化所有 Hive Boxes 和注册 TypeAdapters
class HiveService {
  // Box 名称常量
  static const String aiModelsBox = 'ai_models';
  static const String apiCallRecordsBox = 'api_call_records';
  static const String favoritesBox = 'favorites';
  static const String userNotesBox = 'user_notes';
  static const String settingsBox = 'settings';
  static const String chatHistoryBox = 'chat_history';
  static const String modifiedRecipesBox = 'modified_recipes'; // 存储修改后的菜谱JSON

  /// 初始化 Hive
  /// 必须在应用启动时调用（main.dart 中）
  static Future<void> init() async {
    // 初始化 Hive Flutter
    await Hive.initFlutter();

    // 注册 TypeAdapters
    _registerAdapters();

    // 打开所有 Boxes
    await _openBoxes();
  }

  /// 注册所有 TypeAdapters
  static void _registerAdapters() {
    // 注册 APICallRecord 适配器（TypeId: 2）
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(APICallRecordAdapter());
    }

    // 未来可在此添加其他自定义类型的适配器
  }

  /// 打开所有 Boxes
  static Future<void> _openBoxes() async {
    // AI 模型配置 Box（存储 JSON Map）
    if (!Hive.isBoxOpen(aiModelsBox)) {
      await Hive.openBox<Map>(aiModelsBox);
    }

    // API 调用记录 Box（存储 APICallRecord 对象）
    if (!Hive.isBoxOpen(apiCallRecordsBox)) {
      await Hive.openBox<APICallRecord>(apiCallRecordsBox);
    }

    // 收藏菜谱 Box（存储菜谱 ID 列表）
    if (!Hive.isBoxOpen(favoritesBox)) {
      await Hive.openBox<String>(favoritesBox);
    }

    // 用户笔记 Box（存储字符串: recipeId -> note）
    if (!Hive.isBoxOpen(userNotesBox)) {
      await Hive.openBox<String>(userNotesBox);
    }

    // 应用设置 Box（存储键值对配置）
    if (!Hive.isBoxOpen(settingsBox)) {
      await Hive.openBox(settingsBox);
    }

    // 聊天历史 Box（存储聊天消息 JSON）
    if (!Hive.isBoxOpen(chatHistoryBox)) {
      await Hive.openBox<Map>(chatHistoryBox);
    }

    // 修改后的菜谱 Box（存储 JSON Map）
    if (!Hive.isBoxOpen(modifiedRecipesBox)) {
      await Hive.openBox<Map>(modifiedRecipesBox);
    }
  }

  /// 获取 AI 模型配置 Box
  static Box<Map> getAIModelsBox() => Hive.box<Map>(aiModelsBox);

  /// 获取 API 调用记录 Box
  static Box<APICallRecord> getAPICallRecordsBox() =>
      Hive.box<APICallRecord>(apiCallRecordsBox);

  /// 获取收藏 Box
  static Box<String> getFavoritesBox() => Hive.box<String>(favoritesBox);

  /// 获取用户笔记 Box
  ///
  /// 存储格式: recipeId (String) → note (String)
  static Box<String> getUserNotesBox() => Hive.box<String>(userNotesBox);

  /// 获取设置 Box
  static Box getSettingsBox() => Hive.box(settingsBox);

  /// 获取聊天历史 Box
  static Box<Map> getChatHistoryBox() => Hive.box<Map>(chatHistoryBox);

  /// 获取修改后的菜谱 Box
  ///
  /// 存储格式: recipeId (String) → recipeJson (Map)
  static Box<Map> getModifiedRecipesBox() => Hive.box<Map>(modifiedRecipesBox);

  /// 关闭所有 Boxes（用于测试或应用退出）
  static Future<void> closeAll() async {
    await Hive.close();
  }

  /// 清空所有数据（仅用于测试或重置应用）
  static Future<void> clearAll() async {
    await getAIModelsBox().clear();
    await getAPICallRecordsBox().clear();
    await getFavoritesBox().clear();
    await getUserNotesBox().clear();
    await getSettingsBox().clear();
    await getChatHistoryBox().clear();
    await getModifiedRecipesBox().clear();
  }

  /// 删除所有 Boxes（彻底清除数据）
  static Future<void> deleteAll() async {
    await Hive.deleteBoxFromDisk(aiModelsBox);
    await Hive.deleteBoxFromDisk(apiCallRecordsBox);
    await Hive.deleteBoxFromDisk(favoritesBox);
    await Hive.deleteBoxFromDisk(userNotesBox);
    await Hive.deleteBoxFromDisk(settingsBox);
    await Hive.deleteBoxFromDisk(chatHistoryBox);
    await Hive.deleteBoxFromDisk(modifiedRecipesBox);
  }
}
