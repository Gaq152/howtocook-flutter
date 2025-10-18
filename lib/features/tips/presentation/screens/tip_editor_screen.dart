// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:html_unescape/html_unescape.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../recipe/application/providers/recipe_providers.dart'
    show manifestProvider;
import '../../application/providers/tip_providers.dart';
import '../../domain/entities/tip.dart';
import '../../../sync/domain/entities/manifest.dart';

final HtmlUnescape _tipEditorUnescape = HtmlUnescape();

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
  late final TextEditingController _parseInputController;

  String? _selectedCategory;
  Tip? _loadedTip;
  bool _initialized = false;
  bool _isParsing = false;
  Map<String, CategoryInfo>? _tipCategories;

  final List<_SectionFormData> _sections = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _categoryNameController = TextEditingController();
    _contentController = TextEditingController();
    _parseInputController = TextEditingController();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryNameController.dispose();
    _contentController.dispose();
    _parseInputController.dispose();
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
            tooltip: '保存',
            icon: const Icon(Icons.save_outlined),
            onPressed: () => _saveTip(context),
          ),
        ],
      ),
      body: manifestAsync.when(
        data: (manifest) {
          final categories = manifest.tipsCategories;
          _tipCategories = categories;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (!widget.isEditing) ...[
                  _buildParseCard(context),
                  const SizedBox(height: 24),
                ],
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
                  initialValue:
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
                    child: const Text('暂无分节内容，点击右上角“新增分节”创建一个分节。'),
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
    _selectedCategory ??= 'learn';
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

    final repository = ref.read(tipRepositoryProvider);
    final allTips = await repository.getAllTips();
    final currentTipId = widget.tipId;

    String effectiveTitle = _titleController.text.trim();
    Tip? overwriteTarget;

    while (true) {
      Tip? duplicate;
      for (final tip in allTips) {
        if (tip.title == effectiveTitle &&
            (currentTipId == null || tip.id != currentTipId)) {
          duplicate = tip;
          break;
        }
      }

      if (duplicate == null) {
        _titleController.text = effectiveTitle;
        break;
      }

      final action = await _showDuplicateTipDialog(effectiveTitle);
      if (action == null || action == _DuplicateAction.cancel) {
        return;
      }

      if (action == _DuplicateAction.rename) {
        final newName = await _showTipRenameDialog(effectiveTitle);
        if (newName == null || newName.trim().isEmpty) {
          return;
        }
        effectiveTitle = newName.trim();
        continue;
      }

      if (action == _DuplicateAction.overwrite) {
        overwriteTarget = duplicate;
        _titleController.text = effectiveTitle;
        break;
      }
    }

    final id =
        overwriteTarget?.id ?? currentTipId ?? _generateTipId(selectedCategory);
    final now = DateTime.now();
    final createdAt =
        overwriteTarget?.createdAt ?? _loadedTip?.createdAt ?? now;

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
      await repository.saveTip(tip);
      ref.invalidate(allTipsProvider);
      ref.invalidate(tipsByCategoryProvider(selectedCategory));
      ref.invalidate(tipByIdProvider(id));
      if (overwriteTarget != null &&
          overwriteTarget.category != selectedCategory) {
        ref.invalidate(tipsByCategoryProvider(overwriteTarget.category));
      }

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

  Widget _buildParseCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = colorScheme.secondaryContainer;
    final titleColor = colorScheme.onSecondaryContainer;
    final inputText = _parseInputController.text;

    return Card(
      elevation: 2,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '智能解析',
                  style: AppTextStyles.h4.copyWith(color: titleColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '粘贴教程内容，系统会自动拆分正文与分节，帮助快速建稿。',
              style: AppTextStyles.bodySmall.copyWith(
                color: titleColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _parseInputController,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: const OutlineInputBorder(),
                hintText: '示例：\n教程名称…\n\n## 材料准备\n内容…\n\n## 操作步骤\n内容…',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '粘贴剪贴板内容',
                      icon: const Icon(Icons.paste),
                      onPressed: _isParsing
                          ? null
                          : () => _pasteFromClipboard(context),
                    ),
                    if (inputText.isNotEmpty)
                      IconButton(
                        tooltip: '清空',
                        icon: const Icon(Icons.clear),
                        onPressed: _isParsing
                            ? null
                            : () {
                                setState(() {
                                  _parseInputController.clear();
                                });
                              },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isParsing || inputText.trim().isEmpty
                    ? null
                    : () => _handleParse(context),
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
                label: Text(_isParsing ? '解析中…' : '智能解析并填充'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;

    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('剪贴板中没有可用的文本')));
      return;
    }

    setState(() {
      _parseInputController.text = text;
    });
  }

  Future<void> _handleParse(BuildContext context) async {
    final raw = _parseInputController.text.trim();
    if (raw.isEmpty || _isParsing) {
      return;
    }

    setState(() => _isParsing = true);
    try {
      _applyParsedContent(raw);
      setState(() {
        _parseInputController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('解析完成，已填充表单')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('解析失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  void _applyParsedContent(String text) {
    final payload = _sanitizeParsedInput(text);

    _contentController.clear();

    if (payload.title != null && payload.title!.isNotEmpty) {
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = payload.title!;
      }
    }

    String? resolvedCategoryKey;
    final categoryName = payload.categoryName?.trim();
    if (categoryName != null && categoryName.isNotEmpty) {
      _categoryNameController.text = categoryName;
      if (_tipCategories != null) {
        for (final entry in _tipCategories!.entries) {
          if (entry.value.name == categoryName || entry.key == categoryName) {
            resolvedCategoryKey = entry.key;
            break;
          }
        }
        resolvedCategoryKey ??= _tipCategories!.containsKey(categoryName)
            ? categoryName
            : null;
      }
    }

    final buffer = StringBuffer();
    final sections = <TipSection>[];
    String? currentTitle;

    for (final rawLine in payload.lines) {
      final line = rawLine.trimRight();
      if (line.isEmpty && currentTitle == null && buffer.isEmpty) {
        continue;
      }
      if (line.isEmpty) {
        buffer.writeln();
        continue;
      }

      final headingMatch = RegExp(
        r'^(#{2,}|\d+\.)\s+(.*)$',
      ).firstMatch(line.trimLeft());
      if (headingMatch != null) {
        if (currentTitle != null) {
          final sectionContent = buffer.toString().trim();
          if (sectionContent.isNotEmpty || currentTitle.trim().isNotEmpty) {
            sections.add(
              TipSection(title: currentTitle.trim(), content: sectionContent),
            );
          }
          buffer.clear();
        } else if (buffer.isNotEmpty) {
          final summary = buffer.toString().trim();
          if (summary.isNotEmpty) {
            _contentController.text = summary;
          }
          buffer.clear();
        }
        currentTitle = headingMatch.group(2) ?? headingMatch.group(0)!;
      } else {
        buffer.writeln(line);
      }
    }

    if (currentTitle != null) {
      final sectionContent = buffer.toString().trim();
      if (sectionContent.isNotEmpty || currentTitle.trim().isNotEmpty) {
        sections.add(
          TipSection(title: currentTitle.trim(), content: sectionContent),
        );
      }
    } else if (buffer.isNotEmpty) {
      final summary = buffer.toString().trim();
      if (summary.isNotEmpty) {
        _contentController.text = summary;
      }
    }

    setState(() {
      if (resolvedCategoryKey != null) {
        _selectedCategory = resolvedCategoryKey;
      }
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

  Future<_DuplicateAction?> _showDuplicateTipDialog(String title) async {
    return showDialog<_DuplicateAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              '发现同名教程',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '已存在名为「$title」的教程。',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '请选择操作：',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• 覆盖：替换现有教程\n• 重命名：输入新名称\n• 取消：放弃保存',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DuplicateAction.cancel),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DuplicateAction.rename),
            child: const Text('重命名'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _DuplicateAction.overwrite),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('覆盖'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTipRenameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '重命名教程',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '新名称',
            hintText: '请输入新的教程名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context, newName);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  _ParsedInput _sanitizeParsedInput(String raw) {
    final decoded = _tipEditorUnescape
        .convert(raw)
        .replaceAll('\r\n', '\n')
        .trimRight();
    final rawLines = decoded.split('\n');

    String? title;
    String? categoryName;
    bool reachedBody = false;
    final bodyLines = <String>[];

    for (final original in rawLines) {
      var line = _stripEmoji(
        original,
      ).replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '').trimRight();

      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        if (reachedBody && bodyLines.isNotEmpty && bodyLines.last.isNotEmpty) {
          bodyLines.add('');
        }
        continue;
      }

      if (!reachedBody) {
        final titleMatch = RegExp(r'[「《](.+?)[」》]').firstMatch(trimmed);
        if (titleMatch != null && title == null) {
          title = titleMatch.group(1)!.trim();
          continue;
        }

        final categoryMatch = RegExp(r'^分类[:：]\s*(.+)$').firstMatch(trimmed);
        if (categoryMatch != null) {
          categoryName = categoryMatch.group(1)?.trim();
          continue;
        }

        if (trimmed == '正文' || trimmed.contains('正文')) {
          reachedBody = true;
          continue;
        }
      }

      if (trimmed == '教程分节' || trimmed.contains('教程分节')) {
        reachedBody = true;
        continue;
      }

      if (trimmed == '---') {
        continue;
      }

      if (trimmed.startsWith('分享自')) {
        continue;
      }

      bodyLines.add(trimmed);
      reachedBody = true;
    }

    while (bodyLines.isNotEmpty && bodyLines.first.isEmpty) {
      bodyLines.removeAt(0);
    }
    while (bodyLines.isNotEmpty && bodyLines.last.isEmpty) {
      bodyLines.removeLast();
    }

    return _ParsedInput(
      title: title,
      categoryName: categoryName,
      lines: bodyLines,
    );
  }

  String _stripEmoji(String input) {
    return input.replaceAll(
      RegExp(
        r'[\u{1F000}-\u{1FAFF}\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
        unicode: true,
      ),
      '',
    );
  }
}

enum _DuplicateAction { cancel, rename, overwrite }

class _ParsedInput {
  const _ParsedInput({required this.lines, this.title, this.categoryName});

  final List<String> lines;
  final String? title;
  final String? categoryName;
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
