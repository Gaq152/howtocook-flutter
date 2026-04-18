# 智能菜谱助手（HowToCook）

> 基于 Flutter + Riverpod 的跨平台智能菜谱与 AI 助手。

## 功能概览
- 菜谱管理：列表 / 搜索 / 筛选 / 收藏 / 笔记 / 编辑 / 创建
- AI 助手：多模型对话、识图、菜谱卡片生成
- 同步：内置数据加载、增量更新、云端下载
- 用户中心：我的菜谱 / 收藏 / 设置
- 扫码与分享：二维码扫描、生成分享卡片、保存 / 截图

## 技术栈
- Flutter 3.9 / Dart 3.9，Riverpod 2.x，go_router
- 数据：Hive（全平台）、Sqflite（非 Web 平台）
- 网络：Dio + pretty_dio_logger
- 代码生成：freezed、json_serializable、riverpod_generator、hive_generator、build_runner
- 资源与多媒体：cached_network_image、image_picker、flutter_image_compress、qr_flutter、screenshot、opencv_dart 等

## 架构说明
- 模式：Clean Architecture + Feature-Based
- 分层依赖：Presentation → Application → Domain → Infrastructure
- 核心目录：`lib/core`（通用能力）与 `lib/features/*`（按业务分层）
- 路由：`lib/core/router/app_router.dart`
- 主题：`lib/core/theme/`

## 目录结构（摘录）
```
lib/
├── core/                 # 公共模块（constants/router/services/storage/theme/utils/widgets）
└── features/             # 业务模块（recipe/ai_chat/settings/sync/tips/user...）
    ├── domain/           # 实体与仓库接口
    ├── application/      # 用例、providers
    ├── infrastructure/   # datasources/repositories 实现
    └── presentation/     # screens/widgets
```

## 环境要求
- Flutter SDK ≥ 3.9.2，Dart ≥ 3.9.2
- Android minSdk 21；iOS 当前未启用（如需可补充）
- 本地需安装：`flutter`、`dart`（如使用多包可补充 `melos` 等）

## 快速开始
```bash
# 1) 安装依赖
flutter pub get

# 2) 配置环境变量（参考 .env.example，复制并修改）
cp .env.example .env
# PowerShell 可用：Copy-Item .env.example .env

# 3) 生成代码（freezed / json / riverpod / hive）
dart run build_runner build --delete-conflicting-outputs

# 4) 运行
flutter run -d <device_id>
```

## 配置说明（.env 关键项示例）
- `AI_PROVIDER` / `AI_API_KEY`：AI 模型与密钥
- `BASE_API_URL`：后端接口地址（如有）
- 其他：图片压缩/上传、日志级别等

> 请根据实际使用的环境变量补充完整的键名与默认值。

## 数据与存储
- Hive：全平台本地存储，初始化见 `lib/core/storage/hive_service.dart`
- Sqflite：非 Web 平台启用，入口初始化于 `lib/main.dart` / `DatabaseManager`
- 资源：`assets/` 下 covers / recipes / tips 等已在 `pubspec.yaml` 声明

## 运行与调试
- 常规运行：`flutter run`
- Web 预览（如需）：`flutter run -d chrome`
- 日志：`pretty_dio_logger` 已集成，可在 Dio 初始化处调节级别

## 代码生成
```bash
dart run build_runner build --delete-conflicting-outputs
# 或监听模式
dart run build_runner watch --delete-conflicting-outputs
```

## 构建发布
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS（如启用）
flutter build ios --release
```

## 规范与约定
- 代码风格：`flutter_lints` + 项目已有约定
- 架构：优先按 Clean Architecture + Feature-Based 落地
- 文案：中文文案集中管理，业务实体与代码命名用英文
- 提交：建议遵循 Conventional Commits（feat / fix / docs / chore 等）

## 测试
```bash
flutter test
```
> 如有集成/UI 测试，请在此补充命令与依赖。

## 常见问题（示例）
- 代码生成冲突：删除 `.dart_tool/build` 或使用 `--delete-conflicting-outputs`
- 资源未找到：确认资源已写入 `pubspec.yaml` 的 `assets`，并执行 `flutter pub get`

## Roadmap / TODO
- [ ] 列出计划中的功能或优化项

## 许可证
- 请在此注明 License（如 MIT / Apache-2.0 / 专有）
