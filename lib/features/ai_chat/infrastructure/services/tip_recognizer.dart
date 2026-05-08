import '../../../sync/domain/entities/manifest.dart';
import '../../../sync/infrastructure/bundled_data_loader.dart';

/// 教程卡片数据
class TipCardData {
  final String id;
  final String title;
  final String category;
  final String categoryName;

  TipCardData({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryName,
  });

  factory TipCardData.fromIndex(TipIndex index) {
    return TipCardData(
      id: index.id,
      title: index.title,
      category: index.category,
      categoryName: index.categoryName,
    );
  }
}

/// 教程识别服务
///
/// 从 AI 回复文本中识别教程标题，并与本地教程索引比对
class TipRecognizer {
  final BundledDataLoader _dataLoader;
  Manifest? _cachedManifest;

  TipRecognizer(this._dataLoader);

  Future<List<TipCardData>> extractTipsFromText(String text) async {
    _cachedManifest ??= await _dataLoader.loadManifest();

    final matched = <TipCardData>[];
    for (final tipIndex in _cachedManifest!.tips) {
      if (text.contains(tipIndex.title)) {
        matched.add(TipCardData.fromIndex(tipIndex));
      }
    }
    return matched;
  }

  void clearCache() {
    _cachedManifest = null;
  }
}
