# Changelog

本文件记录 HowToCook 的所有发布变更。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

> 客户端检查到新版本时，更新弹窗会直接渲染这里对应版本的条目，请保持 Markdown 可读。

## [Unreleased]

## [0.1.0] - 2026-04-18

首个正式公开版本。

### 新增
- **菜谱管理**：列表 / 搜索 / 筛选 / 收藏 / 笔记 / 编辑 / 创建，支持二维码分享与扫码导入。
- **AI 助手**：多模型对话（Claude / GPT / DeepSeek），图片识别，流式输出，思考链实时展示。
- **MCP 工具**：内置 `create_recipe`，AI 可在对话中直接生成菜谱预览卡片。
- **模型管理**：设置页支持自定义 API Key，内置 Key 与自定义 Key 一键切换。
- **数据同步**：内置资源打包 + GitHub Pages 增量更新，封面图与详情图可独立开关下载。
- **教程系统**：查看 / 创建 / 编辑烹饪教程，按分类组织。
- **自动更新**：启动 3 秒后静默检查 GitHub Releases，支持 ghfast.top 镜像回退，SHA256 校验，断点缓存复用。
- **用户中心**：我的收藏、我的自创。

### 变更
- 应用包名统一为 `com.anlife.howtocook`。
- Release 构建启用独立 keystore 签名，CI 与本地通过 `key.properties` 共享同一密钥。
- 新增 `REQUEST_INSTALL_PACKAGES` 权限以支持应用内更新安装。

### 修复
- 解决 AGP 8 下部分三方插件（如 `install_plugin`）缺失 `namespace` 导致的构建失败。

[Unreleased]: https://github.com/Gaq152/howtocook-flutter/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Gaq152/howtocook-flutter/releases/tag/v0.1.0
