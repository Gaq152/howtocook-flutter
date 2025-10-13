import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/chat_message.dart';
import '../../infrastructure/services/recipe_recognizer.dart';
import 'recipe_card_widget.dart';

/// 消息气泡组件
///
/// 用于显示聊天消息，支持：
/// - 左右布局（用户消息靠右，AI消息靠左）
/// - Markdown 渲染
/// - 图片展示
/// - 时间戳显示
/// - 操作按钮（复制、重试、编辑、删除）
/// - 模型头像显示
/// - 流式打字效果
/// - 菜谱卡片展示
class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;
  final String? modelName;
  final bool isStreaming;
  final String? streamingText;
  final RecipeRecognizer? recipeRecognizer;
  final Function(String recipeId)? onRecipeTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onCopy,
    this.onRetry,
    this.onEdit,
    this.modelName,
    this.isStreaming = false,
    this.streamingText,
    this.recipeRecognizer,
    this.onRecipeTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  List<RecipeCardData>? _recognizedRecipes;

  @override
  void initState() {
    super.initState();
    _recognizeRecipes();
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果消息内容变化或流式文本变化，重新识别菜谱
    if (widget.message.content != oldWidget.message.content ||
        widget.streamingText != oldWidget.streamingText) {
      _recognizeRecipes();
    }
  }

  /// 识别消息中的菜谱
  Future<void> _recognizeRecipes() async {
    // 只对 AI 消息进行菜谱识别
    if (widget.message.role != MessageRole.assistant) {
      return;
    }

    // 检查是否有 RecipeRecognizer
    if (widget.recipeRecognizer == null) {
      return;
    }

    // 获取显示文本
    final displayText = widget.isStreaming && widget.streamingText != null
        ? widget.streamingText!
        : widget.message.content
            .whereType<TextContent>()
            .map((c) => c.text)
            .join('\n');

    if (displayText.isEmpty) {
      return;
    }

    try {
      final recipes = await widget.recipeRecognizer!.extractRecipesFromText(displayText);
      if (mounted) {
        setState(() {
          _recognizedRecipes = recipes;
        });
      }
    } catch (e) {
      // 识别失败不影响消息显示
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;

    // 获取显示文本：优先使用流式文本，否则使用消息内容
    final displayText = widget.isStreaming && widget.streamingText != null
        ? widget.streamingText!
        : widget.message.content
            .whereType<TextContent>()
            .map((c) => c.text)
            .join('\n');

    // 提取文本内容用于复制
    final textContent = displayText;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI头像（左侧）
            if (!isUser) ...[
              _buildAvatar(isUser),
              const SizedBox(width: 8),
            ],

            // 消息内容
            Flexible(
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 消息气泡
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16).copyWith(
                        topRight: isUser ? const Radius.circular(4) : null,
                        topLeft: isUser ? null : const Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 如果是流式显示，直接显示文本
                        if (widget.isStreaming && widget.streamingText != null)
                          _buildTextContent(widget.streamingText!, isUser)
                        else
                          // 否则渲染所有内容
                          ...widget.message.content.map((content) => content.when(
                            text: (text) => _buildTextContent(text, isUser),
                            image: (data, mimeType, localPath) => _buildImageContent(localPath ?? data, isUser),
                            toolUse: (toolUseId, name, input) => _buildToolUseContent(name, isUser),
                            toolResult: (toolUseId, result) => _buildToolResultContent(result, isUser),
                          )),
                      ],
                    ),
                  ),

                  // 菜谱卡片（仅AI消息）
                  if (!isUser && _recognizedRecipes != null && _recognizedRecipes!.isNotEmpty)
                    ..._recognizedRecipes!.map((recipe) => RecipeCardWidget(
                      recipe: recipe,
                      onTap: widget.onRecipeTap != null
                          ? () => widget.onRecipeTap!(recipe.id)
                          : null,
                    )),

                  // 时间戳和模型名称
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(widget.message.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!isUser && widget.modelName != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· ${widget.modelName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 操作按钮栏（底部持久显示）
                  if (!widget.isStreaming)
                    _buildActionBar(context, textContent, isUser),
                ],
              ),
            ),

            // 用户头像（右侧）
            if (isUser) ...[
              const SizedBox(width: 8),
              _buildAvatar(isUser),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: isUser ? Colors.white : AppColors.textSecondary,
        size: 20,
      ),
    );
  }

  /// 构建操作按钮栏
  Widget _buildActionBar(BuildContext context, String textContent, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 复制按钮
          if (textContent.isNotEmpty)
            _buildIconButton(
              icon: Icons.content_copy,
              tooltip: '复制',
              onTap: () {
                if (widget.onCopy != null) {
                  widget.onCopy!();
                } else {
                  Clipboard.setData(ClipboardData(text: textContent));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
                  );
                }
              },
            ),

          // 重试按钮（仅AI消息）
          if (!isUser && widget.onRetry != null)
            _buildIconButton(
              icon: Icons.refresh,
              tooltip: '重试',
              onTap: widget.onRetry!,
            ),

          // 编辑按钮（仅用户消息）
          if (isUser && widget.onEdit != null)
            _buildIconButton(
              icon: Icons.edit_outlined,
              tooltip: '编辑',
              onTap: widget.onEdit!,
            ),

          // 删除按钮
          if (widget.onDelete != null)
            _buildIconButton(
              icon: Icons.delete_outline,
              tooltip: '删除',
              onTap: widget.onDelete!,
              color: AppColors.error,
            ),
        ],
      ),
    );
  }

  /// 构建图标按钮
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppColors.textSecondary;
    return IconButton(
      icon: Icon(icon, size: 18),
      color: iconColor,
      tooltip: tooltip,
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      onPressed: onTap,
    );
  }

  /// 构建文本内容
  Widget _buildTextContent(String text, bool isUser) {
    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        code: TextStyle(
          backgroundColor: isUser
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey[300],
          color: isUser ? Colors.white : AppColors.textPrimary,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: isUser
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        h1: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        listBullet: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
        ),
        tableBody: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
        ),
        blockquote: TextStyle(
          color: isUser ? Colors.white70 : AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        strong: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        em: TextStyle(
          color: isUser ? Colors.white : AppColors.textPrimary,
          fontStyle: FontStyle.italic,
        ),
      ),
      onTapLink: (text, url, title) {
        // 处理链接点击（如果需要）
        if (url != null) {
          debugPrint('Link tapped: $url');
        }
      },
    );
  }

  /// 构建图片内容
  Widget _buildImageContent(String imagePath, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imagePath,
          width: 200,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 150,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 48),
            );
          },
        ),
      ),
    );
  }

  /// 构建工具使用内容
  Widget _buildToolUseContent(String toolName, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings,
            size: 16,
            color: isUser ? Colors.white70 : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '调用工具: $toolName',
            style: TextStyle(
              color: isUser ? Colors.white70 : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建工具结果内容
  Widget _buildToolResultContent(Map<String, dynamic> result, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '工具结果: ${result.toString()}',
        style: TextStyle(
          color: isUser ? Colors.white70 : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 格式化时间（HH:mm）
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
