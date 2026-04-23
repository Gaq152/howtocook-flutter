import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/hive_service.dart';
import 'github_mirror_resolver.dart';

/// 服务端 manifest.json 解析结果。
class UpdateInfo {
  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final String downloadUrlArm64;
  final String downloadUrlArm32;
  final String sha256;
  final String sha256Arm64;
  final String sha256Arm32;
  final int size;
  final String notes;
  final String publishedAt;

  const UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    this.downloadUrlArm64 = '',
    this.downloadUrlArm32 = '',
    required this.sha256,
    this.sha256Arm64 = '',
    this.sha256Arm32 = '',
    required this.size,
    required this.notes,
    required this.publishedAt,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        versionName: (json['versionName'] as String?)?.trim() ?? '',
        versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
        downloadUrl: (json['downloadUrl'] as String?)?.trim() ?? '',
        downloadUrlArm64: (json['downloadUrlArm64'] as String?)?.trim() ?? '',
        downloadUrlArm32: (json['downloadUrlArm32'] as String?)?.trim() ?? '',
        sha256: ((json['sha256'] as String?) ?? '').trim().toLowerCase(),
        sha256Arm64: ((json['sha256Arm64'] as String?) ?? '').trim().toLowerCase(),
        sha256Arm32: ((json['sha256Arm32'] as String?) ?? '').trim().toLowerCase(),
        size: (json['size'] as num?)?.toInt() ?? 0,
        notes: (json['notes'] as String?) ?? '',
        publishedAt: (json['publishedAt'] as String?) ?? '',
      );

  /// 根据设备 ABI 返回最合适的下载 URL 和 SHA256
  Future<({String url, String sha256})> resolveForDevice() async {
    if (!Platform.isAndroid) return (url: downloadUrl, sha256: sha256);
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final abis = info.supportedAbis;
      if (abis.contains('arm64-v8a') && downloadUrlArm64.isNotEmpty) {
        return (url: downloadUrlArm64, sha256: sha256Arm64.isNotEmpty ? sha256Arm64 : sha256);
      }
      if (abis.any((a) => a.startsWith('armeabi')) && downloadUrlArm32.isNotEmpty) {
        return (url: downloadUrlArm32, sha256: sha256Arm32.isNotEmpty ? sha256Arm32 : sha256);
      }
    } catch (_) {}
    return (url: downloadUrl, sha256: sha256);
  }
}

/// 更新检查结果，UI 层根据 [hasUpdate] 决定是否提示。
class UpdateCheckResult {
  final UpdateInfo? info;
  final bool hasUpdate;
  final int currentVersionCode;
  final String currentVersionName;

  const UpdateCheckResult({
    required this.info,
    required this.hasUpdate,
    required this.currentVersionCode,
    required this.currentVersionName,
  });
}

/// 应用自更新服务。
///
/// 所有 github.com 请求（manifest 与 APK）都经 [GithubMirrorResolver] 产生
/// 候选源，按「ghfast.top 镜像 → 官方」顺序尝试。
class UpdateService {
  UpdateService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final Dio _dio;

  static const String _skippedVersionKey = 'skipped_version_code';
  static const String _defaultManifestUrl =
      'https://github.com/Gaq152/howtocook-flutter/releases/latest/download/manifest.json';

  String get _manifestUrl {
    final override = dotenv.env['RELEASE_MANIFEST_URL']?.trim();
    return (override != null && override.isNotEmpty) ? override : _defaultManifestUrl;
  }

