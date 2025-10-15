import '../../../../core/storage/hive_service.dart';

/// 搜索历史服务
///
/// 管理用户的搜索历史记录
class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryCount = 20; // 最多保存20条搜索记录

  /// 获取搜索历史列表
  Future<List<String>> getSearchHistory() async {
    final box = HiveService.getSettingsBox();
    final history = box.get(_searchHistoryKey);

    if (history == null) {
      return [];
    }

    if (history is List) {
      return history.map((e) => e.toString()).toList();
    }

    return [];
  }

  /// 添加搜索记录
  Future<void> addSearchRecord(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    final history = await getSearchHistory();

    // 移除已存在的相同记录（去重）
    history.remove(query);

    // 添加到列表开头
    history.insert(0, query);

    // 限制最大数量
    if (history.length > _maxHistoryCount) {
      history.removeRange(_maxHistoryCount, history.length);
    }

    // 保存到存储
    final box = HiveService.getSettingsBox();
    await box.put(_searchHistoryKey, history);
  }

  /// 删除单个搜索记录
  Future<void> deleteSearchRecord(String query) async {
    final history = await getSearchHistory();
    history.remove(query);

    final box = HiveService.getSettingsBox();
    await box.put(_searchHistoryKey, history);
  }

  /// 清空所有搜索历史
  Future<void> clearSearchHistory() async {
    final box = HiveService.getSettingsBox();
    await box.delete(_searchHistoryKey);
  }
}
