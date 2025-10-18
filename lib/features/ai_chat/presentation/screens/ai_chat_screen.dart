import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 用于 kDebugMode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../sync/infrastructure/bundled_data_loader.dart';
import '../../../recipe/domain/entities/recipe.dart';
import '../../domain/entities/chat_message.dart';
import '../../infrastructure/services/ai_service_factory.dart';
import '../../infrastructure/services/mcp_service.dart';
import '../../infrastructure/services/recipe_recognizer.dart';
import '../widgets/message_bubble.dart';

/// MCP 工具调用记录（用于调试面板）
class MCPToolCall {
  final String toolName;
  final DateTime timestamp;
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;
  final String? error;
  final Duration duration;

  MCPToolCall({
    required this.toolName,
    required this.timestamp,
    required this.input,
    required this.output,
    this.error,
    required this.duration,
  });
}

/// AI 聊天页面
///
/// 功能：
/// - 发送和接收消息
/// - 模型切换（Claude、OpenAI、DeepSeek）
/// - 联网搜索开关
/// - 图片上传（多模态）
/// - 聊天记录持久化
/// - MCP 工具默认集成
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  final MCPService _mcpService = MCPService();
  late final RecipeRecognizer _recipeRecognizer;

  bool _isLoading = false;
  bool _isStreaming = false;
  String _streamingText = ''; // 流式输出的当前文本
  bool _shouldStopStreaming = false;
  String? _selectedImagePath;
  List<Map<String, dynamic>>? _mcpTools;
  // 新创建的食谱（用于在聊天中显示卡片和跳转到预览页面）
  final Map<String, Recipe> _createdRecipes = {};
  // MCP 工具调用历史（仅 debug 模式）
  final List<MCPToolCall> _mcpCallHistory = [];

  // 当前选择的模型 ID（默认 DeepSeek）
  String _currentModelId = 'builtin-deepseek-chat';

  // 联网搜索开关
  bool _enableWebSearch = false;

  // System Prompt（引导 AI 使用 MCP 工具）
  String _buildSystemPrompt() {
    final now = DateTime.now();
    final hour = now.hour;
    String timeOfDay;
    if (hour < 6) {
      timeOfDay = '凌晨';
    } else if (hour < 9) {
      timeOfDay = '早晨';
    } else if (hour < 12) {
      timeOfDay = '上午';
    } else if (hour < 14) {
      timeOfDay = '中午';
    } else if (hour < 18) {
      timeOfDay = '下午';
    } else if (hour < 22) {
      timeOfDay = '晚上';
    } else {
      timeOfDay = '深夜';
    }

    final weekday = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'][now.weekday - 1];
    final dateStr = '${now.year}年${now.month}月${now.day}日 $weekday $timeOfDay ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return '''你是一个专业的烹饪助手，可以访问"程序员做饭指南"的完整菜谱数据库。

当前时间信息：$dateStr

重要规则：
1. **优先使用MCP工具查询数据**：当用户询问菜谱、食材、做法等问题时，务必先调用相应的MCP工具获取数据
2. **完整展示工具结果**：获取到MCP工具返回的数据后，必须将这些数据完整地展示给用户，不要忽略或省略
3. **基于工具结果回答**：在输出工具查询结果后，可以添加你的专业建议和补充说明
4. **搜索功能**：要搜索食谱时使用getAllRecipes工具获取所有菜谱，然后筛选匹配的结果
5. **时令建议**：根据当前时间（${now.month}月，$timeOfDay）、季节和时间段给出合适的饮食建议

可用的MCP工具：
- getAllRecipes: 获取所有菜谱（用于搜索和浏览）
- getRecipesByCategory: 按分类获取菜谱（荤菜、素菜、主食、汤、甜品、饮品等）
- getRecipeById: 查询菜谱详情（使用菜谱名称，如"红烧肉"）
- recommendMeals: 智能推荐菜谱（可指定人数、过敏原、忌口）
- whatToEat: 今天吃什么（随机推荐，可指定人数）
- createRecipe: 创建新食谱（当用户提供食谱文本时使用）

关于createRecipe工具：
- 当用户提供了食谱的文本描述（包含食材、步骤等），使用此工具创建新食谱
- 参数：recipeText（必需）、checkDuplicate（可选，默认true）、similarityThreshold（可选，默认0.75）
- 创建成功后，在回复中提及食谱名称，系统会自动显示可点击的食谱卡片
- 用户点击卡片可以预览并保存到"我的食谱"

注意：getAllRecipes返回的ID格式为"recipe_数字"，这是生成的ID，不能用于getRecipeById查询。查询详情时请使用菜谱的中文名称。''';
  }


  @override
  void initState() {
    super.initState();
    _recipeRecognizer = RecipeRecognizer(BundledDataLoader());
    _loadChatHistory();
    _loadSettings();
    _loadMCPTools();
  }

  /// 加载 MCP 工具列表
  Future<void> _loadMCPTools() async {
    try {
      final tools = await _mcpService.listTools();
      setState(() {
        _mcpTools = tools;
      });
      debugPrint('MCP tools loaded: ${tools.length} tools');
    } catch (e) {
      debugPrint('Failed to load MCP tools: $e');
      // MCP 工具加载失败不影响基本聊天功能
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载聊天历史
  Future<void> _loadChatHistory() async {
    try {
      final hiveService = HiveService();

      // 加载聊天消息
      final historyJson = await hiveService.getChatHistory();
      if (historyJson != null && historyJson.isNotEmpty) {
        setState(() {
          _messages.addAll(
            historyJson.map((json) {
              // 确保转换为 Map<String, dynamic>
              final map = Map<String, dynamic>.from(json);
              return ChatMessage.fromJson(map);
            }).toList(),
          );
        });
      }

      // 加载 AI 创建的食谱
      final recipesJson = await hiveService.getSetting('ai_created_recipes');
      if (recipesJson is List) {
        setState(() {
          for (final item in recipesJson) {
            if (item is Map) {
              try {
                final map = Map<String, dynamic>.from(item);
                final recipe = Recipe.fromJson(map);
                _createdRecipes[recipe.id] = recipe;
              } catch (e) {
                debugPrint('Failed to parse recipe: $e');
              }
            }
          }
        });
        debugPrint('Loaded ${_createdRecipes.length} AI-created recipes');
      }

      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('Failed to load chat history: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final hiveService = HiveService();
      final enableWebSearch = await hiveService.getSetting(
        'enable_web_search',
        defaultValue: false,
      );

      setState(() {
        _enableWebSearch = enableWebSearch as bool;
      });
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  /// 保存聊天历史
  Future<void> _saveChatHistory() async {
    try {
      final hiveService = HiveService();

      // 保存聊天消息
      final jsonString = jsonEncode(_messages.map((m) => m.toJson()).toList());
      final jsonList = (jsonDecode(jsonString) as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      await hiveService.saveChatHistory(jsonList);
      debugPrint('Chat history saved: ${jsonList.length} messages');

      // 保存 AI 创建的食谱
      await _saveCreatedRecipes();
    } catch (e, stackTrace) {
      debugPrint('Failed to save chat history: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// 保存 AI 创建的食谱（独立方法，可在创建时立即调用）
  Future<void> _saveCreatedRecipes() async {
    try {
      final hiveService = HiveService();
      final recipesJson = _createdRecipes.values
          .map((recipe) => recipe.toJson())
          .toList();
      await hiveService.saveSetting('ai_created_recipes', recipesJson);
      debugPrint('Saved ${_createdRecipes.length} AI-created recipes');
    } catch (e) {
      debugPrint('Failed to save created recipes: $e');
    }
  }

  /// 保存设置
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final hiveService = HiveService();
      await hiveService.saveSetting(key, value);
    } catch (e) {
      debugPrint('Failed to save setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI 助手'),
            const SizedBox(width: 8),
            _buildModelSelector(),
          ],
        ),
        actions: [
          _buildWebSearchToggle(),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空聊天记录',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
      // MCP 调试悬浮按钮（仅 debug 模式）
      floatingActionButton: kDebugMode && _mcpCallHistory.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showMCPDebugPanel,
              tooltip: 'MCP 调试面板',
              backgroundColor: Colors.orange,
              child: Badge(
                label: Text('${_mcpCallHistory.length}'),
                backgroundColor: Colors.red,
                textColor: Colors.white,
                child: const Icon(Icons.bug_report),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  /// 构建模型选择器
  Widget _buildModelSelector() {
    // 获取所有可用模型
    final models = AIServiceFactory.getBuiltinModels();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: _currentModelId,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down, size: 18),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        items: models.map((model) {
          return DropdownMenuItem(
            value: model.id, // 使用 id 而不是 modelId
            child: Text(model.displayName),
          );
        }).toList(),
        onChanged: (modelId) {
          if (modelId != null) {
            setState(() {
              _currentModelId = modelId;
            });
          }
        },
      ),
    );
  }

  /// 构建联网搜索开关
  Widget _buildWebSearchToggle() {
    return IconButton(
      icon: Icon(
        _enableWebSearch ? Icons.language : Icons.language_outlined,
        color: _enableWebSearch ? AppColors.primary : null,
      ),
      tooltip: _enableWebSearch ? '关闭联网搜索' : '开启联网搜索',
      onPressed: () {
        setState(() {
          _enableWebSearch = !_enableWebSearch;
        });
        _saveSetting('enable_web_search', _enableWebSearch);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_enableWebSearch ? '已开启联网搜索' : '已关闭联网搜索'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI 智能助手',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            '您的贴心美食顾问',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '问我任何关于烹饪的问题\n我将为您提供专业建议和菜谱推荐',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('今天吃什么？'),
              _buildSuggestionChip('推荐一道家常菜'),
              _buildSuggestionChip('如何做红烧肉？'),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建建议问题芯片
  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _inputController.text = text;
      },
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.primary,
      ),
    );
  }

  /// 构建消息列表
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadingIndicator();
        }

        final message = _messages[index];

        // 获取模型名称（从消息保存的modelId，而不是当前选择的模型）
        String? modelName;
        if (message.role == MessageRole.assistant && message.modelId != null) {
          final models = AIServiceFactory.getBuiltinModels();
          final model = models.where((m) => m.id == message.modelId).firstOrNull;
          modelName = model?.displayName;
        }

        // 判断这是否是最后一条正在流式显示的消息
        final isLastStreaming = index == _messages.length - 1 && _isStreaming;

        return MessageBubble(
          message: message,
          modelName: modelName,
          isStreaming: isLastStreaming,
          streamingText: isLastStreaming ? _streamingText : null,
          recipeRecognizer: _recipeRecognizer,
          createdRecipes: _createdRecipes, // 传递 AI 创建的食谱列表
          onRecipeTap: (recipeId) {
            // 检查是否是 AI 生成的食谱
            if (_createdRecipes.containsKey(recipeId)) {
              // AI 生成的食谱：跳转到预览页面
              final recipe = _createdRecipes[recipeId]!;
              context.push('/recipe-preview', extra: recipe);
            } else {
              // 内置食谱：直接跳转到详情页
              context.push('/recipe/$recipeId');
            }
          },
          onDelete: () {
            setState(() {
              _messages.removeAt(index);
            });
            _saveChatHistory();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('消息已删除')),
            );
          },
          onRetry: message.role == MessageRole.assistant
              ? () {
                  // 重新发送上一条用户消息
                  if (index > 0 && _messages[index - 1].role == MessageRole.user) {
                    final userMessage = _messages[index - 1];
                    // 移除当前AI消息
                    setState(() {
                      _messages.removeAt(index);
                    });
                    // 触发重新发送（传入用户消息）
                    _resendMessage(userMessage);
                  }
                }
              : null,
          onEdit: message.role == MessageRole.user
              ? () {
                  // 显示编辑对话框
                  _showEditDialog(context, message, index);
                }
              : null,
        );
      },
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            topLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI 正在思考...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图片预览
          if (_selectedImagePath != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 80,
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImagePath!),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedImagePath = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 输入框行
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                tooltip: '上传图片',
                onPressed: _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: !_isLoading, // 加载时禁用
                  decoration: InputDecoration(
                    hintText: _isLoading ? 'AI 正在回复...' : '输入消息...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
                        ),
                  color: _isLoading ? Colors.grey[400] : null,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isLoading ? Icons.stop : Icons.send,
                    color: Colors.white,
                  ),
                  tooltip: _isLoading ? '终止' : '发送',
                  onPressed: _isLoading ? _stopStreaming : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 选择图片
  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final content = _inputController.text.trim();
    if (content.isEmpty && _selectedImagePath == null) return;

    // 创建用户消息
    final messageContent = <MessageContent>[
      if (content.isNotEmpty) MessageContent.text(text: content),
      if (_selectedImagePath != null)
        MessageContent.image(
          data: '', // 将在发送时处理
          localPath: _selectedImagePath,
        ),
    ];

    final userMessage = ChatMessage(
      id: DateTime.now().toString(),
      role: MessageRole.user,
      content: messageContent,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _inputController.clear();
      _selectedImagePath = null;
    });

    _scrollToBottom();

    // 调用实际的发送逻辑
    await _sendMessageInternal();
  }

  /// 重新发送消息（用于重试）
  Future<void> _resendMessage(ChatMessage userMessage) async {
    if (_isLoading) return; // 如果正在加载，不允许重新发送

    setState(() {
      _isLoading = true;
    });

    _scrollToBottom();

    // 调用实际的发送逻辑
    await _sendMessageInternal();
  }

  /// 实际的消息发送逻辑（供 _sendMessage 和 _resendMessage 调用）
  Future<void> _sendMessageInternal() async {
    final tempAssistantMessage = ChatMessage(
      id: DateTime.now().toString(),
      role: MessageRole.assistant,
      content: [MessageContent.text(text: '')],
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(tempAssistantMessage);
    });

    _scrollToBottom();

    try {
      // 获取 AI 服务
      final models = AIServiceFactory.getBuiltinModels();
      final currentModel = models.firstWhere(
        (m) => m.id == _currentModelId, // 使用 id 而不是 modelId
        orElse: () => models.first,
      );

      final aiService = AIServiceFactory.create(currentModel);

      // 准备消息历史（不包括刚添加的临时消息）
      // 只保留最近3轮对话（6条消息：3条用户+3条AI），避免token超限
      var allHistory = _messages.sublist(0, _messages.length - 1);

      // 筛选用户和AI的消息，保留最近3轮
      final recentMessages = <ChatMessage>[];
      var userCount = 0;
      for (var i = allHistory.length - 1; i >= 0; i--) {
        final msg = allHistory[i];
        if (msg.role == MessageRole.user) {
          userCount++;
          if (userCount > 3) break;
        }
        if (msg.role != MessageRole.system) {
          recentMessages.insert(0, msg);
        }
      }

      // 在第一条消息前添加 system prompt（每次都生成新的，包含最新时间）
      var history = [
        ChatMessage(
          id: 'system',
          role: MessageRole.system,
          content: [MessageContent.text(text: _buildSystemPrompt())],
          timestamp: DateTime.now(),
        ),
        ...recentMessages,
      ];

      // MCP 工具调用循环
      if (_mcpTools != null && _mcpTools!.isNotEmpty) {
        debugPrint('Starting MCP tool calling loop with ${_mcpTools!.length} tools');

        // 使用非流式API进行工具调用循环（最多10轮）
        var toolCallCount = 0;
        const maxToolCalls = 10;
        // 收集本次对话创建的食谱ID列表
        final createdRecipeIds = <String>[];

        while (toolCallCount < maxToolCalls) {
          toolCallCount++;
          debugPrint('Tool call iteration $toolCallCount');

          // 调用 AI（非流式）
          final response = await aiService.sendMessageSync(
            messages: history,
            tools: _mcpTools,
          );

          debugPrint('Got response with ${response.content.length} content items');

          // 检查是否有 tool_calls
          final hasToolCalls = response.content.any((c) => c is ToolUseContent);

          if (!hasToolCalls) {
            // 没有工具调用，直接显示文本响应
            debugPrint('No tool calls, displaying final response');
            setState(() {
              final lastIndex = _messages.length - 1;
              _messages[lastIndex] = ChatMessage(
                id: tempAssistantMessage.id,
                role: MessageRole.assistant,
                content: response.content,
                timestamp: tempAssistantMessage.timestamp,
                modelId: _currentModelId, // 保存使用的模型ID
                createdRecipeIds: createdRecipeIds.isNotEmpty ? createdRecipeIds : null,
              );
              _isLoading = false;
            });
            break;
          }

          // 有工具调用，执行工具
          debugPrint('Found tool calls, executing...');
          final toolResults = <MessageContent>[];

          for (final content in response.content) {
            if (content is ToolUseContent) {
              debugPrint('Executing tool: ${content.name}');

              try {
                // 执行 MCP 工具
                final result = await _executeMCPTool(content.name, content.input);
                debugPrint('Tool ${content.name} executed successfully');

                // 如果是 createRecipe 工具且成功，收集创建的食谱 ID
                final cleanToolName = content.name.replaceFirst('mcp_howtocook_', '');
                if (cleanToolName == 'createRecipe' &&
                    result['success'] == true &&
                    result.containsKey('recipe')) {
                  final recipeData = result['recipe'] as Map<String, dynamic>?;
                  if (recipeData != null && recipeData.containsKey('id')) {
                    final recipeId = recipeData['id'] as String;
                    createdRecipeIds.add(recipeId);
                    debugPrint('✅ Collected created recipe ID: $recipeId');
                  }
                }

                toolResults.add(
                  MessageContent.toolResult(
                    toolUseId: content.toolUseId,
                    result: result,
                  ),
                );
              } catch (e) {
                debugPrint('Tool ${content.name} execution failed: $e');
                toolResults.add(
                  MessageContent.toolResult(
                    toolUseId: content.toolUseId,
                    result: {'error': e.toString()},
                  ),
                );
              }
            }
          }

          // 将 AI 的 tool_calls 和工具结果添加到历史
          // 注意：每个 tool result 需要单独的消息，因为适配器会为每个生成独立的 API 消息
          final toolResultMessages = toolResults.map((result) {
            return ChatMessage(
              id: DateTime.now().toString(),
              role: MessageRole.user, // tool results 的角色（适配器会转换为 'tool'）
              content: [result],
              timestamp: DateTime.now(),
            );
          }).toList();

          history = [
            ...history,
            response, // AI 的 tool_calls
            ...toolResultMessages, // 每个 tool result 一条消息
          ];

          // 更新 UI 显示工具调用状态
          setState(() {
            final lastIndex = _messages.length - 1;
            _messages[lastIndex] = ChatMessage(
              id: tempAssistantMessage.id,
              role: MessageRole.assistant,
              content: [MessageContent.text(text: 'AI 正在调用工具查询数据...')],
              timestamp: tempAssistantMessage.timestamp,
            );
          });
        }

        if (toolCallCount >= maxToolCalls) {
          debugPrint('WARNING: Reached max tool call iterations');
          setState(() {
            final lastIndex = _messages.length - 1;
            _messages[lastIndex] = ChatMessage(
              id: tempAssistantMessage.id,
              role: MessageRole.assistant,
              content: [MessageContent.text(text: '抱歉，工具调用次数过多，请重新尝试。')],
              timestamp: tempAssistantMessage.timestamp,
              modelId: _currentModelId, // 保存使用的模型ID
              createdRecipeIds: createdRecipeIds.isNotEmpty ? createdRecipeIds : null,
            );
            _isLoading = false;
          });
        }
      } else {
        // 没有 MCP 工具，使用普通流式响应
        debugPrint('No MCP tools, using streaming response');

        // 开启流式显示状态
        setState(() {
          _isStreaming = true;
          _streamingText = '';
          _shouldStopStreaming = false;
        });

        final responseStream = aiService.sendMessage(
          messages: history,
        );

        // 累积响应文本
        final responseBuffer = StringBuffer();
        var chunkCount = 0;

        await for (final chunk in responseStream) {
          // 检查用户是否点击了终止按钮
          if (_shouldStopStreaming) {
            debugPrint('Streaming stopped by user at chunk $chunkCount');
            break;
          }

          chunkCount++;
          responseBuffer.write(chunk);

          // 更新流式文本状态（用于MessageBubble显示）
          setState(() {
            _streamingText = responseBuffer.toString();
          });

          _scrollToBottom();
        }

        debugPrint('Streaming complete. Received $chunkCount chunks, total ${responseBuffer.length} characters');

        // 流式完成，更新最终消息并关闭流式状态
        setState(() {
          _isStreaming = false;
          _isLoading = false;
          final lastIndex = _messages.length - 1;
          _messages[lastIndex] = ChatMessage(
            id: tempAssistantMessage.id,
            role: MessageRole.assistant,
            content: [MessageContent.text(text: responseBuffer.toString())],
            timestamp: tempAssistantMessage.timestamp,
            modelId: _currentModelId, // 保存使用的模型ID
          );
        });
      }

      // 保存聊天历史
      _saveChatHistory();
      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        // 重置流式状态
        _isStreaming = false;
        _isLoading = false;

        // 移除临时消息并添加错误消息
        if (_messages.isNotEmpty && _messages.last.id == tempAssistantMessage.id) {
          _messages.removeLast();
        }
        _messages.add(ChatMessage(
          id: DateTime.now().toString(),
          role: MessageRole.assistant,
          content: [MessageContent.text(text: '抱歉，发生了错误：$e')],
          timestamp: DateTime.now(),
        ));
      });

      // 保存错误消息
      _saveChatHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    }
  }

  /// 执行 MCP 工具
  ///
  /// 根据工具名称调用相应的 MCPService 方法
  Future<Map<String, dynamic>> _executeMCPTool(
    String toolName,
    Map<String, dynamic> input,
  ) async {
    // 移除 mcp_howtocook_ 前缀（如果有）
    final cleanToolName = toolName.replaceFirst('mcp_howtocook_', '');

    debugPrint('Executing MCP tool: $cleanToolName with input: $input');

    // 记录开始时间
    final startTime = DateTime.now();
    Map<String, dynamic>? result;
    String? errorMessage;

    try {
      switch (cleanToolName) {
        case 'getAllRecipes':
          final recipes = await _mcpService.getAllRecipes();
          result = {
            'success': true,
            'recipes': recipes.map((r) => r.toJson()).toList(),
            'count': recipes.length,
          };
          break;

        case 'getRecipesByCategory':
          // 支持多种参数名
          final categoryValue = input['category'] ?? input['categoryName'];
          final category = categoryValue?.toString();
          if (category == null || category.isEmpty) {
            throw Exception('Missing required parameter: category');
          }
          final recipes = await _mcpService.getRecipesByCategory(category);
          result = {
            'success': true,
            'category': category,
            'recipes': recipes.map((r) => r.toJson()).toList(),
            'count': recipes.length,
          };
          break;

        case 'getRecipeById':
          // 支持多种参数名：query, id, recipeId, recipeName
          final queryValue = input['query'] ?? input['id'] ?? input['recipeId'] ?? input['recipeName'];
          final query = queryValue?.toString();
          if (query == null || query.isEmpty) {
            throw Exception('Missing required parameter: query/id');
          }

          // 检查是否是生成的 ID（格式：recipe_数字）
          if (query.startsWith('recipe_')) {
            result = {
              'success': false,
              'error': 'Generated ID "$query" cannot be used for detail query. '
                  'Please use the recipe name instead. '
                  'Example: Use "红烧肉" instead of "$query".',
            };
            break;
          }

          final recipe = await _mcpService.getRecipeById(query);
          result = {
            'success': true,
            'recipe': recipe.toJson(),
          };
          break;

        case 'recommendMeals':
          // 支持多种参数名：peopleCount, numberOfPeople, people
          final peopleCount = _parseIntParam(
            input['peopleCount'] ?? input['numberOfPeople'] ?? input['people'],
            defaultValue: 2,
          );
          final allergies = input['allergies'] as List<dynamic>?;
          final avoidItems = input['avoidItems'] as List<dynamic>?;

          final mealsResult = await _mcpService.recommendMeals(
            peopleCount: peopleCount,
            allergies: allergies?.cast<String>(),
            avoidItems: avoidItems?.cast<String>(),
          );
          result = {
            'success': true,
            ...mealsResult,
          };
          break;

        case 'whatToEat':
          // 支持多种参数名：peopleCount, numberOfPeople, people
          // 如果没有提供参数，默认2人
          final peopleCount = _parseIntParam(
            input['peopleCount'] ?? input['numberOfPeople'] ?? input['people'],
            defaultValue: 2,
          );
          debugPrint('whatToEat with peopleCount: $peopleCount');

          final recipes = await _mcpService.whatToEat(peopleCount: peopleCount);
          result = {
            'success': true,
            'recipes': recipes.map((r) => r.toJson()).toList(),
            'count': recipes.length,
            'peopleCount': peopleCount,
          };
          break;

        case 'createRecipe':
          // 支持多种参数名
          final recipeTextValue = input['recipeText'] ?? input['text'] ?? input['recipe'];
          final recipeText = recipeTextValue?.toString();
          if (recipeText == null || recipeText.isEmpty) {
            throw Exception('Missing required parameter: recipeText');
          }

          final checkDuplicate = input['checkDuplicate'] as bool? ?? true;
          final similarityThreshold = (input['similarityThreshold'] as num?)?.toDouble() ?? 0.75;

          debugPrint('createRecipe with text length: ${recipeText.length}');

          final createResult = await _mcpService.createRecipe(
            recipeText: recipeText,
            checkDuplicate: checkDuplicate,
            similarityThreshold: similarityThreshold,
          );

          // === 调试日志：打印 MCP 原始返回数据 ===
          debugPrint('=== MCP createRecipe 原始返回数据 ===');
          debugPrint('Success: ${createResult['success']}');
          if (createResult.containsKey('error')) {
            debugPrint('Error: ${createResult['error']}');
          }
          if (createResult.containsKey('recipe')) {
            final recipeData = createResult['recipe'] as Map<String, dynamic>;
            debugPrint('Recipe data keys: ${recipeData.keys.toList()}');
            debugPrint('  - name: ${recipeData['name']}');
            debugPrint('  - category: ${recipeData['category']}');
            debugPrint('  - difficulty: ${recipeData['difficulty']}');
            debugPrint('  - ingredients: ${recipeData['ingredients']}');
            debugPrint('  - steps: ${recipeData['steps']}');
            debugPrint('  - additional_notes type: ${recipeData['additional_notes']?.runtimeType}');
            debugPrint('  - additional_notes: ${recipeData['additional_notes']}');
          }
          debugPrint('=======================================');

          // 提取创建的食谱数据
          if (createResult.containsKey('recipe')) {
            final recipeData = createResult['recipe'] as Map<String, dynamic>;

            // 中文分类到英文的映射
            final categoryMap = {
              '水产': 'aquatic',
              '早餐': 'breakfast',
              '调料': 'condiment',
              '甜品': 'dessert',
              '饮品': 'drink',
              '荤菜': 'meat_dish',
              '半成品加工': 'semi-finished',
              '汤': 'soup',
              '主食': 'staple',
              '素菜': 'vegetable_dish',
            };

            // 获取中文分类名称（MCP 返回的字段名是 category，不是 categoryName）
            final categoryNameFromMCP = recipeData['category'] as String?;
            final categoryId = categoryNameFromMCP != null
                ? (categoryMap[categoryNameFromMCP] ?? 'user_created')
                : 'user_created';

            // 生成 ID 和 hash
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final recipeName = recipeData['name'] as String? ?? '未命名食谱';
            final recipeId = 'ai_${categoryId}_${timestamp.toRadixString(16)}';
            final hash = '$recipeId-$timestamp'.hashCode.abs().toString();

            // 转换 MCP ingredients 格式为我们的格式
            // MCP: {name: "烤肠 6根", text_quantity: "烤肠 6根", ...}
            // 我们需要: {name: "烤肠", text: "烤肠 6根"}
            final mcpIngredients = recipeData['ingredients'] as List<dynamic>? ?? [];
            final ingredients = mcpIngredients.map((item) {
              if (item is Map<String, dynamic>) {
                final textQuantity = item['text_quantity']?.toString() ?? item['name']?.toString() ?? '';
                // 提取食材名称（第一个空格前的部分，或整个文本）
                final firstSpaceIndex = textQuantity.indexOf(' ');
                final name = firstSpaceIndex > 0
                    ? textQuantity.substring(0, firstSpaceIndex)
                    : textQuantity;

                return {
                  'name': name,
                  'text': textQuantity,
                };
              }
              return {'name': '', 'text': item.toString()};
            }).toList();

            // 转换 MCP steps 格式为我们的格式
            // MCP: {step: 1, description: "..."}
            // 我们需要: {description: "..."}
            final mcpSteps = recipeData['steps'] as List<dynamic>? ?? [];
            final steps = mcpSteps.map((item) {
              if (item is Map<String, dynamic>) {
                return {'description': item['description']?.toString() ?? ''};
              }
              return {'description': item.toString()};
            }).toList();

            // 转换 tips/additional_notes（可能是 String 或 List）
            String? tipsText;
            final additionalNotes = recipeData['additional_notes'];
            if (additionalNotes is String) {
              tipsText = additionalNotes;
            } else if (additionalNotes is List) {
              // 如果是列表，合并为字符串
              tipsText = additionalNotes.map((item) => item.toString()).join('\n');
            }

            // 构建完整的食谱数据
            final sanitizedData = <String, dynamic>{
              'id': recipeId,
              'name': recipeName,
              'category': categoryId,
              'categoryName': categoryNameFromMCP ?? '用户创建',
              'difficulty': recipeData['difficulty'] ?? 3,
              'images': recipeData['images'] ?? [],
              'ingredients': ingredients,
              'tools': recipeData['tools'] ?? [],
              'steps': steps,
              'tips': tipsText,
              'warnings': recipeData['warnings'] ?? [],
              'hash': hash,
            };

            debugPrint('=== 清洗后的食谱数据 ===');
            debugPrint('Generated ID: $recipeId');
            debugPrint('Generated hash: $hash');
            debugPrint('Mapped category: $categoryNameFromMCP -> $categoryId');
            debugPrint('Ingredients: ${ingredients.length} items');
            debugPrint('Steps: ${steps.length} items');

            try {
              // 将食谱数据转换为 Recipe 实体
              final recipe = Recipe.fromJson(sanitizedData);

              // 保存到 _createdRecipes 以便在聊天中显示卡片
              setState(() {
                _createdRecipes[recipe.id] = recipe.copyWith(
                  source: RecipeSource.aiGenerated, // 标记为 AI 生成
                );
              });

              // 立即保存到存储（避免切换页面时丢失）
              _saveCreatedRecipes();

              debugPrint('✅ Recipe created and saved: ${recipe.name} (ID: ${recipe.id})');

              // 在返回结果中添加生成的食谱 ID（用于外部收集）
              result = {
                'success': true,
                ...createResult,
                'recipe': {
                  ...sanitizedData,  // 使用清洗后的数据（包含生成的 ID）
                },
              };
            } catch (e, stackTrace) {
              debugPrint('❌ Failed to parse recipe data: $e');
              debugPrint('Stack trace: $stackTrace');
              throw Exception('Failed to parse recipe data: $e');
            }
          } else {
            // 食谱创建失败或没有数据
            result = {
              'success': true,
              ...createResult,
            };
          }
          break;

        default:
          throw Exception('Unknown MCP tool: $cleanToolName');
      }
    } catch (e, stackTrace) {
      debugPrint('MCP tool execution error: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = e.toString();
      result = {
        'success': false,
        'error': e.toString(),
      };
    }

    // 记录工具调用（仅在 debug 模式）
    if (kDebugMode) {
      final duration = DateTime.now().difference(startTime);
      final toolCall = MCPToolCall(
        toolName: cleanToolName,
        timestamp: startTime,
        input: input,
        output: result,
        error: errorMessage,
        duration: duration,
      );

      setState(() {
        _mcpCallHistory.add(toolCall);
        // 只保留最近 50 条记录
        if (_mcpCallHistory.length > 50) {
          _mcpCallHistory.removeAt(0);
        }
      });
    }

    return result;
  }

  /// 解析整数参数（容错处理）
  int _parseIntParam(dynamic value, {required int defaultValue}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    debugPrint('Warning: Could not parse int from $value, using default $defaultValue');
    return defaultValue;
  }

  /// 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 终止流式输出
  void _stopStreaming() {
    setState(() {
      _shouldStopStreaming = true;
      _isLoading = false;
      _isStreaming = false;
    });
    debugPrint('User stopped streaming');
  }

  /// 显示编辑对话框
  void _showEditDialog(BuildContext context, ChatMessage message, int index) {
    final textContent = message.content
        .whereType<TextContent>()
        .map((c) => c.text)
        .join('\n');

    final TextEditingController editController = TextEditingController(text: textContent);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 检查内容是否有改动
          final hasChanged = editController.text.trim() != textContent;

          return AlertDialog(
            title: const Text('编辑消息'),
            content: TextField(
              controller: editController,
              maxLines: null,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '输入消息内容...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                // 内容改变时刷新对话框状态
                setDialogState(() {});
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  editController.dispose();
                  Navigator.pop(dialogContext);
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final newText = editController.text.trim();
                  if (newText.isEmpty) return;

                  // 如果内容没有改动，直接关闭对话框
                  if (!hasChanged) {
                    editController.dispose();
                    Navigator.pop(dialogContext);
                    return;
                  }

                  // 更新消息内容
                  setState(() {
                    _messages[index] = ChatMessage(
                      id: message.id,
                      role: message.role,
                      content: [MessageContent.text(text: newText)],
                      timestamp: message.timestamp,
                      modelId: message.modelId,
                    );
                    // 删除后续所有消息
                    if (index < _messages.length - 1) {
                      _messages.removeRange(index + 1, _messages.length);
                    }
                  });
                  _saveChatHistory();
                  editController.dispose();
                  Navigator.pop(dialogContext);

                  // 如果这是用户消息，自动重新发送
                  if (message.role == MessageRole.user) {
                    _resendMessage(_messages[index]);
                  }
                },
                child: Text(hasChanged ? '发送' : '确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 清空聊天历史
  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空聊天记录'),
        content: const Text('确定要删除所有聊天记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _createdRecipes.clear(); // 同时清空 AI 创建的食谱
              });
              _saveChatHistory();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('聊天记录已清空')),
              );
            },
            child: Text(
              '确定',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示 MCP 调试面板
  void _showMCPDebugPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'MCP 工具调用记录',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_mcpCallHistory.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('清空'),
                        onPressed: () {
                          setState(() {
                            _mcpCallHistory.clear();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 工具调用列表
              Expanded(
                child: _mcpCallHistory.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无工具调用记录',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _mcpCallHistory.length,
                        itemBuilder: (context, index) {
                          final call = _mcpCallHistory[_mcpCallHistory.length - 1 - index]; // 倒序显示
                          return _buildMCPCallCard(call);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建 MCP 工具调用卡片
  Widget _buildMCPCallCard(MCPToolCall call) {
    final hasError = call.error != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(
          hasError ? Icons.error : Icons.check_circle,
          color: hasError ? AppColors.error : Colors.green,
        ),
        title: Text(
          call.toolName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${_formatCallTime(call.timestamp)} · ${call.duration.inMilliseconds}ms',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 输入参数
                const Text(
                  '📥 输入参数',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _formatJson(call.input),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 输出结果
                Text(
                  hasError ? '❌ 错误信息' : '📤 输出结果',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasError ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    hasError ? call.error! : _formatJson(call.output),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: hasError ? Colors.red[900] : Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间（HH:mm:ss）
  String _formatCallTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  /// 格式化 JSON
  String _formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}
