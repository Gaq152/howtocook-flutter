import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/database_manager.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

/// 应用入口
void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化存储服务
  await _initializeServices();

  // 运行应用
  runApp(
    const ProviderScope(
      child: HowToCookApp(),
    ),
  );
}

/// 初始化所有服务
Future<void> _initializeServices() async {
  try {
    // 1. 加载环境变量
    await dotenv.load(fileName: '.env');

    // 2. 初始化 Hive
    await HiveService.init();

    // 3. 初始化 Sqflite（仅在非 Web 平台）
    if (!kIsWeb) {
      await DatabaseManager().database;
      debugPrint('✅ Sqflite 数据库已初始化');
    } else {
      debugPrint('ℹ️ Web 平台：跳过 Sqflite 初始化（使用 Hive 存储）');
    }

    debugPrint('✅ 所有服务初始化成功');
  } catch (e, stackTrace) {
    debugPrint('❌ 服务初始化失败: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

/// 主应用
class HowToCookApp extends ConsumerWidget {
  const HowToCookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(currentThemeModeProvider);

    return MaterialApp.router(
      title: '智能菜谱助手',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // 本地化配置
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 简体中文
        Locale('en', 'US'), // 英文（备用）
      ],
      locale: const Locale('zh', 'CN'), // 默认语言
    );
  }
}
