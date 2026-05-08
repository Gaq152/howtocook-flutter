import 'dart:io';
import 'dart:async'; // 用于 scheduleMicrotask
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 用于 kDebugMode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../sync/infrastructure/bundled_data_loader.dart';
import '../../../recipe/domain/entities/recipe.dart';
import '../../application/providers/ai_providers.dart';
import '../../domain/entities/ai_model_config.dart';
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
  String _streamingReasoningText = ''; // 流式思考内容
  bool _shouldStopStreaming = false;
  String? _selectedImagePath;
  List<Map<String, dynamic>>? _mcpTools;
  // 新创建的食谱（用于在聊天中显示卡片和跳转到预览页面）
  final Map<String, Recipe> _createdRecipes = {};
  // MCP 工具调用历史（仅 debug 模式）
  final List<MCPToolCall> _mcpCallHistory = [];

  // 深度思考开关
  bool _enableThinking = false;

  // System Prompt（根据模型能力动态生成）
  String _buildSystemPrompt({required bool supportsTools}) {
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

    // 如果模型不支持工具调用，返回简化版提示词
    if (!supportsTools) {
      return '''你是一个专业的烹饪助手，提供烹饪相关的建议和帮助。

当前时间信息：$dateStr

重要提示：
⚠️ 当前模型不支持使用MCP工具获取菜谱数据库信息。如果用户需要查询具体菜谱、食材、做法等详细信息，请建议用户：
1. 切换到支持工具调用的模型（如 Claude 系列模型、DeepSeek V4 等）
2. 或者直接在应用的菜谱页面中浏览和搜索

你可以：
- 提供通用的烹饪建议和技巧
- 解答烹饪相关的问题
- 进行正常的对话交流
- 根据当前时间（${now.month}月，$timeOfDay）给出适合的饮食建议

但无法：
- 直接查询菜谱数据库
- 获取具体菜谱的详细做法
- 创建新食谱''';
    }

    // 如果模型支持工具调用，返回完整版提示词（包含MCP工具说明）
    return '''你是一个专业的烹饪助手，可以访问"程序员做饭指南"的完整菜谱数据库。

当前时间信息：$dateStr

重要规则：
1. **优先使用MCP工具查询数据**：当用户询问菜谱、食材、做法等问题时，务必先调用相应的MCP工具获取数据
2. **基于工具结果自然回答**：获取到工具数据后，用自然语言整理并呈现给用户，不要把原始JSON或工具返回的原文直接输出
3. **补充专业建议**：在呈现菜谱内容后，可以添加烹饪技巧、注意事项等补充说明
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

      // 转换工具格式：MCP 使用 inputSchema，Claude API 需要 input_schema
      final convertedTools = tools.map((tool) {
        final converted = Map<String, dynamic>.from(tool);
        if (converted.containsKey('inputSchema')) {
          converted['input_schema'] = converted.remove('inputSchema');
        }
        return converted;
      }).toList();

      setState(() {
        _mcpTools = convertedTools;
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
      final enableThinking = await hiveService.getSetting(
        'enable_thinking',
        defaultValue: false,
      );

      setState(() {
        _enableThinking = enableThinking as bool;
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

  String? _buildFinalReasoning(StringBuffer accumulated, String? current) {
    if (accumulated.isEmpty && (current == null || current.isEmpty)) return null;
    if (accumulated.isEmpty) return current;
    if (current == null || current.isEmpty) return accumulated.toString();
    return '${accumulated.toString()}\n\n$current';
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('小厨', style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            _buildModelSelector(),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空聊天记录',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
      // MCP 调试悬浮按钮（仅 debug 模式）
      floatingActionButton: kDebugMode && _mcpCallHistory.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showMCPDebugPanel,
              tooltip: 'MCP 调试面板',
              backgroundColor: AppColors.warning,
              child: Badge(
                label: Text('${_mcpCallHistory.length}'),
                backgroundColor: AppColors.error,
                textColor: AppColors.surface,
                child: const Icon(Icons.bug_report),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  /// 构建模型选择器
  Widget _buildModelSelector() {
    final selectedModel = ref.watch(selectedModelConfigProvider);
    final modelsAsync = ref.watch(availableModelsProvider);

    return modelsAsync.when(
      loading: () => _buildModelSelectorContainer(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '加载模型...',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
      error: (error, _) => _buildModelSelectorContainer(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.invalidate(availableModelsProvider),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                '加载失败，点击重试',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
      data: (models) {
        if (models.isEmpty) {
          return _buildModelSelectorContainer(
            Text(
              '暂无模型',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          );
        }

        // 查找当前选中模型的最新版本
        final matchingModel = models.where((model) => model.id == selectedModel.id).firstOrNull;

        if (matchingModel != null) {
          // 找到匹配的模型，检查是否需要更新（对象可能已被编辑）
          if (matchingModel != selectedModel) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedModelConfigProvider.notifier).state = matchingModel;
            });
          }
        } else {
          // 没有找到匹配的模型，回退到第一个模型
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedModelConfigProvider.notifier).state = models.first;
          });
        }

        final currentValue = matchingModel?.id ?? models.first.id;

        return _buildModelSelectorContainer(
          DropdownButton<String>(
            value: currentValue,
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            items: models.map((model) {
              return DropdownMenuItem(
                value: model.id,
                child: Text(model.displayName),
              );
            }).toList(),
            onChanged: (modelId) {
              if (modelId == null) return;
              final nextModel = models.firstWhere((model) => model.id == modelId);
              ref.read(selectedModelConfigProvider.notifier).state = nextModel;
            },
          ),
        );
      },
    );
  }

  /// 构建模型选择器容器
  Widget _buildModelSelectorContainer(Widget child) {
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
      child: child,
    );
  }

  /// 解析当前有效的模型
  AIModelConfig _resolveActiveModel() {
    final selected = ref.read(selectedModelConfigProvider);
    final modelsAsyncValue = ref.read(availableModelsProvider);

    // 只有当 provider 有具体数据时，才验证选择是否有效
    // 在 loading/error 状态下，继续使用当前选择
    return modelsAsyncValue.maybeWhen(
      data: (models) {
        if (models.isEmpty) {
          return selected;
        }

        final hasSelected = models.any(
          (model) => model.id == selected.id && model.isEnabled,
        );

        if (hasSelected) {
          return selected;
        }

        // 只有确认当前选择不存在时才回退
        final fallback = models.firstWhere(
          (model) => model.isEnabled,
          orElse: () => models.first,
        );

        if (fallback.id != selected.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedModelConfigProvider.notifier).state = fallback;
          });
        }

        return fallback;
      },
      // loading/error 状态：保持当前选择，不回退
      orElse: () => selected,
    );
  }

  /// 构建深度思考开关
  Widget _buildThinkingToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _enableThinking = !_enableThinking;
        });
        _saveSetting('enable_thinking', _enableThinking);

        AppSnackBar.show(
          context,
          _enableThinking ? '已开启深度思考' : '已关闭深度思考',
          duration: const Duration(seconds: 1),
          bottomOffset: AppSnackBar.kChatBottomOffset,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _enableThinking
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.textSecondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _enableThinking
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.textSecondary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology,
              size: 16,
              color: _enableThinking ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '深度思考',
              style: AppTextStyles.bodySmall.copyWith(
                color: _enableThinking ? AppColors.primary : AppColors.textSecondary,
                fontWeight: _enableThinking ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
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
              Icons.auto_awesome,
              color: AppColors.surface,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '小厨',
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
    // 获取所有可用模型（包括用户自定义模型）用于显示模型名称
    final availableModelsAsync = ref.watch(availableModelsProvider);
    final builtinModels = AIServiceFactory.getBuiltinModels();

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
        // 优先从 availableModelsProvider 查找（包含用户自定义模型）
        // 找不到时回退到 modelId 本身
        String? modelName;
        if (message.role == MessageRole.assistant && message.modelId != null) {
          final models = availableModelsAsync.maybeWhen(
            data: (items) => items,
            orElse: () => builtinModels,
          );
          final model = models.where((m) => m.id == message.modelId).firstOrNull;
          // 找不到模型时，显示 modelId 作为后备
          modelName = model?.displayName ?? message.modelId;
        }

        // 判断这是否是最后一条正在流式显示的消息
        final isLastStreaming = index == _messages.length - 1 && _isStreaming;
        final isLastMessage = index == _messages.length - 1;

        return MessageBubble(
          message: message,
          modelName: modelName,
          isStreaming: isLastStreaming,
          streamingText: isLastStreaming ? _streamingText : null,
          streamingReasoningText: isLastMessage && _streamingReasoningText.isNotEmpty
              ? _streamingReasoningText
              : null,
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
            AppSnackBar.show(
              context,
              '消息已删除',
              bottomOffset: AppSnackBar.kChatBottomOffset,
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
          color: AppColors.surfaceAlt,
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
    final hasKeyboard = MediaQuery.of(context).viewInsets.bottom > 0;
    final double extraBottom = hasKeyboard ? 8.0 : 16.0 + kFloatingNavBarHeight;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, extraBottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具栏
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _buildThinkingToggle(),
              ],
            ),
          ),

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
                              color: AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.surface,
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
                  color: _isLoading ? AppColors.textDisabled : null,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isLoading ? Icons.stop : Icons.send,
                    color: AppColors.surface,
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
        AppSnackBar.show(
          context,
          '选择图片失败: $e',
          bottomOffset: AppSnackBar.kChatBottomOffset,
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
      // 获取当前有效的模型，应用聊天页的 thinking 开关覆盖
      final baseModel = _resolveActiveModel();
      final currentModel = baseModel.copyWith(
        capabilities: baseModel.capabilities.copyWith(
          enableThinking: _enableThinking,
        ),
      );
      final aiService = AIServiceFactory.create(currentModel);

      // 准备消息历史（不包括刚添加的临时消息）
      // 只保留最近3轮对话（6条消息：3条用户+3条AI），避免token超限
      var allHistory = _messages.sublist(0, _messages.length - 1);

      // 处理图片：将本地路径转换为 base64
      final processedHistory = <ChatMessage>[];
      for (var msg in allHistory) {
        var hasImage = false;
        final processedContent = <MessageContent>[];

        for (var content in msg.content) {
          if (content is ImageContent && content.data.isEmpty && content.localPath != null) {
            try {
              final imageFile = File(content.localPath!);
              final imageBytes = await imageFile.readAsBytes();
              final base64Image = base64Encode(imageBytes);

              // 添加带 base64 数据的图片内容
              processedContent.add(MessageContent.image(
                data: base64Image,
                mimeType: content.mimeType ?? 'image/jpeg',
                localPath: content.localPath,
              ));
              hasImage = true;
            } catch (e) {
              debugPrint('❌ Failed to read image file: $e');
              // 即使失败也添加原内容
              processedContent.add(content);
            }
          } else {
            processedContent.add(content);
          }
        }

        // 如果有图片被处理，创建新的消息对象
        if (hasImage) {
          processedHistory.add(ChatMessage(
            id: msg.id,
            role: msg.role,
            content: processedContent,
            timestamp: msg.timestamp,
            modelId: msg.modelId,
            reasoningContent: msg.reasoningContent,
            createdRecipeIds: msg.createdRecipeIds,
          ));
        } else {
          processedHistory.add(msg);
        }
      }

      allHistory = processedHistory;

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

      // 检查模型是否支持工具调用（在生成 system prompt 之前）
      final modelInfo = await aiService.getModelInfo();
      final supportsTools = modelInfo['supports_tools'] == true;
      final shouldUseMcpTools = _mcpTools != null && _mcpTools!.isNotEmpty && supportsTools;

      // 在第一条消息前添加 system prompt（根据模型能力动态生成）
      var history = [
        ChatMessage(
          id: 'system',
          role: MessageRole.system,
          content: [MessageContent.text(text: _buildSystemPrompt(supportsTools: supportsTools))],
          timestamp: DateTime.now(),
        ),
        ...recentMessages,
      ];

      // MCP 工具调用循环
      if (shouldUseMcpTools) {
        debugPrint('Starting MCP tool calling loop with ${_mcpTools!.length} tools');

        // 使用非流式API进行工具调用循环（最多10轮）
        var toolCallCount = 0;
        const maxToolCalls = 10;
        // 收集本次对话创建的食谱ID列表
        final createdRecipeIds = <String>[];
        // 跨轮次累积文本（AI 先说话再调工具的场景）
        final accumulatedText = StringBuffer();
        // 跨轮次累积思考内容
        final accumulatedReasoning = StringBuffer();

        setState(() {
          _streamingReasoningText = '';
        });

        while (toolCallCount < maxToolCalls) {
          toolCallCount++;
          debugPrint('Tool call iteration $toolCallCount');

          final streamingTextBuffer = StringBuffer();

          final response = await aiService.sendMessageSync(
            messages: history,
            tools: _mcpTools,
            onTextChunk: (chunk) {
              streamingTextBuffer.write(chunk);
              if (mounted) {
                scheduleMicrotask(() {
                  if (mounted) {
                    setState(() {
                      final lastIndex = _messages.length - 1;
                      final display = accumulatedText.isEmpty
                          ? streamingTextBuffer.toString()
                          : '${accumulatedText.toString()}\n\n${streamingTextBuffer.toString()}';
                      _messages[lastIndex] = ChatMessage(
                        id: tempAssistantMessage.id,
                        role: MessageRole.assistant,
                        content: [MessageContent.text(text: display)],
                        timestamp: tempAssistantMessage.timestamp,
                        modelId: currentModel.id,
                      );
                    });
                  }
                });
              }
            },
            onReasoningContent: (value) {
              if (mounted) {
                setState(() {
                  // value 是当前轮的累积思考，拼接之前轮次的
                  _streamingReasoningText = accumulatedReasoning.isEmpty
                      ? value
                      : '${accumulatedReasoning.toString()}\n\n$value';
                });
              }
            },
          );

          debugPrint('📨 Got response with ${response.content.length} content items');

          // 打印所有 content 类型
          for (var i = 0; i < response.content.length; i++) {
            final content = response.content[i];
            if (content is TextContent) {
              debugPrint('📨 Content[$i]: Text (${content.text.length} chars)');
            } else if (content is ToolUseContent) {
              debugPrint('📨 Content[$i]: ToolUse (name: ${content.name})');
            } else {
              debugPrint('📨 Content[$i]: ${content.runtimeType}');
            }
          }

          // 检查是否有 tool_calls
          final hasToolCalls = response.content.any((c) => c is ToolUseContent);

          if (!hasToolCalls) {
            debugPrint('📨 No tool calls, displaying final response');
            // 如果有前置累积文本，把它拼到最终文本内容前面
            List<MessageContent> finalContent = response.content;
            if (accumulatedText.isNotEmpty) {
              final responseText = response.content
                  .whereType<TextContent>()
                  .map((c) => c.text)
                  .join();
              final merged =
                  '${accumulatedText.toString()}\n\n$responseText'.trim();
              finalContent = [
                MessageContent.text(text: merged),
                ...response.content.where((c) => c is! TextContent),
              ];
            }
            setState(() {
              final lastIndex = _messages.length - 1;
              _messages[lastIndex] = ChatMessage(
                id: tempAssistantMessage.id,
                role: MessageRole.assistant,
                content: finalContent,
                timestamp: tempAssistantMessage.timestamp,
                modelId: currentModel.id,
                reasoningContent: _buildFinalReasoning(accumulatedReasoning, response.reasoningContent),
                createdRecipeIds: createdRecipeIds.isNotEmpty ? createdRecipeIds : null,
              );
              _isLoading = false;
              _streamingReasoningText = '';
            });
            break;
          }

          // 有工具调用，执行工具
          debugPrint('Found tool calls, executing...');
          // 把本轮文本追加到跨轮累积区
          final roundText = streamingTextBuffer.toString();
          if (roundText.isNotEmpty) {
            if (accumulatedText.isNotEmpty) accumulatedText.write('\n\n');
            accumulatedText.write(roundText);
          }
          // 把本轮思考内容追加到跨轮累积区
          if (response.reasoningContent != null && response.reasoningContent!.isNotEmpty) {
            if (accumulatedReasoning.isNotEmpty) accumulatedReasoning.write('\n\n');
            accumulatedReasoning.write(response.reasoningContent);
          }
          // 更新 UI 显示工具调用状态（保留前置文本）
          setState(() {
            final lastIndex = _messages.length - 1;
            final statusText = accumulatedText.isEmpty
                ? 'AI 正在调用工具查询数据...'
                : '${accumulatedText.toString()}\n\nAI 正在调用工具查询数据...';
            _messages[lastIndex] = ChatMessage(
              id: tempAssistantMessage.id,
              role: MessageRole.assistant,
              content: [MessageContent.text(text: statusText)],
              timestamp: tempAssistantMessage.timestamp,
            );
          });          final toolResults = <MessageContent>[];

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
            response,
            ...toolResultMessages,
          ];

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
              modelId: currentModel.id, // 保存使用的模型ID
              createdRecipeIds: createdRecipeIds.isNotEmpty ? createdRecipeIds : null,
            );
            _isLoading = false;
            _streamingReasoningText = '';
          });
        }
      } else {
        // 没有可用的 MCP 工具或模型不支持工具调用
        // 检查模型是否启用流式输出
        final enableStreaming = currentModel.capabilities.enableStreaming;

        if (enableStreaming) {
          // 使用流式响应
          debugPrint('Using streaming response (streaming enabled)');

          // 开启流式显示状态
          setState(() {
            _isStreaming = true;
            _streamingText = '';
            _streamingReasoningText = '';
            _shouldStopStreaming = false;
          });

          String? reasoningContent;
          final responseStream = aiService.sendMessage(
            messages: history,
            onReasoningContent: (value) {
              reasoningContent = value;
              // 更新流式思考内容（实时显示）
              setState(() {
                _streamingReasoningText = value;
              });
            },
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
          }

          debugPrint('Streaming complete. Received $chunkCount chunks, total ${responseBuffer.length} characters');

          // 检查是否包含 XML 格式的工具调用（思考链模式）
          final responseText = responseBuffer.toString();
          final xmlToolCalls = _parseXmlToolCalls(responseText);

          if (xmlToolCalls.isNotEmpty) {
            debugPrint('🔧 Found ${xmlToolCalls.length} XML tool calls in streaming response');

            // 关闭流式状态，但保持加载状态
            setState(() {
              _isStreaming = false;
            });

            // 收集创建的菜谱 ID
            final createdRecipeIds = <String>[];

            // 执行所有工具调用并收集结果
            final toolResultsXml = StringBuffer();
            for (final toolCall in xmlToolCalls) {
              final toolUseId = toolCall['id'] as String;
              final toolName = toolCall['name'] as String;
              final toolArgs = toolCall['arguments'] as Map<String, dynamic>;

              debugPrint('🔧 Executing XML tool: $toolName (id: $toolUseId)');
              try {
                final result = await _executeMCPTool(toolName, toolArgs);
                toolResultsXml.writeln(_formatToolResultAsXml(toolUseId, toolName, result));

                // 如果是 createRecipe 工具且成功，收集创建的食谱 ID
                final cleanToolName = toolName.replaceFirst('mcp_howtocook_', '');
                if (cleanToolName == 'createRecipe' &&
                    result['success'] == true &&
                    result.containsKey('recipe')) {
                  final recipeData = result['recipe'] as Map<String, dynamic>?;
                  if (recipeData != null && recipeData.containsKey('id')) {
                    createdRecipeIds.add(recipeData['id'] as String);
                  }
                }
              } catch (e) {
                debugPrint('❌ XML tool execution failed: $e');
                toolResultsXml.writeln(_formatToolResultAsXml(toolUseId, toolName, {'error': e.toString()}));
              }
            }

            // 移除原文本中的工具调用标签，保留其他内容
            final cleanResponseText = _removeXmlToolCalls(responseText);

            // 更新历史，添加 AI 响应和工具结果
            history = [
              ...history,
              ChatMessage(
                id: DateTime.now().toString(),
                role: MessageRole.assistant,
                content: [MessageContent.text(text: responseText)],
                timestamp: DateTime.now(),
                reasoningContent: reasoningContent,
              ),
              ChatMessage(
                id: DateTime.now().toString(),
                role: MessageRole.user,
                content: [MessageContent.text(text: toolResultsXml.toString())],
                timestamp: DateTime.now(),
              ),
            ];

            // 发送下一轮请求让 AI 处理工具结果
            debugPrint('🔧 Sending tool results back to AI...');
            final nextResponseBuffer = StringBuffer();
            String? nextReasoningContent;

            setState(() {
              _isStreaming = true;
              _streamingText = cleanResponseText.isNotEmpty ? '$cleanResponseText\n\n' : '';
              _streamingReasoningText = '';
            });

            final nextStream = aiService.sendMessage(
              messages: history,
              onReasoningContent: (value) {
                nextReasoningContent = value;
                setState(() {
                  _streamingReasoningText = value;
                });
              },
            );

            await for (final chunk in nextStream) {
              if (_shouldStopStreaming) break;
              nextResponseBuffer.write(chunk);
              setState(() {
                _streamingText = cleanResponseText.isNotEmpty
                    ? '$cleanResponseText\n\n${nextResponseBuffer.toString()}'
                    : nextResponseBuffer.toString();
              });
            }

            // 最终响应
            final finalText = cleanResponseText.isNotEmpty
                ? '$cleanResponseText\n\n${nextResponseBuffer.toString()}'
                : nextResponseBuffer.toString();

            setState(() {
              _isStreaming = false;
              _isLoading = false;
              final lastIndex = _messages.length - 1;
              _messages[lastIndex] = ChatMessage(
                id: tempAssistantMessage.id,
                role: MessageRole.assistant,
                content: [MessageContent.text(text: finalText)],
                timestamp: tempAssistantMessage.timestamp,
                modelId: currentModel.id,
                reasoningContent: reasoningContent ?? nextReasoningContent,
                createdRecipeIds: createdRecipeIds.isNotEmpty ? createdRecipeIds : null,
              );
            });
          } else {
            // 没有工具调用，直接显示响应
            setState(() {
              _isStreaming = false;
              _isLoading = false;
              final lastIndex = _messages.length - 1;
              _messages[lastIndex] = ChatMessage(
                id: tempAssistantMessage.id,
                role: MessageRole.assistant,
                content: [MessageContent.text(text: responseBuffer.toString())],
                timestamp: tempAssistantMessage.timestamp,
                modelId: currentModel.id,
                reasoningContent: (reasoningContent != null && reasoningContent!.isNotEmpty)
                    ? reasoningContent
                    : null,
              );
            });
          }
        } else {
          // 使用非流式响应（等待完整回复）
          debugPrint('Using non-streaming response (streaming disabled)');

          final response = await aiService.sendMessageSync(
            messages: history,
          );

          // 更新最终消息（使用响应中的reasoning内容）
          setState(() {
            _isLoading = false;
            final lastIndex = _messages.length - 1;
            _messages[lastIndex] = ChatMessage(
              id: tempAssistantMessage.id,
              role: MessageRole.assistant,
              content: response.content,
              timestamp: tempAssistantMessage.timestamp,
              modelId: currentModel.id, // 保存使用的模型ID
              reasoningContent: response.reasoningContent,
            );
          });
        }
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
        AppSnackBar.show(
          context,
          '发送失败: $e',
          bottomOffset: AppSnackBar.kChatBottomOffset,
        );
      }
    }
  }

  /// 解析 XML 格式的工具调用（CherryStudio 风格）
  ///
  /// 从响应文本中提取 `<tool_use>` 标签内容
  /// 返回工具调用列表，每个元素包含 id, name 和 arguments
  List<Map<String, dynamic>> _parseXmlToolCalls(String text) {
    final toolCalls = <Map<String, dynamic>>[];

    // 匹配 <tool_use>...</tool_use> 块（支持可选的 <id> 标签）
    final toolUseRegex = RegExp(
      r'<tool_use>\s*(?:<id>([^<]*)</id>\s*)?<name>([^<]+)</name>\s*<arguments>([^<]*)</arguments>\s*</tool_use>',
      multiLine: true,
      dotAll: true,
    );

    for (final match in toolUseRegex.allMatches(text)) {
      final idFromXml = match.group(1)?.trim();
      final name = match.group(2)?.trim();
      final argumentsStr = match.group(3)?.trim();

      if (name != null && name.isNotEmpty) {
        // 生成稳定的 tool_use_id：如果 XML 中有 id 则使用，否则生成一个
        final toolUseId = (idFromXml != null && idFromXml.isNotEmpty)
            ? idFromXml
            : 'xml-${DateTime.now().microsecondsSinceEpoch}-${toolCalls.length}';

        Map<String, dynamic> arguments = {};
        if (argumentsStr != null && argumentsStr.isNotEmpty) {
          try {
            arguments = jsonDecode(argumentsStr) as Map<String, dynamic>;
          } catch (e) {
            debugPrint('⚠️ Failed to parse tool arguments JSON: $e');
          }
        }

        toolCalls.add({
          'id': toolUseId,
          'name': name,
          'arguments': arguments,
        });
        debugPrint('🔧 Parsed XML tool call: id=$toolUseId, name=$name, arguments=$arguments');
      }
    }

    return toolCalls;
  }

  /// 移除响应文本中的 XML 工具调用标签
  ///
  /// 保留工具调用之外的正常文本内容
  String _removeXmlToolCalls(String text) {
    // 移除 <tool_use>...</tool_use> 块
    return text.replaceAll(
      RegExp(r'<tool_use>\s*<name>[^<]+</name>\s*<arguments>[^<]*</arguments>\s*</tool_use>', multiLine: true, dotAll: true),
      '',
    ).trim();
  }

  /// 格式化工具结果为 XML 格式（包含 tool_use_id 以便 AI 关联调用和结果）
  String _formatToolResultAsXml(String toolUseId, String toolName, Map<String, dynamic> result) {
    return '''<tool_use_result>
  <id>$toolUseId</id>
  <name>$toolName</name>
  <result>${jsonEncode(result)}</result>
</tool_use_result>''';
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

    debugPrint('🔧 ===== MCP Tool Call Start =====');
    debugPrint('🔧 Tool: $cleanToolName');
    debugPrint('🔧 Input: $input');

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
              '调味品': 'condiment',
              '甜品': 'dessert',
              '饮料': 'drink',
              '饮品': 'drink',
              '荤菜': 'meat_dish',
              '肉类': 'meat_dish',
              '半成品': 'semi-finished',
              '半成品加工': 'semi-finished',
              '汤粥': 'soup',
              '汤': 'soup',
              '汤羹': 'soup',
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
    final duration = DateTime.now().difference(startTime);

    debugPrint('🔧 ===== MCP Tool Call End =====');
    debugPrint('🔧 Tool: $cleanToolName');
    debugPrint('🔧 Duration: ${duration.inMilliseconds}ms');
    debugPrint('🔧 Success: ${result['success']}');
    if (errorMessage != null) {
      debugPrint('🔧 Error: $errorMessage');
    }
    debugPrint('🔧 Result keys: ${result.keys.toList()}');
    debugPrint('🔧 ==============================');

    if (kDebugMode) {
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
    bool isDisposed = false; // 标记 controller 是否已释放

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 检查内容是否有改动（安全检查 controller 状态）
          final hasChanged = !isDisposed && editController.text.trim() != textContent;

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
                // 内容改变时刷新对话框状态（仅当 controller 未释放）
                if (!isDisposed && mounted) {
                  setDialogState(() {});
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 取消：先标记已释放，再关闭对话框，最后 dispose
                  isDisposed = true;
                  Navigator.pop(dialogContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    editController.dispose();
                  });
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final newText = editController.text.trim();
                  if (newText.isEmpty) return;

                  // 如果内容没有改动，直接关闭对话框
                  if (!hasChanged) {
                    isDisposed = true;
                    Navigator.pop(dialogContext);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      editController.dispose();
                    });
                    return;
                  }

                  // 标记 controller 已释放，避免后续使用
                  isDisposed = true;

                  // 先关闭对话框
                  Navigator.pop(dialogContext);

                  // 在下一帧释放 controller（确保对话框动画完成）
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    editController.dispose();
                  });

                  // 等待对话框动画完成
                  await Future.delayed(const Duration(milliseconds: 150));

                  // 检查 widget 是否仍然挂载
                  if (!mounted) return;

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

                  // 如果这是用户消息，延迟重新发送（避免 setState 冲突）
                  if (message.role == MessageRole.user) {
                    scheduleMicrotask(() {
                      if (mounted) {
                        _resendMessage(_messages[index]);
                      }
                    });
                  }
                },
                child: Text(hasChanged ? '发送' : '确定'),
              ),
            ],
          );
        },
      ),
    );
    // 移除 whenComplete，改为在按钮回调中处理 dispose
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

              AppSnackBar.show(
                context,
                '聊天记录已清空',
                bottomOffset: AppSnackBar.kChatBottomOffset,
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
            color: AppColors.surface,
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
                      color: AppColors.divider,
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
                            color: AppColors.textDisabled,
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
          color: hasError ? AppColors.error : AppColors.success,
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
            color: AppColors.textDisabled,
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
                    color: AppColors.surfaceAlt,
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
                    color: hasError ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    hasError ? call.error! : _formatJson(call.output),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: hasError ? AppColors.error : AppColors.success,
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
