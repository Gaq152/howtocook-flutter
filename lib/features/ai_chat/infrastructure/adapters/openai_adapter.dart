import 'package:dio/dio.dart';
import 'dart:convert';
import '../../domain/entities/chat_message.dart';
import '../../domain/services/ai_service.dart';

/// OpenAI API 适配器
///
/// 支持 GPT-4、GPT-3.5 等 OpenAI 模型
/// 支持自定义 API URL（用于代理或非官方端点）
class OpenAIAdapter implements AIService {
  final Dio _dio;
  final String apiKey;
  final String modelId;
  final String? customApiUrl;

  /// 默认 OpenAI API 地址
  static const String defaultApiUrl = 'https://api.openai.com/v1';

  OpenAIAdapter({
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

      // 检测是否为自定义API（如 code.lljby.cn），使用 /responses 而不是 /chat/completions
      final endpoint = (customApiUrl != null && customApiUrl!.contains('lljby.cn'))
          ? '/responses'
          : '/chat/completions';

      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream;
      final isResponsesEndpoint = (customApiUrl != null && customApiUrl!.contains('lljby.cn'));

      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') continue;
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data);

              if (isResponsesEndpoint) {
                // Responses API 格式: output数组中包含内容块
                final output = json['output'] as List<dynamic>?;
                if (output != null) {
                  for (final block in output) {
                    if (block is Map<String, dynamic>) {
                      final type = block['type'] as String?;
                      if (type == 'text') {
                        final text = block['text'] as String?;
                        if (text != null && text.isNotEmpty) {
                          yield text;
                        }
                      }
                    }
                  }
                }
              } else {
                // 标准 OpenAI 格式
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
      throw Exception('OpenAI API streaming failed: $e');
    }
  }

  @override
  Future<ChatMessage> sendMessageSync({
    required List<ChatMessage> messages,
    List<Map<String, dynamic>>? tools,
    int? maxTokens,
  }) async {
    // 对于 /responses 端点，强制使用流式（代理API要求）
    final isResponsesEndpoint = customApiUrl != null && customApiUrl!.contains('lljby.cn');

    if (isResponsesEndpoint) {
      // Responses API 强制要求流式，所以收集所有流式输出
      final buffer = StringBuffer();
      await for (final chunk in sendMessage(messages: messages, tools: tools, maxTokens: maxTokens)) {
        buffer.write(chunk);
      }

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: [MessageContent.text(text: buffer.toString())],
        timestamp: DateTime.now(),
      );
    }

    // 标准 OpenAI API 使用非流式
    try {
      final requestData = _buildRequest(messages, tools, maxTokens, stream: false);

      final response = await _dio.post(
        '/chat/completions',
        data: requestData,
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('OpenAI API call failed: $e');
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
      'provider': 'openai',
      'model_id': modelId,
      'supports_streaming': true,
      'supports_vision': modelId.contains('gpt-4') && modelId.contains('vision'),
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
    // 检测是否为 Responses API 端点
    final isResponsesEndpoint = customApiUrl != null && customApiUrl!.contains('lljby.cn');

    if (isResponsesEndpoint) {
      // Responses API 格式
      final requestData = <String, dynamic>{
        'model': modelId,
        'input': messages.map(_convertMessageForResponses).toList(),
        'stream': true, // Responses API 强制要求流式
      };

      // Responses API 不支持 max_tokens 参数

      // 暂时禁用工具传递，先测试基本功能
      // TODO: 调试代理 API 的工具格式要求
      // if (tools != null && tools.isNotEmpty) {
      //   requestData['tools'] = tools.map(_convertTool).toList();
      // }

      return requestData;
    }

    // 标准 OpenAI API 格式
    final requestData = <String, dynamic>{
      'model': modelId,
      'messages': messages.map(_convertMessage).toList(),
      'stream': stream,
    };

    if (maxTokens != null) {
      requestData['max_tokens'] = maxTokens;
    }

    // 暂时禁用工具传递，先测试基本功能
    // TODO: 调试代理 API 的工具格式要求
    // if (tools != null && tools.isNotEmpty) {
    //   requestData['tools'] = tools.map(_convertTool).toList();
    //   requestData['tool_choice'] = 'auto';
    // }

    return requestData;
  }

  /// 转换消息格式（用于 Responses API）
  Map<String, dynamic> _convertMessageForResponses(ChatMessage message) {
    final content = <Map<String, dynamic>>[];

    for (final item in message.content) {
      if (item is TextContent) {
        content.add({
          'type': 'input_text',
          'text': item.text,
        });
      } else if (item is ImageContent) {
        content.add({
          'type': 'input_image',
          'image_url': 'data:${item.mimeType ?? 'image/jpeg'};base64,${item.data}',
        });
      }
      // TODO: 处理工具调用内容
    }

    return {
      'role': _convertRole(message.role),
      'content': content,
    };
  }

  /// 转换消息格式（用于标准 OpenAI API）
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
        content.add({
          'type': 'image_url',
          'image_url': {
            'url': 'data:${item.mimeType ?? 'image/jpeg'};base64,${item.data}',
          },
        });
      } else if (item is ToolUseContent) {
        // OpenAI 使用 tool_calls 字段
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
      var data = e.response!.data;

      // 如果 data 是字符串，尝试解析为 JSON
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          // 无法解析，使用原始字符串作为错误信息
          return Exception('OpenAI API error ($statusCode): $data');
        }
      }

      String errorMessage = 'OpenAI API error';
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
          return Exception('OpenAI service unavailable: $errorMessage');
        default:
          return Exception('OpenAI API error ($statusCode): $errorMessage');
      }
    }

    return Exception('Network error: ${e.message}');
  }
}
