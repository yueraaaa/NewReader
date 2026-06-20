# Real Reader - 技术手册

> Flutter RSS 阅读器 | Clean Architecture + BLoC

---

## 目录

1. [项目概述](#1-项目概述)
2. [系统架构](#2-系统架构)
3. [数据模型](#3-数据模型)
4. [核心功能](#4-核心功能)
5. [模块详解](#5-模块详解)
6. [配置说明](#6-配置说明)
7. [路由设计](#7-路由设计)
8. [已知问题与限制](#8-已知问题与限制)
9. [技术债务](#9-技术债务)

---

## 1. 项目概述

**Real Reader** 是一个跨平台 RSS 阅读器，支持桌面端和移动端。

| 属性 | 值 |
|------|-----|
| 框架 | Flutter 3.x |
| 架构 | Clean Architecture + BLoC |
| 本地存储 | SQLite (sqflite) |
| 远程同步 | Supabase (PostgreSQL + Auth) |
| AI 功能 | MiniMax API 集成 |
| 依赖包数 | 20+ (见 `pubspec.yaml`) |

### 文件结构

```
lib/
├── core/                    # 核心配置
│   ├── config/              # App 配置 (API keys)
│   ├── constants/            # 颜色、间距常量
│   ├── router/              # GoRouter 路由
│   └── theme/                # Material Theme
├── data/                     # 数据层
│   ├── datasources/
│   │   ├── local/           # SQLite 本地存储
│   │   ├── remote/          # RSS/Supabase 远程
│   │   └── ai/              # MiniMax AI
│   ├── models/              # 数据模型
│   ├── repositories/        # Repository 实现
│   └── services/           # OPML / Sync 服务
├── domain/                   # 领域层
│   ├── entities/           # 实体
│   └── repositories/        # Repository 接口
└── presentation/            # 表现层
    ├── blocs/              # 状态管理 (Auth/Feed/Article/Settings/AI)
    ├── pages/              # 页面 (desktop/mobile)
    └── widgets/            # 通用组件
```

**总文件数：68 个 Dart 文件**

---

## 2. 系统架构

### 2.1 层级依赖

```
┌────────────────────────────────────────────┐
│              Presentation Layer            │
│   Pages ──► BLoCs ──► Repositories         │
└────────────────────┬───────────────────────┘
                     │
┌────────────────────▼───────────────────────┐
│                Domain Layer                 │
│         Repository Interfaces               │
└────────────────────┬───────────────────────┘
                     │
┌────────────────────▼───────────────────────┐
│                  Data Layer                 │
│  Local Datasources  │  Remote Datasources   │
│  SQLite             │  RSS / Supabase      │
└────────────────────────────────────────────┘
```

### 2.2 数据流

```
用户操作 → BLoC Event → Repository → Datasource
                ↓
          State 更新 → UI 重建
                ↓
          同步到云端 (可选)
```

### 2.3 BLoC 架构

| BLoC | 职责 |
|------|------|
| `AuthBloc` | 登录/登出/Auth 状态 |
| `FeedBloc` | 订阅源/分类的 CRUD + 刷新 |
| `ArticleBloc` | 文章的 CRUD、搜索、未读计数、阅读进度 |
| `SettingsBloc` | 主题、语言、API 配置 |
| `AiBloc` | AI 摘要/翻译/解释 |

---

## 3. 数据模型

### 3.1 数据库 Schema

**SQLite 文件：** `real_reader.db` (位于系统数据库目录)

```sql
-- 分类表
categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  user_id TEXT DEFAULT '',
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)

-- 订阅源表
feeds (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  category_id TEXT REFERENCES categories(id),
  user_id TEXT DEFAULT '',
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)

-- 文章表
articles (
  id TEXT PRIMARY KEY,
  feed_id TEXT NOT NULL REFERENCES feeds(id),
  title TEXT NOT NULL,
  link TEXT NOT NULL,
  description TEXT,        -- 摘要/预览
  content TEXT,            -- 完整内容
  author TEXT,
  image_url TEXT,
  published_at TEXT,
  is_read INTEGER DEFAULT 0,
  is_favorite INTEGER DEFAULT 0,
  read_progress REAL DEFAULT 0,  -- 0.0 ~ 1.0
  user_id TEXT DEFAULT '',
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)

-- 设置表 (key-value)
settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)

-- 同步元数据
sync_metadata (
  table_name TEXT PRIMARY KEY,
  last_synced_at TEXT
)
```

### 3.2 索引

```sql
idx_articles_feed_id       ON articles(feed_id)
idx_articles_published_at ON articles(published_at)
idx_feeds_category_id     ON feeds(category_id)
idx_feeds_user_id         ON feeds(user_id)
idx_articles_user_id      ON articles(user_id)
idx_categories_user_id    ON categories(user_id)
```

### 3.3 Model 类

| Model | 文件 | 关键字段 |
|-------|------|---------|
| `ArticleModel` | `data/models/article_model.dart` | id, title, link, content, isRead, isFavorite, readProgress |
| `FeedModel` | `data/models/feed_model.dart` | id, title, url, categoryId |
| `CategoryModel` | `data/models/category_model.dart` | id, name, color |

所有 Model：
- 使用 `Equatable` 实现值相等
- 提供 `fromMap()` / `toMap()` 方法与 SQLite/Supabase 互转
- 提供 `copyWith()` 方法支持不可变更新

---

## 4. 核心功能

### 4.1 RSS 订阅管理

| 功能 | 状态 | 说明 |
|------|------|------|
| 添加订阅源 | ✅ | 输入 RSS URL，自动解析 |
| 删除订阅源 | ✅ | 软删除 (is_deleted=1) |
| 刷新单个订阅源 | ✅ | 手动触发，拉取新文章 |
| 刷新全部订阅源 | ✅ | 遍历所有订阅源 |
| 分类管理 | ✅ | 创建/删除分类，给订阅源分配分类 |
| OPML 导入 | ✅ | 支持批量导入订阅源 |
| OPML 导出 | ✅ | 导出全部订阅源为 OPML 文件 |

### 4.2 文章阅读

| 功能 | 状态 | 说明 |
|------|------|------|
| 文章列表 | ✅ | 按订阅源/分类/全部显示 |
| 文章详情 | ✅ | 显示完整内容，支持滚动 |
| 标记已读/未读 | ✅ | 自动 + 手动 |
| 收藏文章 | ✅ | bookmark 收藏夹 |
| 阅读进度 | ✅ | 滚动位置 0.0~1.0，自动保存 |
| 离线阅读 | ✅ | 文章内容存储在 SQLite，可离线访问 |
| 搜索文章 | ✅ | 按标题/内容/描述搜索 |
| 未读计数 | ✅ | 显示未读文章数量 badge |

### 4.3 云端同步

| 功能 | 状态 | 说明 |
|------|------|------|
| 登录 (Apple/GitHub/Email) | ✅ | Supabase Auth |
| 订阅源同步 | ✅ | 增删改自动同步到 Supabase |
| 分类同步 | ✅ | 增删改自动同步 |
| 文章状态同步 | ✅ | 已读/收藏/阅读进度同步 |
| 跨设备同步 | ✅ | 登录后自动 pull cloud 数据 |

> **注意：** 同步为单向 (本地 → 云端)，云端数据用于备份和多设备共享。

### 4.4 AI 功能

| 功能 | 状态 | 说明 |
|------|------|------|
| AI 摘要 | ✅ | 调用 MiniMax API 生成文章摘要 |
| AI 翻译 | ✅ | 调用 MiniMax API 翻译文章 |
| AI 解释 | ✅ | 调用 MiniMax API 解释文章内容 |
| 文字转语音 | ✅ | Flutter TTS 实现文章朗读 |

> AI 功能通过 `AiBloc` 管理，使用 `MiniMaxDatasource` 调用 MiniMax API。

### 4.5 分享功能

```dart
Share.share('${article.title}\n${article.link}', subject: article.title);
```

使用 `share_plus` 包，支持系统分享面板。

---

## 5. 模块详解

### 5.1 核心模块依赖图

```
main.dart
  ├── DatabaseHelper (初始化 SQLite)
  ├── SettingsLocalDatasource (读取 API 配置)
  └── RealReaderApp
        └── MultiBlocProvider
              ├── AuthBloc ← AuthRepository ← SupabaseDatasource
              ├── SettingsBloc ← SettingsLocalDatasource
              ├── FeedBloc ← FeedRepositoryImpl
              │     ├── FeedLocalDatasource (SQLite)
              │     ├── RssRemoteDatasource (RSS 解析)
              │     └── SupabaseDatasource (云同步)
              ├── ArticleBloc ← ArticleLocalDatasource + SupabaseDatasource
              └── AiBloc ← MiniMaxDatasource
```

### 5.2 FeedRepositoryImpl

负责订阅源和分类的业务逻辑：

```dart
class FeedRepositoryImpl implements FeedRepository {
  // 添加订阅源 → 解析 RSS → 插入 SQLite → 同步云端
  Future<void> addFeed(String url, {String? categoryId});

  // 刷新订阅源 → 获取新文章 → UPSERT 到 SQLite
  Future<void> refreshFeed(String id);

  // 软删除订阅源及其文章 → 同步云端
  Future<void> deleteFeed(String id);

  // 私有方法：本地变更同步到 Supabase
  Future<void> _syncToCloud();

  // 从云端拉取数据合并到本地
  Future<void> pullFromCloud();
}
```

### 5.3 ArticleBloc

管理文章状态和操作：

```dart
class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  // Events:
  // - LoadArticles(feedId, categoryId)      加载文章列表
  // - LoadAllArticles                       加载全部文章
  // - LoadFavoriteArticles                   加载收藏文章
  // - MarkArticleRead(articleId, isRead)    标记已读
  // - MarkArticleFavorite(articleId, isFav) 标记收藏
  // - UpdateReadProgress(articleId, prog)   更新阅读进度
  // - SearchArticles(query)                 搜索文章
  // - LoadUnreadCount(feedId)               加载未读计数
  // - LoadArticleById(articleId)            加载单篇文章 (离线用)
}
```

### 5.4 SupabaseDatasource

远程数据访问层 (Supabase)：

```dart
class SupabaseDatasource {
  // Auth
  Future<User> signInWithApple();
  Future<User> signInWithGithub();
  Future<User> signInWithEmail(email, password);
  Stream<User?> authStateChanges;

  // CRUD (自动按 user_id 过滤)
  Future<List<Map>> getFeeds(since);      // 获取订阅源
  Future<void> upsertFeed(feed);          // 插入/更新订阅源
  Future<List<Map>> getArticles(since);   // 获取文章
  Future<void> upsertArticle(article);    // 插入/更新文章
  Future<List<Map>> getCategories(since);
  Future<void> upsertCategory(category);
  Future<Map?> getSetting(key);
  Future<void> setSetting(key, value);
}
```

### 5.5 Datasource 对比

| 操作 | 本地 (SQLite) | 远程 (Supabase) |
|------|-------------|----------------|
| 订阅源 CRUD | `FeedLocalDatasource` | `SupabaseDatasource.upsertFeed()` |
| 文章 CRUD | `ArticleLocalDatasource` | `SupabaseDatasource.upsertArticle()` |
| RSS 获取 | `RssRemoteDatasource.fetchAndParseArticles()` | - |
| AI | - | `MiniMaxDatasource` |

---

## 6. 配置说明

### 6.1 API 配置

配置来源优先级：**数据库设置 > 环境变量 > 硬编码默认值**

```dart
// 读取顺序：
1. SettingsLocalDatasource.getSetting('supabase_url')
2. AppConfig.supabaseUrl (环境变量 SUPABASE_URL)
3. 空字符串 fallback
```

配置文件：
- `lib/core/config/app_config.dart` — 硬编码默认值
- `lib/data/datasources/local/settings_local_datasource.dart` — 数据库设置存储

### 6.2 Supabase 配置项

| Key | 说明 |
|-----|------|
| `supabase_url` | Supabase 项目 URL |
| `supabase_anon_key` | Supabase Anon Key (公开密钥) |
| `minimax_api_key` | MiniMax API 密钥 |

### 6.3 主题配置

通过 `SettingsBloc` 管理：

```dart
// 可配置项：
themeMode     // ThemeMode.light / dark / system
fontSize      // 字号 (small/medium/large)
// 等...
```

---

## 7. 路由设计

使用 `go_router` + `ShellRoute` 实现自适应布局：

```dart
ShellRoute (
  // 桌面端 → DesktopShell (侧边栏)
  // 移动端 → MobileShell (底部导航)
  routes: [
    /            → DashboardPage         (首页/全部文章)
    /explore     → ExplorePage            (探索/发现)
    /bookmarks   → BookmarksPage          (收藏夹)
    /settings    → SettingsPage           (设置)
    /search      → SearchPage             (搜索)
    /category/:id → FeedListPage          (分类文章列表)
    /feed/:id    → FeedListPage           (订阅源文章列表)
    /article/:id → ArticleDetailPage      (文章详情)
  ]
)
```

| 路由 | 页面 | 布局 |
|------|------|------|
| `/` | DashboardPage | 侧边栏 + 主内容区 |
| `/explore` | ExplorePage | 侧边栏 + 主内容区 |
| `/bookmarks` | BookmarksPage | 侧边栏 + 主内容区 |
| `/settings` | SettingsPage | 侧边栏 + 主内容区 |
| `/search` | SearchPage | 搜索界面 |
| `/category/:id` | FeedListPage | 侧边栏 + 主内容区 |
| `/feed/:id` | FeedListPage | 侧边栏 + 主内容区 |
| `/article/:id` | ArticleDetailPage | 全屏文章阅读 + 顶部工具栏 |

---

## 8. 已知问题与限制

### 8.1 功能限制

| 问题 | 说明 | 严重度 |
|------|------|--------|
| 钉钉未接入 | 钉钉消息功能无法使用 (Stream 模式配置中) | 低 |
| 无移动端适配验证 | 移动端 UI 可能存在布局问题 | 中 |
| OPML 导入无进度条 | 大文件导入时 UI 无反馈 | 低 |
| 无错误重试机制 | 网络失败后不会自动重试 | 低 |
| 文章去重逻辑缺失 | 同一订阅源的新文章可能重复入库 | 中 |

### 8.2 技术限制

| 限制 | 说明 |
|------|------|
| 无分页加载 | 文章列表一次性加载全部，可能影响性能 |
| 无订阅源更新检测 | 无法感知订阅源 URL 变更 |
| 无夜间模式自动切换 | 依赖系统设置，不支持定时切换 |
| AI 功能无缓存 | 每次查看摘要都重新调用 API |

### 8.3 未解决的问题

| 问题 | 位置 | 说明 |
|------|------|------|
| `type` 变量未使用 | `opml_service.dart:68` | Warning，不影响功能 |
| `isPassword` 参数未使用 | `settings_page.dart:555` | Warning，不影响功能 |

---

## 9. 技术债务

### 9.1 测试覆盖

| 类型 | 状态 |
|------|------|
| Widget Tests | `test/widget_test.dart` (存在) |
| Model Tests | `test/data/models/` (3 个测试文件) |
| BLoC Tests | `bloc_test` 依赖已添加，但无测试文件 |
| 集成测试 | 无 |

### 9.2 代码质量

| 指标 | 状态 |
|------|------|
| `flutter analyze` | ⚠️ 2 warnings, 0 errors |
| 文档注释 | 核心类有注释，部分方法无 |
| 错误处理 | 部分异步操作缺少 try-catch |

### 9.3 建议优先级

| 优先级 | 任务 |
|--------|------|
| P0 | 修复文章去重逻辑 |
| P1 | 添加文章列表分页/虚拟滚动 |
| P1 | 移动端 UI 适配验证 |
| P2 | 添加 BLoC 单元测试 |
| P2 | AI 摘要结果缓存 |
| P3 | OPML 导入进度反馈 |
| P3 | 网络失败自动重试 |

---

## 附录

### A. 依赖版本

```yaml
flutter_bloc: ^8.1.3
equatable: ^2.0.5
go_router: ^13.0.0
sqflite: ^2.3.0
supabase_flutter: ^2.12.2
webfeed_revised: ^0.7.2
share_plus: ^7.2.1
file_picker: ^6.1.1
path_provider: ^2.1.1
google_fonts: ^6.1.0
flutter_tts: ^4.0.2
```

### B. 关键常量

```dart
// app_spacing.dart
static const sideNavWidth = 280.0;  // 侧边栏宽度
static const radiusMd = 12.0;        // 圆角半径

// app_colors.dart
// 定义了 light/dark 两套色板
primary         // 主色调
onSurface       // 文本色
surface         // 背景色
```

### C. Supabase 表结构 (参考)

```sql
-- feeds 表 (Supabase)
CREATE TABLE feeds (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  category_id TEXT,
  user_id TEXT REFERENCES auth.users(id),
  is_deleted INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

-- RLS 策略：用户只能访问自己的数据
CREATE POLICY "Users can only access their own feeds"
  ON feeds FOR ALL
  USING (auth.uid() = user_id);

-- articles 表类似，包含 is_read, is_favorite, read_progress 字段
```

---

*手册版本：1.0.0*
*最后更新：2026-04-11*
