// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$availableModelsHash() => r'58e8941cd2e8fd7d6c4e5c817b3e49be97cc8383';

/// 所有可用的模型配置列表 Provider
///
/// 包含内置模型和用户自定义模型
/// - 内置模型：来自 AIServiceFactory.getBuiltinModels()，不可删除
/// - 用户模型：存储在 Hive aiModelsBox 中，可增删改
///
/// Copied from [AvailableModels].
@ProviderFor(AvailableModels)
final availableModelsProvider =
    AsyncNotifierProvider<AvailableModels, List<AIModelConfig>>.internal(
  AvailableModels.new,
  name: r'availableModelsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableModelsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AvailableModels = AsyncNotifier<List<AIModelConfig>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
