import '../../domain/entities/ai_model_config.dart';
import '../../domain/services/ai_service.dart';
import '../adapters/claude_adapter.dart';
import '../adapters/openai_adapter.dart';
import '../adapters/deepseek_adapter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI Service 工厂
///
/// 根据模型配置创建对应的 AI Service 实例
class AIServiceFactory {
  /// 创建 AI Service
  ///
  /// [config] 模型配置
  /// 返回: AIService 实例
  static AIService create(AIModelConfig config) {
    // 获取 API Key 和 URL
    final apiKey = _getApiKey(config);
    final apiUrl = _getApiUrl(config);

    // 根据服务商创建对应的适配器
    switch (config.provider) {
      case AIProvider.claude:
        // 获取 MCP 服务器 URL (如果配置支持 MCP)
        final mcpUrl = config.capabilities.supportsMCP
            ? dotenv.env['MCP_BASE_URL']
            : null;

        return ClaudeAdapter(
          apiKey: apiKey,
          modelId: config.modelId,
          customApiUrl: apiUrl,
          mcpServerUrl: mcpUrl != null ? '$mcpUrl/mcp' : null,
        );

      case AIProvider.openai:
        return OpenAIAdapter(
          apiKey: apiKey,
          modelId: config.modelId,
          customApiUrl: apiUrl,
        );

      case AIProvider.deepseek:
        return DeepSeekAdapter(
          apiKey: apiKey,
          modelId: config.modelId,
          customApiUrl: apiUrl,
        );
    }
  }

  /// 获取 API Key
  ///
  /// 优先使用用户自定义 Key，否则使用内置 Key
  static String _getApiKey(AIModelConfig config) {
    if (!config.useBuiltinKey && config.customApiKey != null) {
      return config.customApiKey!;
    }

    // 从环境变量获取内置 Key
    final envKey = _getBuiltinKeyEnvName(config.provider);
    final apiKey = dotenv.env[envKey];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Missing API key for ${config.provider.name}. '
        'Please set $envKey in .env file or provide a custom API key.',
      );
    }

    return apiKey;
  }

  /// 获取 API URL
  ///
  /// 优先使用用户自定义 URL，否则使用内置 URL
  static String? _getApiUrl(AIModelConfig config) {
    // 如果用户提供了自定义 URL，使用自定义 URL
    if (config.customApiUrl != null && config.customApiUrl!.isNotEmpty) {
      return config.customApiUrl;
    }

    // 如果使用内置 Key，使用内置 URL
    if (config.useBuiltinKey) {
      final envKey = _getBuiltinUrlEnvName(config.provider);
      final apiUrl = dotenv.env[envKey];
      return apiUrl;
    }

    // 用户使用自定义 Key 但没有指定 URL，返回 null（使用默认官方 URL）
    return null;
  }

  /// 获取内置 Key 的环境变量名
  static String _getBuiltinKeyEnvName(AIProvider provider) {
    switch (provider) {
      case AIProvider.claude:
        return 'BUILTIN_CLAUDE_API_KEY';
      case AIProvider.openai:
        return 'BUILTIN_OPENAI_API_KEY';
      case AIProvider.deepseek:
        return 'BUILTIN_DEEPSEEK_API_KEY';
    }
  }

  /// 获取内置 URL 的环境变量名
  static String _getBuiltinUrlEnvName(AIProvider provider) {
    switch (provider) {
      case AIProvider.claude:
        return 'BUILTIN_CLAUDE_API_URL';
      case AIProvider.openai:
        return 'BUILTIN_OPENAI_API_URL';
      case AIProvider.deepseek:
        return 'BUILTIN_DEEPSEEK_API_URL';
    }
  }

  /// 验证模型配置
  ///
  /// [config] 模型配置
  /// 返回: true 表示配置有效并且 API 可用
  static Future<bool> validateConfig(AIModelConfig config) async {
    try {
      final service = create(config);
      return await service.validateApiKey();
    } catch (e) {
      return false;
    }
  }

  /// 获取默认模型配置列表
  ///
  /// 返回: 内置的默认模型配置（2025年最新版本）
  static List<AIModelConfig> getBuiltinModels() {
    return [
      // Claude 模型（2025最新）
      AIModelConfig(
        id: 'builtin-claude-sonnet-4-5',
        provider: AIProvider.claude,
        modelId: 'claude-sonnet-4-5-20250929',
        displayName: 'Claude Sonnet 4.5 (2025)',
        description: 'Claude最新旗舰模型，卓越推理和工具调用能力',
        isBuiltin: true,
        isDefault: true,
        capabilities: const ModelCapabilities(
          supportsImageInput: true,
          supportsMCP: true,
          maxTokens: 8192,
          contextWindow: 200000,
        ),
      ),
      AIModelConfig(
        id: 'builtin-claude-sonnet-4',
        provider: AIProvider.claude,
        modelId: 'claude-sonnet-4-20250514',
        displayName: 'Claude Sonnet 4 (2025)',
        description: 'Claude第四代Sonnet模型',
        isBuiltin: true,
        capabilities: const ModelCapabilities(
          supportsImageInput: true,
          supportsMCP: true,
          maxTokens: 8192,
          contextWindow: 200000,
        ),
      ),

      // OpenAI 模型（2025最新）
      AIModelConfig(
        id: 'builtin-gpt-5',
        provider: AIProvider.openai,
        modelId: 'gpt-5-2025-08-07',
        displayName: 'GPT-5 (2025)',
        description: 'OpenAI最新GPT-5模型，更强推理和多模态能力',
        isBuiltin: true,
        capabilities: const ModelCapabilities(
          supportsImageInput: true,
          supportsMCP: true,
          maxTokens: 16384,
          contextWindow: 256000,
        ),
      ),
      AIModelConfig(
        id: 'builtin-gpt-4o',
        provider: AIProvider.openai,
        modelId: 'gpt-4o',
        displayName: 'GPT-4o',
        description: 'GPT-4优化版，速度更快、成本更低',
        isBuiltin: true,
        capabilities: const ModelCapabilities(
          supportsImageInput: true,
          supportsMCP: true,
          maxTokens: 4096,
          contextWindow: 128000,
        ),
      ),

      // DeepSeek 模型（2025最新）
      AIModelConfig(
        id: 'builtin-deepseek-chat',
        provider: AIProvider.deepseek,
        modelId: 'deepseek-chat',
        displayName: 'DeepSeek Chat (2025)',
        description: '国产大模型，性能优秀且价格实惠',
        isBuiltin: true,
        capabilities: const ModelCapabilities(
          supportsImageInput: false,
          supportsMCP: true,
          maxTokens: 8192,
          contextWindow: 64000,
        ),
      ),
    ];
  }
}