  /// 检查远端是否有可用更新。
  ///
  /// [respectSkippedVersion] 为 true 时，被用户跳过的版本视为无更新。
  /// 设置页的手动按钮应传 false，强制展示。
  Future<UpdateCheckResult> checkForUpdate({
    bool respectSkippedVersion = true,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;
    final currentName = packageInfo.version;

    final info = await _fetchManifest(_manifestUrl);
    if (info == null) {
      return UpdateCheckResult(
        info: null,
        hasUpdate: false,
        currentVersionCode: currentCode,
        currentVersionName: currentName,
      );
    }

    final skipped = respectSkippedVersion ? getSkippedVersion() : null;
    final hasUpdate =
        info.versionCode > currentCode && info.versionCode != skipped;

    return UpdateCheckResult(
      info: info,
      hasUpdate: hasUpdate,
      currentVersionCode: currentCode,
      currentVersionName: currentName,
    );
  }

  /// 下载 APK 到外部存储，校验 SHA256，失败自动切下一个镜像源。
  ///
  /// 成功返回本地文件绝对路径；全部镜像失败抛异常。
  Future<String> downloadUpdate(
    UpdateInfo info, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (info.downloadUrl.isEmpty || info.sha256.isEmpty) {
      throw ArgumentError('manifest 缺少 downloadUrl 或 sha256');
    }
    final resolved = await info.resolveForDevice();
    final candidates = GithubMirrorResolver.candidates(resolved.url);
    final saveDir = await _prepareDownloadDir();
    final savePath =
        p.join(saveDir.path, 'howtocook-${info.versionName}-${info.versionCode}.apk');

    // 命中本地缓存：若文件存在且 SHA 一致，直接复用
    final cached = File(savePath);
    if (await cached.exists()) {
      final localSha = await _sha256OfFile(cached);
      if (localSha == resolved.sha256) {
        debugPrint('✅ 命中本地缓存 APK，跳过下载：$savePath');
        onProgress?.call(1.0);
        return savePath;
      }
      await cached.delete();
    }

    Object? lastError;
    for (final url in candidates) {
      try {
        debugPrint('⬇️  下载更新包：$url');
        await _dio.download(
          url,
          savePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total > 0 && onProgress != null) {
              onProgress(received / total);
            }
          },
          options: Options(
            followRedirects: true,
            receiveTimeout: const Duration(minutes: 10),
          ),
        );
        final sha = await _sha256OfFile(File(savePath));
        if (sha != resolved.sha256) {
          debugPrint('❌ SHA256 校验失败 expected=${resolved.sha256} actual=$sha');
          await File(savePath).delete();
          lastError = Exception('SHA256 校验失败');
          continue;
        }
        debugPrint('✅ APK 下载完成并通过 SHA256 校验');
        return savePath;
      } catch (e) {
        debugPrint('⚠️  镜像 $url 下载失败：$e');
        lastError = e;
        final f = File(savePath);
        if (await f.exists()) await f.delete();
      }
    }
    throw lastError ?? Exception('所有下载源均失败');
  }

  /// 调起系统安装器安装 APK。
  Future<void> installApk(String apkPath) async {
    final file = File(apkPath);
    if (!await file.exists()) throw Exception('APK 文件不存在：$apkPath');
    await InstallPlugin.installApk(apkPath, appId: 'com.anlife.howtocook');
  }

  /// 记录用户跳过的版本号。
  Future<void> skipVersion(int versionCode) async {
    await HiveService.getUpdatePrefsBox().put(_skippedVersionKey, versionCode);
  }

  /// 读取被跳过的版本号。
  int? getSkippedVersion() {
    final raw = HiveService.getUpdatePrefsBox().get(_skippedVersionKey);
    return raw is int ? raw : null;
  }

  Future<UpdateInfo?> _fetchManifest(String manifestUrl) async {
    final candidates = GithubMirrorResolver.candidates(manifestUrl);
    for (final url in candidates) {
      try {
        debugPrint('🔎 拉取更新 manifest：$url');
        final resp = await _dio.get<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
        final body = resp.data;
        if (body == null || body.isEmpty) continue;
        final json = jsonDecode(body) as Map<String, dynamic>;
        return UpdateInfo.fromJson(json);
      } catch (e) {
        debugPrint('⚠️  manifest 拉取失败 ($url)：$e');
      }
    }
    return null;
  }

  Future<Directory> _prepareDownloadDir() async {
    final root = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'updates'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _sha256OfFile(File file) async {
    // APK 通常 10-50MB，一次性读取内存可接受；若未来需要支持超大包再改分块
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString().toLowerCase();
  }
}

/// 单例 Provider
final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());
