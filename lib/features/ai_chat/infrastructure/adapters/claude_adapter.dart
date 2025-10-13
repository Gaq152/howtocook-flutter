import 'package:dio/dio.dart';
import 'dart:convert';
import '../../domain/entities/chat_message.dart';
import '../../domain/services/ai_service.dart';

/// Claude API 适配器
///
/// 支持 Claude 3.5 Sonnet 和其他 Claude 模型
/// 支持自定义 API URL（用于代理或非官方端点）
class ClaudeAdapter implements AIService {
  final Dio _dio;
  final String apiKey;
  final String modelId;
  final String? customApiUrl;
  final String? mcpServerUrl;

  /// 默认 Claude API 地址
  static const String defaultApiUrl = 'https://api.anthropic.com/v1';

  ClaudeAdapter({
    required this.apiKey,
    required this.modelId,
    this.customApiUrl,
    this.mcpServerUrl,
  }) : _dio = Dio() {
    final baseUrl = customApiUrl ?? defaultApiUrl;
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'mcp-client-2025-04-04',
      'content-type': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 300);
  }

  @override
  Stream<String> sendMessage({
    required List<ChatMessage> messages,
    List<Map<String, dynamic>>? tools,
    int? maxTokens,
  }) async* {
    try {
      final requestData = _buildRequest(messages, tools, maxTokens, stream: true);

      final response = await _dio.post(
        '/messages',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream;
      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final json = jsonDecode(data);
              final type = json['type'] as String?;

              // 处理内容块增量
              if (type == 'content_block_delta') {
                final delta = json['delta'] as Map<String, dynamic>?;
                if (delta != null && delta['type'] == 'text_delta') {
                  final text = delta['text'] as String?;
                  if (text != null) {
                    yield text;
                  }
                }
              }
            } catch (e) {
              // 忽略解析错误，继续处理下一行
              continue;
            }
          }
        }
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Claude API streaming failed: $e');
    }
  }

  @override
  Future<ChatMessage> sendMessageSync({
    required List<ChatMessage> messages,
    List<Map<String, dynamic>>? tools,
    int? maxTokens,
  }) async {
    try {
      final requestData = _buildRequest(messages, tools, maxTokens, stream: false);

      final response = await _dio.post(
        '/messages',
        data: requestData,
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Claude API call failed: $e');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      // 发送一个简单的测试请求
      await sendMessageSync(
        messages: [
          ChatMessage(
            id: 'test',
            role: MessageRole.user,
            content: [MessageContent.text(text: 'Hi')],
            timestamp: DateTime.now(),
          ),
        ],
        maxTokens: 10,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getModelInfo() async {
    return {
      'provider': 'claude',
      'model_id': modelId,
      'supports_streaming': true,
      'supports_vision': modelId.contains('claude-3'),
      'supports_tools': true,
    };
  }

  /// 构建请求数据
  Map<String, dynamic> _buildRequest(
    List<ChatMessage> messages,
    List<Map<String, dynamic>>? tools,
    int? maxTokens, {
    required bool stream,
  }) {
    // 提取系统消息
    String? systemMessage;
    final userMessages = <ChatMessage>[];

    for (final msg in messages) {
      if (msg.role == MessageRole.system) {
        // 合并所有系统消息
        final text = msg.content.whereType<TextContent>().map((c) => c.text).join('\n');
        systemMessage = systemMessage == null ? text : '$systemMessage\n$text';
      } else {
        userMessages.add(msg);
      }
    }

    final requestData = <String, dynamic>{
      'model': modelId,
      'messages': userMessages.map(_convertMessage).toList(),
      'max_tokens': maxTokens ?? 4096,
      'stream': stream,
    };

    if (systemMessage != null) {
      requestData['system'] = systemMessage;
    }

    // 添加 MCP 服务器配置
    if (mcpServerUrl != null && mcpServerUrl!.isNotEmpty) {
      requestData['mcp_servers'] = [
        {
          'type': 'url',
          'url': mcpServerUrl,
          'name': 'howtocook-mcp',
        }
      ];

      // 使用 MCP connector 时,不需要手动传递 tools
      // API 会自动从 MCP 服务器发现工具
    } else {
      // 标准工具调用（非 MCP）
      if (tools != null && tools.isNotEmpty) {
        requestData['tools'] = tools;
      }
    }

    return requestData;
  }

  /// 转换消息格式
  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final content = <Map<String, dynamic>>[];

    for (final item in message.content) {
      if (item is TextContent) {
        content.add({
          'type': 'text',
          'text': item.text,
        });
      } else if (item is ImageContent) {
        content.add({
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': item.mimeType ?? 'image/jpeg',
            'data': item.data,
          },
        });
      } else if (item is ToolUseContent) {
        // 如果配置了MCP服务器，使用 mcp_tool_use 类型
        if (mcpServerUrl != null && mcpServerUrl!.isNotEmpty) {
          content.add({
            'type': 'mcp_tool_use',
            'id': item.toolUseId,
            'name': item.name,
            'server_name': 'howtocook-mcp',
            'input': item.input,
          });
        } else {
          // 标准工具调用
          content.add({
            'type': 'tool_use',
            'id': item.toolUseId,
            'name': item.name,
            'input': item.input,
          });
        }
      } else if (item is ToolResultContent) {
        // 如果配置了MCP服务器，使用 mcp_tool_result 类型
        if (mcpServerUrl != null && mcpServerUrl!.isNotEmpty) {
          content.add({
            'type': 'mcp_tool_result',
            'tool_use_id': item.toolUseId,
            'is_error': false,
            'content': [
              {
                'type': 'text',
                'text': jsonEncode(item.result),
              }
            ],
          });
        } else {
          // 标准工具结果
          content.add({
            'type': 'tool_result',
            'tool_use_id': item.toolUseId,
            'content': item.result,
          });
        }
      }
    }

    return {
      'role': message.role == MessageRole.user ? 'user' : 'assistant',
      'content': content,
    };
  }

  /// 解析响应
  ChatMessage _parseResponse(Map<String, dynamic> data) {
    final contentList = data['content'] as List<dynamic>;
    final parsedContent = <MessageContent>[];

    for (final item in contentList) {
      final type = item['type'] as String;
      if (type == 'text') {
        parsedContent.add(MessageContent.text(text: item['text'] as String));
      } else if (type == 'tool_use' || type == 'mcp_tool_use') {
        // 支持标准 tool_use 和 mcp_tool_use
        parsedContent.add(
          MessageContent.toolUse(
            toolUseId: item['id'] as String,
            name: item['name'] as String,
            input: item['input'] as Map<String, dynamic>,
          ),
        );
      }
    }

    return ChatMessage(
      id: data['id'] as String,
      role: MessageRole.assistant,
      content: parsedContent,
      timestamp: DateTime.now(),
    );
  }

  /// 处理 Dio 异常
  Exception _handleDioException(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      var data = e.response!.data;

      // 如果 data 是字符串，尝试解析为 JSON
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          // 无法解析，使用原始字符串作为错误信息
          return Exception('Claude API error ($statusCode): $data');
        }
      }

      String errorMessage = 'Claude API error';
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          errorMessage = error['message'] as String? ?? errorMessage;
        } else if (error is String) {
          errorMessage = error;
        }
      }

      switch (statusCode) {
        case 401:
          return Exception('Invalid API key: $errorMessage');
        case 429:
          return Exception('Rate limit exceeded: $errorMessage');
        case 500:
        case 502:
        case 503:
          return Exception('Claude service unavailable: $errorMessage');
        default:
          return Exception('Claude API error ($statusCode): $errorMessage');
      }
    }

    return Exception('Network error: ${e.message}');
  }
}
