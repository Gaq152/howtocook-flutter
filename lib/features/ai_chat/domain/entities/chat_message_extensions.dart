import 'chat_message.dart';

/// ChatMessage 扩展方法
extension ChatMessageExtensions on ChatMessage {
  /// 创建文本消息
  static ChatMessage text({
    required String id,
    required MessageRole role,
    required String text,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: [MessageContent.text(text: text)],
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// 创建带图片的消息
  static ChatMessage withImages({
    required String id,
    required MessageRole role,
    required String text,
    required List<String> imagePaths,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: [
        MessageContent.text(text: text),
        ...imagePaths.map((path) => MessageContent.image(
          data: '',  // 将在发送时转换为 base64
          localPath: path,
        )),
      ],
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// 获取文本内容（拼接所有文本）
  String get textContent {
    return content
        .whereType<TextContent>()
        .map((c) => c.text)
        .join('\n');
  }

  /// 获取图片路径列表
  List<String> get imagePaths {
    return content
        .whereType<ImageContent>()
        .where((c) => c.localPath != null)
        .map((c) => c.localPath!)
        .toList();
  }

  /// 是否有图片
  bool get hasImages {
    return content.any((c) => c is ImageContent);
  }
}
