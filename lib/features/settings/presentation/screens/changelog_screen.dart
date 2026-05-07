import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';

class ChangelogScreen extends StatefulWidget {
  final String currentVersion;

  const ChangelogScreen({super.key, required this.currentVersion});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _fullChangelog = '';
  String _currentVersionLog = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChangelog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChangelog() async {
    try {
      final content = await rootBundle.loadString('CHANGELOG.md');
      final currentLog = _extractVersionLog(content, widget.currentVersion);
      if (mounted) {
        setState(() {
          _fullChangelog = content;
          _currentVersionLog = currentLog;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullChangelog = '无法加载更新日志';
          _currentVersionLog = '无法加载更新日志';
          _loading = false;
        });
      }
    }
  }

  String _extractVersionLog(String content, String version) {
    final versionClean = version.replaceFirst('v', '');
    final lines = content.split('\n');
    final buffer = StringBuffer();
    var found = false;

    for (final line in lines) {
      if (line.startsWith('## [') && line.contains(versionClean)) {
        found = true;
        buffer.writeln(line);
        continue;
      }
      if (found) {
        if (line.startsWith('## [')) break;
        buffer.writeln(line);
      }
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) {
      return '当前版本 v$versionClean 暂无更新日志';
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更新日志'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '当前版本'),
            Tab(text: '全部版本'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMarkdownView(_currentVersionLog),
                _buildMarkdownView(_fullChangelog),
              ],
            ),
    );
  }

  Widget _buildMarkdownView(String data) {
    return Markdown(
      data: data,
      selectable: true,
      padding: const EdgeInsets.all(16),
      onTapLink: (_, href, __) {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
