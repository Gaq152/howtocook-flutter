import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../domain/entities/recipe.dart';
import '../../application/providers/recipe_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

/// 菜谱创建页面
///
/// 支持从零创建新菜谱
class RecipeCreateScreen extends ConsumerStatefulWidget {
  const RecipeCreateScreen({super.key});

  @override
  ConsumerState<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends ConsumerState<RecipeCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  late TextEditingController _nameController;
  late TextEditingController _pasteController;

  // 数据
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isParsing = false;

  // 编辑状态
  String _selectedCategory = 'meat_dish'; // 默认分类
  int _selectedDifficulty = 1; // 默认难度
  List<String> _ingredientTexts = [];
  List<String> _stepDescriptions = [];
  List<String> _tools = [];
  String? _tips;
  List<String> _warnings = [];
  List<String> _images = [];

  // 可用的分类列表
  final List<Map<String, String>> _categories = [
    {'value': 'meat_dish', 'label': '肉类'},
    {'value': 'vegetable_dish', 'label': '素菜'},
    {'value': 'aquatic', 'label': '水产'},
    {'value': 'breakfast', 'label': '早餐'},
    {'value': 'staple', 'label': '主食'},
    {'value': 'soup', 'label': '汤羹'},
    {'value': 'dessert', 'label': '甜品'},
    {'value': 'drink', 'label': '饮品'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _pasteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建菜谱'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveRecipe,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 粘贴导入区域（最顶部）
            _buildPasteImportSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildIngredientsSection(),
            const SizedBox(height: 24),
            _buildStepsSection(),
            const SizedBox(height: 24),
            _buildToolsSection(),
            const SizedBox(height: 24),
            _buildTipsSection(),
            const SizedBox(height: 24),
            _buildWarningsSection(),
            const SizedBox(height: 24),
            _buildImagesSection(),
            const SizedBox(height: 80), // 底部留白
          ],
        ),
      ),
    );
  }

  /// 粘贴导入部分
  Widget _buildPasteImportSection() {
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  '智能导入',
                  style: AppTextStyles.h3.copyWith(color: Colors.blue.shade900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '粘贴菜谱内容，AI 将自动解析并填充表单',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pasteController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '粘贴菜谱内容...\n例如：\n菜名：红烧肉\n食材：五花肉 500g、生抽 2勺...\n步骤：1. 五花肉切块...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.paste),
                      tooltip: '粘贴剪贴板内容',
                      onPressed: _pasteFromClipboard,
                    ),
                    if (_pasteController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: '清空',
                        onPressed: () {
                          setState(() => _pasteController.clear());
                        },
                      ),
                  ],
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pasteController.text.trim().isEmpty || _isParsing
                    ? null
                    : _parseAndFill,
                icon: _isParsing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isParsing ? '解析中...' : '智能解析并填充'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 基本信息部分
  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('基本信息', style: AppTextStyles.h3),
            const SizedBox(height: 16),

            // 菜谱名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '菜谱名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入菜谱名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 分类选择
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category['value'],
                  child: Text(category['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // 难度选择 - 五颗星
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('难度', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDifficulty = starValue);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          starValue <= _selectedDifficulty
                              ? Icons.star
                              : Icons.star_border,
                          color: starValue <= _selectedDifficulty
                              ? Colors.orange
                              : Colors.grey,
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 食材部分
  Widget _buildIngredientsSection() {
    return _buildListSection(
      title: '食材',
      items: _ingredientTexts,
      onAdd: () => _addListItem(_ingredientTexts, '新食材'),
      onEdit: (index) => _editListItem(_ingredientTexts, index, '编辑食材'),
      onDelete: (index) => _deleteListItem(_ingredientTexts, index),
    );
  }

  /// 步骤部分 - 支持拖拽排序
  Widget _buildStepsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('制作步骤', style: AppTextStyles.h3),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addListItem(_stepDescriptions, '新步骤'),
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_stepDescriptions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('暂无制作步骤', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ReorderableListView.builder(
                buildDefaultDragHandles: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stepDescriptions.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _stepDescriptions.removeAt(oldIndex);
                    _stepDescriptions.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final step = _stepDescriptions[index];
                  return ListTile(
                    key: ValueKey('step_$index'),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          child: Text('${index + 1}'),
                        ),
                      ],
                    ),
                    title: Text(step),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editListItem(_stepDescriptions, index, '编辑步骤'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _deleteListItem(_stepDescriptions, index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 工具部分
  Widget _buildToolsSection() {
    return _buildListSection(
      title: '所需工具（可选）',
      items: _tools,
      onAdd: () => _addListItem(_tools, '新工具'),
      onEdit: (index) => _editListItem(_tools, index, '编辑工具'),
      onDelete: (index) => _deleteListItem(_tools, index),
    );
  }

  /// 小贴士部分
  Widget _buildTipsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('小贴士（可选）', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _tips,
              decoration: const InputDecoration(
                hintText: '输入烹饪小贴士',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _tips = value,
            ),
          ],
        ),
      ),
    );
  }

  /// 注意事项部分
  Widget _buildWarningsSection() {
    return _buildListSection(
      title: '注意事项（可选）',
      items: _warnings,
      onAdd: () => _addListItem(_warnings, '新注意事项'),
      onEdit: (index) => _editListItem(_warnings, index, '编辑注意事项'),
      onDelete: (index) => _deleteListItem(_warnings, index),
    );
  }

  /// 图片部分
  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('图片', style: AppTextStyles.h3),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addImageUrl(),
                  icon: const Icon(Icons.link),
                  label: const Text('URL'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _pickLocalImage(),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('本地'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_images.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('暂无图片', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._images.asMap().entries.map((entry) {
                final index = entry.key;
                final imagePath = entry.value;
                final isUrl = imagePath.startsWith('http');
                final isAsset = imagePath.startsWith('assets/');
                final isBase64 = imagePath.startsWith('data:image/');
                final isLocalFile = !isUrl && !isAsset && !isBase64;

                Widget leadingWidget;
                if (isBase64) {
                  try {
                    final base64String = imagePath.split(',')[1];
                    final bytes = base64Decode(base64String);
                    leadingWidget = ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        bytes,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    );
                  } catch (e) {
                    leadingWidget = const Icon(Icons.broken_image);
                  }
                } else if (isLocalFile && !kIsWeb && File(imagePath).existsSync()) {
                  leadingWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(imagePath),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  );
                } else {
                  leadingWidget = const Icon(Icons.image);
                }

                String displayText;
                String? subtitle;
                if (isBase64) {
                  displayText = 'WebP 图片';
                  subtitle = '已压缩';
                } else if (isLocalFile) {
                  displayText = kIsWeb ? '本地图片' : path.basename(imagePath);
                  subtitle = '本地文件';
                } else {
                  displayText = imagePath;
                  subtitle = null;
                }

                return ListTile(
                  leading: leadingWidget,
                  title: Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: subtitle != null
                      ? Text(subtitle, style: const TextStyle(fontSize: 12))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUrl)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editImageUrl(index),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteListItem(_images, index),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  /// 通用列表部分构建
  Widget _buildListSection({
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onEdit,
    required Function(int) onDelete,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: AppTextStyles.h3),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text('暂无$title', style: const TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ListTile(
                  leading: const Icon(Icons.circle, size: 8),
                  title: Text(item),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => onEdit(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => onDelete(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  /// 添加列表项
  void _addListItem(List<String> list, String hint) {
    _editListItemDialog(list, -1, hint);
  }

  /// 编辑列表项
  void _editListItem(List<String> list, int index, String hint) {
    _editListItemDialog(list, index, hint);
  }

  /// 列表项编辑对话框
  void _editListItemDialog(List<String> list, int index, String hint) {
    final controller = TextEditingController(
      text: index >= 0 ? list[index] : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          index >= 0 ? hint : '添加',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (index >= 0) {
                    list[index] = text;
                  } else {
                    list.add(text);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 删除列表项
  void _deleteListItem(List<String> list, int index) {
    setState(() => list.removeAt(index));
  }

  /// 添加图片URL
  void _addImageUrl() {
    _editImageUrlDialog(-1);
  }

  /// 编辑图片URL
  void _editImageUrl(int index) {
    _editImageUrlDialog(index);
  }

  /// 图片URL编辑对话框
  void _editImageUrlDialog(int index) {
    final controller = TextEditingController(
      text: index >= 0 ? _images[index] : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          index >= 0 ? '编辑图片URL' : '添加图片URL',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入图片URL地址',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                setState(() {
                  if (index >= 0) {
                    _images[index] = url;
                  } else {
                    _images.add(url);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 选择本地图片
  Future<void> _pickLocalImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      // 显示加载对话框
      if (mounted) {
        setState(() => _isUploadingImage = true);
        _showImageProcessingDialog();
      }

      // 读取图片字节
      final bytes = await image.readAsBytes();

      if (!mounted) return;
      _updateImageProcessingDialog('正在压缩图片...');

      // 压缩并转换为webp格式
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.webp,
        quality: 85,
      );

      final originalSizeKB = (bytes.length / 1024).toStringAsFixed(1);
      final compressedSizeKB = (compressedBytes.length / 1024).toStringAsFixed(1);

      String imagePath;

      if (kIsWeb) {
        if (!mounted) return;
        _updateImageProcessingDialog('正在转换格式...');

        // Web端：转换为base64字符串存储
        final base64String = base64Encode(compressedBytes);
        imagePath = 'data:image/webp;base64,$base64String';
      } else {
        if (!mounted) return;
        _updateImageProcessingDialog('正在保存文件...');

        // 移动端：保存到本地文件
        final appDir = await getApplicationDocumentsDirectory();
        final recipesImagesDir = Directory('${appDir.path}/recipe_images');

        // 确保目录存在
        if (!await recipesImagesDir.exists()) {
          await recipesImagesDir.create(recursive: true);
        }

        // 生成唯一文件名
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'recipe_new_$timestamp.webp';
        final targetPath = '${recipesImagesDir.path}/$fileName';

        // 写入压缩后的webp文件
        await File(targetPath).writeAsBytes(compressedBytes);
        imagePath = targetPath;
      }

      // 添加到图片列表
      if (mounted) {
        setState(() {
          _images.add(imagePath);
          _isUploadingImage = false;
        });
        Navigator.of(context).pop(); // 关闭加载对话框

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片添加成功 ($originalSizeKB KB → $compressedSizeKB KB)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 显示图片处理对话框
  void _showImageProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                '正在处理图片...',
                key: const ValueKey('processing_text'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 更新图片处理对话框的文本
  void _updateImageProcessingDialog(String message) {
    if (mounted && _isUploadingImage) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// 移除文本中的 emoji
  String _removeEmoji(String text) {
    // 移除所有 emoji 和特殊符号（保留中文、英文、数字、标点）
    return text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '') // Emoji 表情
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '')  // 杂项符号
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '')  // 装饰符号
        .replaceAll(RegExp(r'[\u{FE00}-\u{FE0F}]', unicode: true), '')  // 变体选择符
        .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), '') // 表情符号
        .replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), '') // 交通和地图符号
        .replaceAll(RegExp(r'[\u{1F1E0}-\u{1F1FF}]', unicode: true), '') // 国旗
        .trim();
  }

  /// 从剪贴板粘贴内容
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        setState(() {
          _pasteController.text = clipboardData.text!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已粘贴剪贴板内容'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('剪贴板为空'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('粘贴失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 智能解析并填充表单
  Future<void> _parseAndFill() async {
    final content = _pasteController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isParsing = true);

    try {
      // 本地简单解析逻辑
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

      String? name;
      List<String> ingredients = [];
      List<String> steps = [];
      List<String> tools = [];
      List<String> warnings = [];
      String? tips;
      String? category;
      int difficulty = 1;

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final cleanLine = _removeEmoji(line); // 移除 emoji 后的文本
        final lowerLine = cleanLine.toLowerCase();

        // 解析菜名（支持【】包裹）
        if (cleanLine.contains('【') && cleanLine.contains('】')) {
          final match = RegExp(r'【(.+?)】').firstMatch(cleanLine);
          if (match != null) {
            name = match.group(1);
            continue;
          }
        }

        // 解析菜名（标准格式）
        if (lowerLine.startsWith('菜名：') || lowerLine.startsWith('菜名:') ||
            lowerLine.startsWith('名称：') || lowerLine.startsWith('名称:')) {
          name = cleanLine.split(RegExp(r'[：:]'))[1].trim();
        }
        // 解析分类
        else if (lowerLine.startsWith('分类：') || lowerLine.startsWith('分类:') ||
                 lowerLine.startsWith('类别：') || lowerLine.startsWith('类别:')) {
          final categoryText = _removeEmoji(cleanLine.split(RegExp(r'[：:]'))[1].trim());
          category = _matchCategory(categoryText);
        }
        // 解析难度（支持星号 ⭐）
        else if (lowerLine.startsWith('难度：') || lowerLine.startsWith('难度:')) {
          final diffText = line.split(RegExp(r'[：:]'))[1].trim();
          // 计算星号数量
          final starCount = '⭐'.allMatches(diffText).length;
          if (starCount > 0) {
            difficulty = starCount.clamp(1, 5);
          } else if (diffText.contains('简单') || diffText.contains('1')) {
            difficulty = 1;
          } else if (diffText.contains('中等') || diffText.contains('2')) {
            difficulty = 2;
          } else if (diffText.contains('困难') || diffText.contains('3') || diffText.contains('难')) {
            difficulty = 3;
          } else if (diffText.contains('4')) {
            difficulty = 4;
          } else if (diffText.contains('5')) {
            difficulty = 5;
          }
        }
        // 解析食材
        else if (lowerLine.startsWith('食材：') || lowerLine.startsWith('食材:') ||
                 lowerLine.startsWith('配料：') || lowerLine.startsWith('配料:') ||
                 lowerLine.startsWith('原料：') || lowerLine.startsWith('原料:')) {
          // 食材可能在同一行或多行
          final parts = cleanLine.split(RegExp(r'[：:]'));
          if (parts.length > 1) {
            var ingText = parts[1].trim();
            if (ingText.isNotEmpty) {
              // 同一行有多个食材，用逗号、顿号、分号分隔
              ingredients.addAll(ingText.split(RegExp(r'[,，、;；]')).map((e) => e.trim()).where((e) => e.isNotEmpty));
            }
          }

          // 继续读取下一行，如果是列表项（• 开头）就当作食材
          for (var j = i + 1; j < lines.length; j++) {
            final nextLine = lines[j].trim();
            final nextClean = _removeEmoji(nextLine);
            final nextLower = nextClean.toLowerCase();

            // 遇到其他标题，停止（标题通常包含冒号）
            if (nextClean.contains(':') || nextClean.contains('：')) {
              break;
            }

            // 如果是 • 开头，当作食材
            if (nextClean.startsWith('•')) {
              String itemText = nextClean.substring(1).trim();
              if (itemText.isNotEmpty) {
                ingredients.addAll(itemText.split(RegExp(r'[,，、;；]')).map((e) => e.trim()).where((e) => e.isNotEmpty));
                i = j;
              } else {
                break;
              }
            } else {
              // 不是 • 开头，停止解析食材
              break;
            }
          }
        }
        // 解析工具
        else if (lowerLine.startsWith('所需工具') || lowerLine.startsWith('工具：') ||
                 lowerLine.startsWith('工具:')) {
          // 读取工具列表
          for (var j = i + 1; j < lines.length; j++) {
            final toolLine = lines[j].trim();
            final toolClean = _removeEmoji(toolLine);
            final toolLower = toolClean.toLowerCase();

            // 遇到其他标题，停止
            if (toolLower.startsWith('步骤') || toolLower.startsWith('做法') ||
                toolLower.startsWith('制作') || toolLower.startsWith('小贴士') ||
                toolLower.startsWith('注意') || toolClean.contains('---')) {
              break;
            }

            // 只解析 • 开头的行
            if (toolClean.startsWith('•')) {
              String toolText = toolClean.substring(1).trim();
              if (toolText.isNotEmpty) {
                tools.add(toolText);
                i = j;
              } else {
                break;
              }
            } else {
              // 不是 • 开头，停止解析工具
              break;
            }
          }
        }
        // 解析步骤
        else if (lowerLine.startsWith('步骤：') || lowerLine.startsWith('步骤:') ||
                 lowerLine.startsWith('做法：') || lowerLine.startsWith('做法:') ||
                 lowerLine.startsWith('制作步骤') || lowerLine.startsWith('制作：') ||
                 lowerLine.startsWith('制作:')) {
          // 步骤通常是多行
          for (var j = i + 1; j < lines.length; j++) {
            final stepLine = lines[j].trim();
            final stepClean = _removeEmoji(stepLine);
            final stepLower = stepClean.toLowerCase();

            // 遇到小贴士或其他标题，停止
            if (stepLower.startsWith('小贴士') || stepLower.startsWith('提示') ||
                stepLower.startsWith('注意') || stepLower.startsWith('tips') ||
                stepLower.contains('---')) {
              break;
            }

            // 移除步骤编号（如 "1. " 或 "1、" 或 "①"）
            var step = stepClean.replaceFirst(RegExp(r'^[\d①②③④⑤⑥⑦⑧⑨⑩]+[.、\s]+'), '').trim();
            if (step.isNotEmpty) {
              steps.add(step);
              i = j;
            } else {
              break;
            }
          }
        }
        // 解析小贴士
        else if (lowerLine.startsWith('小贴士：') || lowerLine.startsWith('小贴士:') ||
                 lowerLine.startsWith('提示：') || lowerLine.startsWith('提示:') ||
                 lowerLine.startsWith('tips：') || lowerLine.startsWith('tips:')) {
          final parts = cleanLine.split(RegExp(r'[：:]'));
          if (parts.length > 1) {
            tips = parts[1].trim();
          } else {
            tips = '';
          }

          // 小贴士可能多行
          for (var j = i + 1; j < lines.length; j++) {
            final tipsLine = lines[j].trim();
            final tipsClean = _removeEmoji(tipsLine);
            final tipsLower = tipsClean.toLowerCase();

            // 遇到其他标题或分隔符，停止
            if (tipsLower.startsWith('注意') || tipsLower.startsWith('warning') ||
                tipsClean.contains('---') || tipsLower.startsWith('分享自')) {
              break;
            }

            if (tipsClean.isNotEmpty) {
              tips = tips!.isEmpty ? tipsClean : '$tips\n$tipsClean';
              i = j;
            }
          }
        }
        // 解析注意事项
        else if (lowerLine.startsWith('注意事项') || lowerLine.startsWith('注意：') ||
                 lowerLine.startsWith('注意:') || lowerLine.startsWith('警告') ||
                 lowerLine.startsWith('warning')) {
          // 读取注意事项列表
          for (var j = i + 1; j < lines.length; j++) {
            final warnLine = lines[j].trim();
            final warnClean = _removeEmoji(warnLine);

            // 遇到分隔符或结尾，停止
            if (warnClean.contains('---') || warnClean.startsWith('分享自')) {
              break;
            }

            // 只解析 • 开头的行，也允许 - 开头（markdown 风格）
            if (warnClean.startsWith('•') || warnClean.startsWith('-')) {
              String warnText = warnClean.startsWith('•')
                  ? warnClean.substring(1).trim()
                  : warnClean.substring(1).trim();
              if (warnText.isNotEmpty) {
                warnings.add(warnText);
                i = j;
              } else {
                break;
              }
            } else {
              // 不是列表项开头，停止解析注意事项
              break;
            }
          }
        }
      }

      // 如果没有明确标记，尝试智能识别
      if (name == null && lines.isNotEmpty) {
        // 第一行可能是菜名（移除 emoji）
        name = _removeEmoji(lines[0].trim());
      }

      // 填充表单
      if (name != null && name.isNotEmpty) {
        _nameController.text = name;
      }

      if (category != null) {
        setState(() => _selectedCategory = category!);
      }

      setState(() {
        _selectedDifficulty = difficulty;
        if (ingredients.isNotEmpty) _ingredientTexts = ingredients;
        if (steps.isNotEmpty) _stepDescriptions = steps;
        if (tools.isNotEmpty) _tools = tools;
        if (warnings.isNotEmpty) _warnings = warnings;
        if (tips != null && tips.isNotEmpty) _tips = tips;
      });

      // 清空输入框
      _pasteController.clear();

      // 显示成功提示
      if (mounted) {
        final summary = <String>[];
        if (name != null) summary.add('菜名');
        if (category != null) summary.add('分类');
        if (difficulty > 1) summary.add('难度');
        if (ingredients.isNotEmpty) summary.add('${ingredients.length}个食材');
        if (steps.isNotEmpty) summary.add('${steps.length}个步骤');
        if (tools.isNotEmpty) summary.add('${tools.length}个工具');
        if (warnings.isNotEmpty) summary.add('${warnings.length}个注意事项');
        if (tips != null && tips.isNotEmpty) summary.add('小贴士');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 解析成功！已填充：${summary.join('、')}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('解析失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解析失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isParsing = false);
    }
  }

  /// 匹配分类
  String _matchCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('肉') || lower.contains('meat')) return 'meat_dish';
    if (lower.contains('素') || lower.contains('vegetable')) return 'vegetable_dish';
    if (lower.contains('水产') || lower.contains('海鲜') || lower.contains('鱼') || lower.contains('虾')) return 'aquatic';
    if (lower.contains('早餐') || lower.contains('breakfast')) return 'breakfast';
    if (lower.contains('主食') || lower.contains('staple')) return 'staple';
    if (lower.contains('汤') || lower.contains('羹') || lower.contains('soup')) return 'soup';
    if (lower.contains('甜品') || lower.contains('dessert')) return 'dessert';
    if (lower.contains('饮') || lower.contains('drink')) return 'drink';
    return 'meat_dish'; // 默认
  }

  /// 保存菜谱
  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ingredientTexts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个食材')),
      );
      return;
    }

    if (_stepDescriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个制作步骤')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 生成新的菜谱ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final categoryPrefix = _selectedCategory;
      final randomSuffix = timestamp.toRadixString(16).substring(0, 8);
      final newRecipeId = '${categoryPrefix}_$randomSuffix';

      // 转换食材文本为Ingredient对象
      final ingredients = _ingredientTexts.map((text) {
        final name = text.split(RegExp(r'\s+')).first;
        return Ingredient(name: name, text: text);
      }).toList();

      // 转换步骤描述为CookingStep对象
      final steps = _stepDescriptions.map((desc) {
        return CookingStep(description: desc);
      }).toList();

      // 获取分类名称
      final categoryName = _categories
          .firstWhere((c) => c['value'] == _selectedCategory)['label']!;

      final newRecipe = Recipe(
        id: newRecipeId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        categoryName: categoryName,
        difficulty: _selectedDifficulty,
        ingredients: ingredients,
        steps: steps,
        tools: _tools,
        tips: _tips?.trim().isEmpty == true ? null : _tips?.trim(),
        warnings: _warnings,
        images: _images,
        source: RecipeSource.userCreated,
        hash: '', // 用户创建的菜谱不需要hash
      );

      final repository = ref.read(recipeRepositoryProvider);
      await repository.saveRecipe(newRecipe);

      // 刷新相关provider
      ref.invalidate(allRecipesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
