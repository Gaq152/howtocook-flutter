import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/update_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _pkg;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _pkg = info);
    });
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    final service = ref.read(updateServiceProvider);
    try {
      // 手动检查时忽略「跳过本版」状态，强制展示
      final result = await service.checkForUpdate(respectSkippedVersion: false);
      if (!mounted) return;
      if (result.hasUpdate && result.info != null) {
        await showUpdateDialog(
          context: context,
          ref: ref,
          info: result.info!,
          currentVersionName: result.currentVersionName,
        );
      } else {
        _showSnack(result.info == null ? '未能获取更新信息，请稍后重试' : '已经是最新版本');
      }
    } catch (e) {
      if (mounted) _showSnack('检查更新失败：$e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _showChangelog() async {
    setState(() => _checking = true);
    try {
      final service = ref.read(updateServiceProvider);
      final result = await service.checkForUpdate(respectSkippedVersion: false);
      if (!mounted) return;
      final notes = result.info?.notes.trim() ?? '';
      final versionName = result.info?.versionName ?? _pkg?.version ?? '--';
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('更新日志 v$versionName'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 380),
            child: notes.isEmpty
                ? const Text('暂无更新日志')
                : Scrollbar(
                    child: SingleChildScrollView(
                      child: MarkdownBody(
                        data: notes,
                        selectable: true,
                        onTapLink: (text, href, title) {
                          if (href == null) return;
                          final uri = Uri.tryParse(href);
                          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _showSnack('获取更新日志失败：$e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showSnack(String msg) {
    AppSnackBar.show(context, msg);
  }

  Future<void> _openRepo() async {
    final uri = Uri.parse('https://github.com/Gaq152/howtocook-flutter');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _showSnack('无法打开浏览器');
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: '智能菜谱助手',
      applicationVersion: _pkg == null
          ? '--'
          : '${_pkg!.version} (build ${_pkg!.buildNumber})',
      applicationLegalese: '基于 Flutter 构建',
      children: [
        const SizedBox(height: 12),
        InkWell(
          onTap: _openRepo,
          child: const Text(
            'github.com/Gaq152/howtocook-flutter',
            style: TextStyle(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = _pkg == null
        ? '--'
        : '${_pkg!.version} (${_pkg!.buildNumber})';

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader('AI 助手'),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('模型管理'),
            subtitle: const Text('管理 AI 模型配置、API Key 与能力'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/model-management'),
          ),

          const _SectionHeader('数据'),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('数据同步'),
            subtitle: const Text('从云端增量下载菜谱和教程'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/data-sync'),
          ),

          const _SectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('检查更新'),
            subtitle: Text('当前版本 $version'),
            trailing: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _checking ? null : _checkUpdate,
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('更新日志'),
            subtitle: const Text('查看当前版本的更新内容'),
            trailing: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _checking ? null : _showChangelog,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('版本信息与开源仓库'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
