import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// 聊天消息实体
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required MessageRole role,
    required DateTime timestamp,
    List<String>? imageUrls,                     // 图片 URL 列表
    List<String>? localImagePaths,               // 本地图片路径（用于历史记录）
    List<RecipeCard>? recipeCards,               // 菜谱卡片
    @Default(MessageStatus.sent) MessageStatus status,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

/// 消息角色
enum MessageRole {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('system')
  system,
}

/// 消息状态
enum MessageStatus {
  sending,   // 发送中
  sent,      // 已发送
  error,     // 发送失败
}

/// 菜谱卡片实体（嵌入在聊天消息中）
@freezed
class RecipeCard with _$RecipeCard {
  const factory RecipeCard({
    required String recipeId,
    required String recipeName,
    String? imageUrl,
    String? category,
  }) = _RecipeCard;

  factory RecipeCard.fromJson(Map<String, dynamic> json) => _$RecipeCardFromJson(json);
}
