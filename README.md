# REAL READER

一款跨平台 RSS 阅读器，基于 Flutter 构建。集成 AI 翻译/摘要（Minimax）、云端同步（Supabase），采用高端杂志风格的 UI 设计系统。

## 功能特性

- **RSS 订阅管理** — 添加、编辑、删除、分类管理 RSS 订阅源
- **文章阅读** — 列表展示、已读/未读标记、收藏、阅读进度记录
- **OPML 导入/导出** — 标准 OPML 格式，支持从其他阅读器迁移
- **AI 增强** — 一键翻译成中文、智能摘要、语音朗读
- **云端同步** — Supabase 实时同步，多设备无缝衔接
- **第三方登录** — Apple / GitHub / Email 一键登录
- **无广告 · 无注册限制 · 轻量化**

## 支持平台

- macOS
- Windows
- iOS

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.x / Dart 3.x |
| 状态管理 | flutter_bloc |
| 本地存储 | sqflite (SQLite) |
| 云端服务 | Supabase |
| AI 服务 | Minimax API |
| RSS 解析 | webfeed_revised |
| 路由 | go_router |

## 快速开始

### 安装依赖

```bash
flutter pub get
```

### 运行

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# iOS
flutter run -d iphone
```

### 构建

```bash
flutter build macos
flutter build ios
flutter build windows
```

## 配置 API

首次使用需要在应用内配置或在环境变量中设置：

| 变量 | 说明 |
|------|------|
| `SUPABASE_URL` | Supabase 项目 URL |
| `SUPABASE_ANON_KEY` | Supabase Anonymous Key |
| `MINIMAX_API_KEY` | Minimax API Key |
| `MINIMAX_GROUP_ID` | Minimax Group ID |

或在应用内「设置 > API 配置」页面直接输入。

## 项目结构

```
lib/
├── core/              # 核心：主题、路由、配置
├── data/              # 数据层：模型、数据源、仓库实现
├── domain/           # 业务层：实体、仓库接口
└── presentation/      # 表现层：页面、组件、BLoC
```

## 设计系统

UI 设计遵循 "The Editorial Sanctuary" 理念：
- **Newsreader** 衬线体用于文章正文
- **Inter** 无衬线体用于界面标签
- 浅色/深色双模式（深色不使用纯黑）
- 无边框分隔，通过背景色阶区分层级

详见 `UI/desktop/stitch/slate_serif/DESIGN.md`

## License

MIT License
