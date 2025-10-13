import 'package:dio/dio.dart';
import 'dart:convert';
import '../../domain/entities/chat_message.dart';
import '../../domain/services/ai_service.dart';

/// DeepSeek API 适配器
///
/// 支持 DeepSeek Chat 模型
/// DeepSeek API 与 OpenAI API 兼容，使用相同的请求格式
class DeepSeekAdapter implements AIService {
  final Dio _dio;
  final String apiKey;
  final String modelId;
  final String? customApiUrl;

  /// 默认 DeepSeek API 地址
  static const String defaultApiUrl = 'https://api.deepseek.com/v1';

  DeepSeekAdapter({
    required this.apiKey,
    required this.modelId,
    this.customApiUrl,
  }) : _dio = Dio() {
    final baseUrl = customApiUrl ?? defaultApiUrl;
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
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
        '/chat/completions',
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
            final data = line.substring(6).trim();
            if (data == '[DONE]') continue;
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data);
              final choices = json['choices'] as List<dynamic>?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                if (delta != null) {
                  final content = delta['content'] as String?;
                  if (content != null) {
                    yield content;
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
      throw Exception('DeepSeek API streaming failed: $e');
    }
  }

  @override
  Future<ChatMessage> sendMessageSync({
    required List<ChatMessage> messages,
    List<Map<String, dynamic>>? tools,
    int? maxTokens,
  }) async {
    // 重试配置
    const maxRetries = 2;
    var retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        final requestData = _buildRequest(messages, tools, maxTokens, stream: false);

        final response = await _dio.post(
          '/chat/completions',
          data: requestData,
        );

        // 验证响应数据
        if (response.data == null) {
          throw Exception('Response data is null');
        }

        // 如果是字符串，尝试解析为JSON
        final responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        return _parseResponse(responseData);
      } on DioException catch (e) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw _handleDioException(e);
        }
        // 等待后重试
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      } catch (e) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('DeepSeek API call failed: $e');
        }
        // 等待后重试
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    throw Exception('DeepSeek API call failed after $maxRetries retries');
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
      'provider': 'deepseek',
      'model_id': modelId,
      'supports_streaming': true,
      'supports_vision': false, // DeepSeek 当前不支持视觉输入
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
    final requestData = <String, dynamic>{
      'model': modelId,
      'messages': messages.map(_convertMessage).toList(),
      'stream': stream,
    };

    if (maxTokens != null) {
      requestData['max_tokens'] = maxTokens;
    }

    if (tools != null && tools.isNotEmpty) {
      requestData['tools'] = tools.map(_convertTool).toList();
      requestData['tool_choice'] = 'auto';
    }

    return requestData;
  }

  /// 转换消息格式
  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final content = <dynamic>[];

    for (final item in message.content) {
      if (item is TextContent) {
        // 如果只有一个文本内容，直接用字符串
        if (message.content.length == 1) {
          return {
            'role': _convertRole(message.role),
            'content': item.text,
          };
        }
        content.add({
          'type': 'text',
          'text': item.text,
        });
      } else if (item is ImageContent) {
        // DeepSeek 当前不支持图片，但保留接口
        throw Exception('DeepSeek does not support image input');
      } else if (item is ToolUseContent) {
        // DeepSeek 使用 OpenAI 兼容的 tool_calls 格式
        return {
          'role': 'assistant',
          'tool_calls': [
            {
              'id': item.toolUseId,
              'type': 'function',
              'function': {
                'name': item.name,
                'arguments': jsonEncode(item.input),
              },
            },
          ],
        };
      } else if (item is ToolResultContent) {
        return {
          'role': 'tool',
          'tool_call_id': item.toolUseId,
          'content': jsonEncode(item.result),
        };
      }
    }

    return {
      'role': _convertRole(message.role),
      'content': content,
    };
  }

  /// 转换角色
  String _convertRole(MessageRole role) {
    switch (role) {
      case MessageRole.system:
        return 'system';
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
    }
  }

  /// 转换工具定义（从 MCP 格式到 OpenAI 兼容格式）
  Map<String, dynamic> _convertTool(Map<String, dynamic> tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool['name'],
        'description': tool['description'],
        'parameters': tool['input_schema'] ?? tool['parameters'],
      },
    };
  }

  /// 解析响应
  ChatMessage _parseResponse(Map<String, dynamic> data) {
    final choices = data['choices'] as List<dynamic>;
    final message = choices[0]['message'] as Map<String, dynamic>;
    final content = <MessageContent>[];

    // 处理文本内容
    final textContent = message['content'] as String?;
    if (textContent != null && textContent.isNotEmpty) {
      content.add(MessageContent.text(text: textContent));
    }

    // 处理工具调用
    final toolCalls = message['tool_calls'] as List<dynamic>?;
    if (toolCalls != null) {
      for (final call in toolCalls) {
        final function = call['function'] as Map<String, dynamic>;
        content.add(
          MessageContent.toolUse(
            toolUseId: call['id'] as String,
            name: function['name'] as String,
            input: jsonDecode(function['arguments'] as String) as Map<String, dynamic>,
          ),
        );
      }
    }

    return ChatMessage(
      id: data['id'] as String,
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// 处理 Dio 异常
  Exception _handleDioException(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String errorMessage = 'DeepSeek API error';
      if (data is Map<String, dynamic>) {
        final error = data['error'] as Map<String, dynamic>?;
        if (error != null) {
          errorMessage = error['message'] as String? ?? errorMessage;
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
          return Exception('DeepSeek service unavailable: $errorMessage');
        default:
          return Exception('DeepSeek API error ($statusCode): $errorMessage');
      }
    }

    return Exception('Network error: ${e.message}');
  }
}
