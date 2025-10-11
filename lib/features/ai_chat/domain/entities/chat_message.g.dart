// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      content: json['content'] as String,
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      localImagePaths: (json['localImagePaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      recipeCards: (json['recipeCards'] as List<dynamic>?)
          ?.map((e) => RecipeCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
          MessageStatus.sent,
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'imageUrls': instance.imageUrls,
      'localImagePaths': instance.localImagePaths,
      'recipeCards': instance.recipeCards,
      'status': _$MessageStatusEnumMap[instance.status]!,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.error: 'error',
};

_$RecipeCardImpl _$$RecipeCardImplFromJson(Map<String, dynamic> json) =>
    _$RecipeCardImpl(
      recipeId: json['recipeId'] as String,
      recipeName: json['recipeName'] as String,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$$RecipeCardImplToJson(_$RecipeCardImpl instance) =>
    <String, dynamic>{
      'recipeId': instance.recipeId,
      'recipeName': instance.recipeName,
      'imageUrl': instance.imageUrl,
      'category': instance.category,
    };
