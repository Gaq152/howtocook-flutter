import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../recipe/application/providers/recipe_providers.dart'
    show manifestProvider;
import '../../application/providers/tip_providers.dart';
import '../../domain/entities/tip.dart';

class TipEditorScreen extends ConsumerStatefulWidget {
  const TipEditorScreen({super.key, this.tipId, this.initialCategory});

  final String? tipId;
  final String? initialCategory;

  bool get isEditing => tipId != null;

  @override
  ConsumerState<TipEditorScreen> createState() => _TipEditorScreenState();
}

class _TipEditorScreenState extends ConsumerState<TipEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _categoryNameController;
  late final TextEditingController _contentController;

  String? _selectedCategory;
  Tip? _loadedTip;
  bool _initialized = false;

  final List<_SectionFormData> _sections = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _categoryNameController = TextEditingController();
    _contentController = TextEditingController();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryNameController.dispose();
    _contentController.dispose();
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manifestAsync = ref.watch(manifestProvider);
    final tipAsync = widget.tipId != null
        ? ref.watch(tipByIdProvider(widget.tipId!))
        : null;

    if (!_initialized && widget.isEditing) {
      tipAsync?.when(
        data: (tip) {
          if (tip != null) {
            _loadedTip = tip;
            _populateFromTip(tip);
            _initialized = true;
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    } else if (!_initialized && !widget.isEditing) {
      _initializeForCreate();
      _initialized = true;
    }

    final titleText = widget.isEditing ? '编辑教程' : '新增教程';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            tooltip: '智能解析',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _showParseDialog(context),
          ),
          IconButton(
            tooltip: '保存',
            icon: const Icon(Icons.save_outlined),
            onPressed: () => _saveTip(context),
          ),
        ],
      ),
      body: manifestAsync.when(
        data: (manifest) {
          final categories = manifest.tipsCategories;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    prefixIcon: Icon(Icons.title_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入标题' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value:
                      _selectedCategory ??
                      (categories.isNotEmpty ? categories.keys.first : null),
                  items: categories.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text('${entry.value.name} (${entry.key})'),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: '分类',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      if (value != null) {
                        final categoryInfo = categories[value];
                        if (categoryInfo != null) {
                          _categoryNameController.text = categoryInfo.name;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryNameController,
                  decoration: const InputDecoration(
                    labelText: '分类显示名称',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: '正文内容',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('教程分节', style: AppTextStyles.h4),
                    TextButton.icon(
                      onPressed: _addSection,
                      icon: const Icon(Icons.add),
                      label: const Text('新增分节'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_sections.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('暂无分节内容，点击右上角“新增分节”创建。'),
                  ),
                for (int i = 0; i < _sections.length; i++)
                  _SectionEditorCard(
                    index: i,
                    data: _sections[i],
                    onRemove: () => _removeSection(i),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('加载分类失败: $error')),
      ),
    );
  }

  void _initializeForCreate() {
    if (_selectedCategory == null) {
      _selectedCategory = 'learn';
    }
    _categoryNameController.text = _categoryNameController.text.isEmpty
        ? '基础技巧'
        : _categoryNameController.text;
  }

  void _populateFromTip(Tip tip) {
    _titleController.text = tip.title;
    _selectedCategory = tip.category;
    _categoryNameController.text = tip.categoryName;
    _contentController.text = tip.content;

    _sections
      ..clear()
      ..addAll(
        tip.sections.map(
          (section) =>
              _SectionFormData(title: section.title, content: section.content),
        ),
      );
    setState(() {});
  }

  void _addSection() {
    setState(() {
      _sections.add(_SectionFormData());
    });
  }

  void _removeSection(int index) {
    setState(() {
      final removed = _sections.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveTip(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCategory = _selectedCategory;
    if (selectedCategory == null || selectedCategory.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }

    final categoryName = _categoryNameController.text.trim().isEmpty
        ? selectedCategory
        : _categoryNameController.text.trim();

    final sections = _sections
        .map(
          (data) => TipSection(
            title: data.titleController.text.trim(),
            content: data.contentController.text.trim(),
          ),
        )
        .where(
          (section) => section.title.isNotEmpty || section.content.isNotEmpty,
        )
        .toList();

    final id = widget.tipId ?? _generateTipId(selectedCategory);
    final now = DateTime.now();
    final createdAt = _loadedTip?.createdAt ?? now;

    final hash = _computeTipHash(
      id: id,
      title: _titleController.text.trim(),
      category: selectedCategory,
      categoryName: categoryName,
      content: _contentController.text.trim(),
      sections: sections,
    );

    final tip = Tip(
      id: id,
      title: _titleController.text.trim(),
      category: selectedCategory,
      categoryName: categoryName,
      content: _contentController.text.trim(),
      sections: sections,
      hash: hash,
      isFavorite: _loadedTip?.isFavorite ?? false,
      createdAt: createdAt,
      updatedAt: now,
    );

    try {
      await ref.read(tipRepositoryProvider).saveTip(tip);
      ref.invalidate(allTipsProvider);
      ref.invalidate(tipsByCategoryProvider(selectedCategory));
      ref.invalidate(tipByIdProvider(id));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('教程已保存')));
        context.pop(tip);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  void _showParseDialog(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('智能解析（实验性）', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              const Text('将 Markdown/纯文本粘贴在此，我们会自动拆分成正文和分节内容。'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      '示例：\n介绍内容...\n\n## 注意事项\n段落内容...\n\n## 操作步骤\n段落内容...',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    final raw = controller.text.trim();
                    if (raw.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }
                    _applyParsedContent(raw);
                    Navigator.pop(context);
                  },
                  child: const Text('解析并应用'),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() => controller.dispose());
  }

  void _applyParsedContent(String text) {
    final lines = LineSplitter.split(text).toList();
    final buffer = StringBuffer();
    final sections = <TipSection>[];
    String? currentTitle;

    for (final line in lines) {
      final headingMatch = RegExp(r'^(#{2,}|\d+\.)\s+(.*)$').firstMatch(line);
      if (headingMatch != null) {
        if (currentTitle != null) {
          sections.add(
            TipSection(
              title: currentTitle.trim(),
              content: buffer.toString().trim(),
            ),
          );
          buffer.clear();
        } else if (buffer.isNotEmpty) {
          _contentController.text = buffer.toString().trim();
          buffer.clear();
        }
        currentTitle = headingMatch.group(2) ?? headingMatch.group(0)!;
      } else {
        buffer.writeln(line);
      }
    }

    if (currentTitle != null) {
      sections.add(
        TipSection(
          title: currentTitle.trim(),
          content: buffer.toString().trim(),
        ),
      );
    } else if (buffer.isNotEmpty) {
      _contentController.text = buffer.toString().trim();
    }

    setState(() {
      for (final section in _sections) {
        section.dispose();
      }
      _sections
        ..clear()
        ..addAll(
          sections.map(
            (section) => _SectionFormData(
              title: section.title,
              content: section.content,
            ),
          ),
        );
    });
  }

  String _generateTipId(String category) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    return 'tips_${category}_$timestamp';
  }

  String _computeTipHash({
    required String id,
    required String title,
    required String category,
    required String categoryName,
    required String content,
    required List<TipSection> sections,
  }) {
    final payload = {
      'id': id,
      'title': title,
      'category': category,
      'categoryName': categoryName,
      'content': content,
      'sections': sections
          .map(
            (section) => {'title': section.title, 'content': section.content},
          )
          .toList(),
    };
    return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
  }
}

class _SectionEditorCard extends StatelessWidget {
  const _SectionEditorCard({
    required this.index,
    required this.data,
    required this.onRemove,
  });

  final int index;
  final _SectionFormData data;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('分节 ${index + 1}', style: AppTextStyles.h5),
                IconButton(
                  tooltip: '删除分节',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: data.titleController,
              decoration: const InputDecoration(
                labelText: '分节标题',
                prefixIcon: Icon(Icons.subtitles_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: data.contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '分节内容',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionFormData {
  _SectionFormData({String title = '', String content = ''})
    : titleController = TextEditingController(text: title),
      contentController = TextEditingController(text: content);

  final TextEditingController titleController;
  final TextEditingController contentController;

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }
}
