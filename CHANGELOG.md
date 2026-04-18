# Changelog

本文件记录 HowToCook 的所有发布变更。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

> 客户端检查到新版本时，更新弹窗会直接渲染这里对应版本的条目，请保持 Markdown 可读。

## [Unreleased]

## [0.1.1] - 2026-04-18

### 新增
- **模型管理页免责声明**：底部新增小字提示，说明自定义模型输出质量取决于服务商。

### 变更
- **「我的」页精简入口**：模型管理、数据同步、关于 三项从主页移除，统一收敛到「设置」页入口，减少重复。
- **底部导航栏重构**：移除突出 FAB 设计，改为标准三项导航（菜谱 / AI / 我的），解决 FAB 遮挡输入框问题。
- **AI 提示词优化**：工具调用规则改为"自然语言整理呈现"，避免模型直接输出原始 JSON。

### 修复
- **DeepSeek / OpenAI 工具调用**：`sendMessageSync` 改为直接解析 SSE 流，修复 tool_calls 被纯文本流丢弃导致 MCP 工具无法触发的问题。
- **AI 多轮工具调用文本保留**：修复 AI 先输出文字再调用工具时，前置文本被"正在调用工具..."覆盖丢失的问题。
- **菜谱工具 Chip 字体不可见**：显式指定 labelStyle 颜色，修复浅色背景下文字与背景色接近导致看不清的问题。

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

[Unreleased]: https://github.com/Gaq152/howtocook-flutter/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/Gaq152/howtocook-flutter/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Gaq152/howtocook-flutter/releases/tag/v0.1.0
