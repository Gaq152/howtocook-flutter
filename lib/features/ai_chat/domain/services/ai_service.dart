import '../entities/chat_message.dart';

/// AI 服务接口
///
/// 统一的 AI 服务抽象接口，支持 Claude、OpenAI、DeepSeek 等多种服务商
abstract class AIService {
  /// 发送消息（流式响应）
  ///
  /// [messages] 对话历史（包含当前消息）
  /// [tools] MCP 工具定义（可选）
  /// [maxTokens] 最大生成 token 数
  ///
  /// 返回: Stream<String> - 流式文本响应
  Stream<String> sendMessage({
    required List<ChatMessage> messages,
    List<Map<String, dynamic>>? tools,
    int? maxTokens,
  });

  /// 发送消息（非流式响应）
  ///
  /// [messages] 对话历史（包含当前消息）
  /// [tools] MCP 工具定义（可选）
  /// [maxTokens] 最大生成 token 数
  ///
  /// 返回: ChatMessage - 完整的 AI 响应消息
  Future<ChatMessage> sendMessageSync({
    required List<ChatMessage> messages,
    List<Map<String, dynamic>>? tools,
    int? maxTokens,
  });

  /// 验证 API Key 是否有效
  ///
  /// 返回: true 表示有效，false 表示无效
  Future<bool> validateApiKey();

  /// 获取模型信息
  ///
  /// 返回: Map<String, dynamic> - 模型信息（名称、能力等）
  Future<Map<String, dynamic>> getModelInfo();
}
