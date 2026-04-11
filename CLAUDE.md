# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码仓库工作时提供指导。

## 项目概述

REAL READER 是一款跨平台 RSS 阅读器，基于 Flutter 构建。集成 AI 翻译/摘要（Minimax）、云端同步（Supabase），采用高端杂志风格的 UI 设计系统（"The Editorial Sanctuary"）。

## 开发命令

```bash
# 安装依赖
flutter pub get

# 运行
flutter run -d macos
flutter run -d windows
flutter run -d iphone

# 分析/检查
flutter analyze

# 测试
flutter test

# 指定测试文件
flutter test test/data/models/feed_model_test.dart

# 构建
flutter build macos
flutter build ios
flutter build windows
```

## 环境变量（运行时必填）

通过 `flutter run` 的 `--dart-define` 参数或 Shell 环境变量设置：

| 变量 | 说明 |
|------|------|
| `SUPABASE_URL` | Supabase 项目 URL |
| `SUPABASE_ANON_KEY` | Supabase Anonymous（公开）Key |
| `MINIMAX_API_KEY` | Minimax API Key |
| `MINIMAX_GROUP_ID` | Minimax Group ID |

示例：`flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...`

## 架构

**三层 Clean Architecture：**
- `lib/presentation/` — UI 层（pages、widgets、BLoCs）
- `lib/domain/` — 业务逻辑层（entities、repository 接口）
- `lib/data/` — 数据层（models、datasources、repository 实现）

**状态管理：** flutter_bloc（BLoC 模式）

**路由：** go_router + ShellRoute，根据 `universal_platform` 自动选择 `DesktopShell` 或 `MobileShell`

**本地存储：** sqflite（SQLite）— 表：`feeds`、`articles`、`categories`、`settings`、`sync_metadata`

**云端同步：** Supabase — 与 SQLite 同 schema，通过 `SyncService` 同步（last-write-wins 冲突解决）

**核心 BLoCs：**
- `AuthBloc` — Apple/GitHub/Email 登录，认证状态
- `FeedBloc` — RSS 订阅源和分类的 CRUD
- `ArticleBloc` — 文章的已读/收藏/阅读进度跟踪
- `SettingsBloc` — 主题模式、字体大小、阅读速度
- `AiBloc` — Minimax 翻译、摘要、TTS 朗读

**设计系统：** 详见 `UI/desktop/stitch/slate_serif/DESIGN.md` 和 `UI/mobile/stitch/slate_serif/DESIGN.md`。正文使用 Newsreader（衬线体），UI 标签使用 Inter。颜色定义在 `AppColors` 类中 — 深色模式不使用纯黑色（采用 `surface-dim` 方案）。

## 重要模式

- **Models** 使用 `Equatable`，通过 `fromMap`/`toMap` 与 SQLite 互转
- **Local datasources** 处理 SQLite CRUD；remote datasources 处理 HTTP/API
- **Repository 实现** 位于 BLoCs 和 datasources 之间
- **OPML 导入/导出** 由 `lib/data/services/opml_service.dart` 中的 `OpmlService` 处理
- **AI 功能**（翻译/摘要）相互独立 — 各自分别调用 Minimax，结果存于 BLoC state，不覆盖原文
