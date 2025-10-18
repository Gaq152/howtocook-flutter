import 'package:freezed_annotation/freezed_annotation.dart';

part 'tip.freezed.dart';
part 'tip.g.dart';

/// 教程来源
enum TipSource {
  bundled, // 内置
  userCreated, // 用户新建
  userModified, // 用户修改内置
  scanned, // 扫码导入
}

/// 教程/技巧实体
@freezed
class Tip with _$Tip {
  const factory Tip({
    required String id, // 教程 ID
    required String title, // 教程标题
    required String category, // 分类 ID
    required String categoryName, // 分类名称
    @Default('') String content, // 正文内容
    @Default(<TipSection>[]) List<TipSection> sections, // 分节内容
    required String hash, // 数据哈希
    @Default(false) bool isFavorite, // 是否收藏
    @Default(TipSource.bundled) TipSource source, // 数据来源
    DateTime? createdAt, // 创建时间
    DateTime? updatedAt, // 更新时间
  }) = _Tip;

  factory Tip.fromJson(Map<String, dynamic> json) => _$TipFromJson(json);
}

/// 教程分节
@freezed
class TipSection with _$TipSection {
  const factory TipSection({
    required String title, // 分节标题
    required String content, // 分节内容
  }) = _TipSection;

  factory TipSection.fromJson(Map<String, dynamic> json) =>
      _$TipSectionFromJson(json);
}
