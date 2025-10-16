import 'package:freezed_annotation/freezed_annotation.dart';

part 'tip.freezed.dart';
part 'tip.g.dart';

/// 教程/技巧实体
@freezed
class Tip with _$Tip {
  const factory Tip({
    required String id, // 教程 ID，例如 tips_learn_xxx
    required String title, // 标题
    required String category, // 分类 ID，例如 learn
    @JsonKey(name: 'categoryName') required String categoryName, // 分类名称
    @Default('') String content, // 正文内容
    @Default(<TipSection>[]) List<TipSection> sections, // 分节内容
    required String hash, // 文件哈希，用于同步增量
    // 扩展字段
    @Default(false) bool isFavorite, // 是否收藏
    DateTime? createdAt, // 创建时间
    DateTime? updatedAt, // 更新时间
  }) = _Tip;

  factory Tip.fromJson(Map<String, dynamic> json) => _$TipFromJson(json);
}

/// 教程段落
@freezed
class TipSection with _$TipSection {
  const factory TipSection({
    required String title, // 段落标题
    required String content, // 段落内容
  }) = _TipSection;

  factory TipSection.fromJson(Map<String, dynamic> json) =>
      _$TipSectionFromJson(json);
}
