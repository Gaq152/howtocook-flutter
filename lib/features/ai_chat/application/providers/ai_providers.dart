import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ai_model_config.dart';
import '../../domain/services/ai_service.dart';
import '../../infrastructure/services/ai_service_factory.dart';

/// 当前选中的模型配置 Provider
///
/// 默认使用 Claude 3.5 Sonnet（第一个内置模型）
final selectedModelConfigProvider = StateProvider<AIModelConfig>((ref) {
  final builtinModels = AIServiceFactory.getBuiltinModels();
  return builtinModels.firstWhere(
    (model) => model.isDefault,
    orElse: () => builtinModels.first,
  );
});

/// 所有可用的模型配置列表 Provider
///
/// 包含内置模型和用户自定义模型
final availableModelsProvider = StateProvider<List<AIModelConfig>>((ref) {
  // 初始化时只返回内置模型
  // TODO: 后续从 Hive 加载用户自定义模型
  return AIServiceFactory.getBuiltinModels();
});

/// AI Service Provider
///
/// 根据当前选中的模型配置创建 AI Service 实例
final aiServiceProvider = Provider<AIService>((ref) {
  final config = ref.watch(selectedModelConfigProvider);
  return AIServiceFactory.create(config);
});

/// 验证模型配置 Provider
///
/// 用于验证用户输入的 API Key 是否有效
final validateModelConfigProvider = FutureProvider.family<bool, AIModelConfig>(
  (ref, config) async {
    return AIServiceFactory.validateConfig(config);
  },
);

/// 模型能力 Provider
///
/// 获取当前模型的能力信息（是否支持图片、工具调用等）
final modelCapabilitiesProvider = Provider<ModelCapabilities>((ref) {
  final config = ref.watch(selectedModelConfigProvider);
  return config.capabilities;
});

/// 切换模型 Provider
///
/// 用于在 UI 中切换不同的模型
class ModelSwitcher extends StateNotifier<AIModelConfig> {
  ModelSwitcher(this.ref, AIModelConfig initialModel) : super(initialModel);

  final Ref ref;

  /// 切换到指定模型
  void switchTo(AIModelConfig model) {
    if (!model.isEnabled) {
      throw Exception('Model is disabled: ${model.displayName}');
    }
    state = model;
  }

  /// 切换到下一个可用模型
  void switchToNext() {
    final availableModels = ref.read(availableModelsProvider);
    final enabledModels = availableModels.where((m) => m.isEnabled).toList();

    if (enabledModels.isEmpty) {
      throw Exception('No enabled models available');
    }

    final currentIndex = enabledModels.indexWhere((m) => m.id == state.id);
    final nextIndex = (currentIndex + 1) % enabledModels.length;
    state = enabledModels[nextIndex];
  }
}

/// 模型切换器 Provider
final modelSwitcherProvider = StateNotifierProvider<ModelSwitcher, AIModelConfig>((ref) {
  final initialModel = ref.watch(selectedModelConfigProvider);
  return ModelSwitcher(ref, initialModel);
});
