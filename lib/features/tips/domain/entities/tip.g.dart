// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TipImpl _$$TipImplFromJson(Map<String, dynamic> json) => _$TipImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      categoryName: json['categoryName'] as String,
      content: json['content'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => TipSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TipSection>[],
      hash: json['hash'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      source: $enumDecodeNullable(_$TipSourceEnumMap, json['source']) ??
          TipSource.bundled,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TipImplToJson(_$TipImpl instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'categoryName': instance.categoryName,
      'content': instance.content,
      'sections': instance.sections,
      'hash': instance.hash,
      'isFavorite': instance.isFavorite,
      'source': _$TipSourceEnumMap[instance.source]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$TipSourceEnumMap = {
  TipSource.bundled: 'bundled',
  TipSource.userCreated: 'userCreated',
  TipSource.userModified: 'userModified',
  TipSource.scanned: 'scanned',
};

_$TipSectionImpl _$$TipSectionImplFromJson(Map<String, dynamic> json) =>
    _$TipSectionImpl(
      title: json['title'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$$TipSectionImplToJson(_$TipSectionImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
    };
