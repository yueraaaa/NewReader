# NewReader 代码质量与安全检查报告

> 审计对象：`/Users/zhuliang/Documents/NewReader`
> 审计日期：2026-06-15
> 当前版本：v1.2.0（commit `798835e`）
> 技术栈：Swift 6.0 / SwiftUI / SwiftData / FeedKit / Supabase / CloudKit
> 平台：macOS 15+、iOS 18+
> 规模：40 个 Swift 源文件，~5956 行代码；4 个测试文件，~382 行

---

## 0. 总体评价

| 维度 | 评分 | 说明 |
|------|------|------|
| 架构清晰度 | ★★★★☆ | Core/Mac/iOS 三层切分合理，ViewModel 集中，Services 单一职责 |
| 安全姿态 | ★★★★☆ | SSRF/XSS/Keychain/OPML 都有专门防护；HTML 消毒、CSP 完整 |
| 编码规范 | ★★★☆☆ | 整体良好，偶有 `try!` / force unwrap / 重复键 / 多余 import |
| 测试覆盖 | ★★☆☆☆ | 4 个测试文件，仅覆盖 4/16 个 Service；`swift test` 当前**编译失败** |
| 文档完整度 | ★★★★★ | README/CLOUDKIT.md 详尽，注释非常充分 |
| 可发布度 | ★★★★☆ | 构建通过（388s），主路径无崩溃风险；测试套件需修复 |

**TL;DR**：项目结构与安全防御都做得相当扎实，但**测试套件目前无法编译**（actor 隔离错误），需要在交付前修复；另外有几处安全/正确性细节值得修缮。

---

## 1. 关键发现摘要

| 级别 | 数量 | 简述 |
|------|------|------|
| 🔴 CRITICAL | 2 | `swift test` 编译失败；`Secrets.plist` 含真实 publishable key 留在工作树 |
| 🟠 HIGH | 5 | Keychain 重复键、force unwrap、HTTP 错误信息泄露、未使用 import、CRUD 误用 |
| 🟡 MEDIUM | 7 | 视图层代码重复、CRUD 静默失败、日志用 print 等 |
| 🟢 LOW | 6 | 死代码残留、临时文件清理、.DS_Store/缓存等小问题 |

---

## 2. 🔴 CRITICAL

### 2.1 `swift test` 编译失败（6 个 actor-isolated 错误）
- **位置**：`Tests/NewReaderCoreTests/AIServiceTests.swift:7,12,17,22,28,33`
- **根因**：`AIService` 整体标了 `@MainActor`，其静态方法 `stripThinking(_:)` 因此也是主 actor 隔离的，但测试从同步上下文调用。
- **影响**：CI 跑测试直接失败；本地 `swift build` 不带 test target 也能通过，造成"绿色构建"假象。
- **修复**：
  ```swift
  // AIService.swift
  nonisolated public static func stripThinking(_ text: String) -> String { ... }
  ```
  该方法无状态、无 IO，安全可标记为 `nonisolated`。

### 2.2 `Secrets.plist` 工作树里有真实 publishable key
- **位置**：`Sources/NewReaderMac/Secrets.plist`（未跟踪 — 已在 `.gitignore:30`）
- **状态**：当前已被 .gitignore 正确忽略，**未提交**。
- **风险**：.gitignore 配置 OK，但文件明文存在于工作树，且 `package-macos.sh` 会把它写进 `Info.plist`。如果未来有人不小心 `git add -f` 或拷贝发布包，会泄露。
- **建议**：
  1. 把 `Secrets.plist` 移到 `~/Library/Application Support/NewReader/` 等用户目录，构建脚本按需读取。
  2. 或改用环境变量 + 注入 Info.plist 的方式。
  3. 短期内加一条 `.gitattributes` 或 README 警告。

---

## 3. 🟠 HIGH

### 3.1 KeychainHelper 有重复键
- **位置**：`Sources/NewReaderCore/Services/KeychainHelper.swift:24,27`
- **代码**：
  ```swift
  let addQuery: [String: Any] = [
      ...
      kSecAttrAccessGroup as String: "com.newreader.app",  // line 24
      kSecAttrService as String: serviceName,
      kSecValueData as String: data,
      kSecAttrAccessGroup as String: "com.newreader.app",  // line 27 (重复)
      ...
  ]
  ```
- **影响**：Swift 字典以后者为准（`com.newreader.app` 仍是该值），但意图不清；且对 `load(key:)` 来讲 line 41 也写了 `kSecAttrAccessGroup`，如果未来改 save 的 access group 而忘了改 load，会导致写入读出不在同一 group。
- **修复**：删除重复，并抽出为常量。

### 3.2 CustomTTSProvider 把原始 HTTP 响应体塞进 UI 错误信息
- **位置**：`Sources/NewReaderCore/Services/CustomTTSProvider.swift:222`
- **代码**：`errorMessage = "TTS 响应解析失败: \(raw.prefix(200))"`
- **影响**：TTS API 错误体可能含 token、路径、PII。设置页 `SettingsView.swift:248` 会把这段 `err` 直接 `Text(err)` 渲染给用户。
- **修复**：只显示脱敏后的"响应非 JSON"，并把 raw body 写进 `os_log`（带 `privacy: .private`）。

### 3.3 `ReaderViewModel` 误 import CoreData
- **位置**：`Sources/NewReaderCore/ViewModels/ReaderViewModel.swift:4`
- **代码**：`import CoreData`
- **影响**：项目是纯 SwiftData，没有用到任何 `NSManagedObject` / `NSPersistentContainer`（用了 `NSPersistentCloudKitContainer` 通知，但那是 `Foundation`+SwiftData 提供的）。死 import 增加编译时间和包大小，误导后来人。
- **修复**：删除该行。

### 3.4 SwiftData CRUD 大量静默 `try?`
- **位置**：`Sources/NewReaderCore/ViewModels/ReaderViewModel.swift`（全文 ~12 处）
  - line 87, 119, 143, 193, 208, 219, 224, 229, 235, 245, 268, 303, 395, 416, 424, 431, 440, 446, 474
- **影响**：保存失败被静默吞掉——SwiftData `save()` 失败通常是 schema 冲突或磁盘满，但用户看不到任何错误，`@Published errorMessage` 也不会被赋值。
- **修复**：封装 `private func save() throws` 集中处理；调用点用 `do/catch` 写日志 + 写 `errorMessage`。

### 3.5 视图层 `KeyboardShortcut` 在 iOS 上无效
- **位置**：`Sources/NewReaderMac/ContentView.swift:52,57`、`SidebarView.swift:191,200,223,232,252,261`、`NewReaderMacApp.swift:54,59`、`SettingsView.swift:27,36,115`、`WorkspaceView.swift:27,36` 等
- **影响**：macOS 专用快捷键绑在 `Button` 内的 `.keyboardShortcut(...)` 在 iOS 上不会生效（编译过，运行忽略），但代码中混在共享组件里，会误导以为是跨平台的。
- **建议**：把 `ContentView`/`SidebarView` 中可以共享的逻辑迁到 `NewReaderCore/Views/`（仅 macOS 编译），或者用 `#if os(macOS)` 包裹快捷键绑定。

---

## 4. 🟡 MEDIUM

### 4.1 macOS 与 iOS 视图层 70% 重复
- **数据**：`Sources/NewReaderMac` 1373 行 vs `Sources/NewReaderiOS` 702 行；其中 SettingsView、SubscribeView、WorkspaceView 几乎是同代码不同 padding。
- **建议**：抽到 `NewReaderCore/Views/`，用 `ViewThatFits` / `#if os(...)` 处理平台差异；SettingsView 已经有 macOS 专属子项（TTS 测速），iOS 可以直接用子集版本。

### 4.2 `ReaderViewModel.workspace` 阈值不一致
- **位置**：`Sources/NewReaderCore/ViewModels/ReaderViewModel.swift`
  - line 369 `generateWorkspace()`：需要至少 3 篇
  - line 408 `maybeGenerateWorkspace()`：触发阈值是 5 篇
  - line 62 `WorkspaceView.swift`（macOS）和 iOS 提示"阅读 5 篇以上"
- **建议**：抽常量 `private static let workspaceMinArticles = 3` / `workspaceAutoThreshold = 5`，并在 `WorkspaceView` 文案里直接读 vm。

### 4.3 ArticleListView 的 `searchText` 与 viewModel 双向同步混乱
- **位置**：`Sources/NewReaderMac/ArticleListView.swift:7,193`
  - `@State private var searchText: String = ""` 是本地状态
  - `.onChange(of: searchText) { viewModel.searchQuery = newValue }` 又写到 vm
  - 但 `viewModel.filteredArticles` 来自 vm
  - ⌘F 通过 `NSEvent.addLocalMonitorForEvents` 在 `onAppear` 拦截 keyDown 设置 `isSearchFocused = true`（line 202-208），**没有注销监听**。
- **影响**：每次 `ArticleListView` 出现就新增一个 monitor，但旧 monitor 还引用着 `isSearchFocused`（虽然 SwiftUI `@State` 已被释放）。属于潜在泄漏。
- **建议**：把 ⌘F 处理放到 `.onKeyPress(.init("f", modifiers: .command))`（macOS 14+），避免全局事件监听。

### 4.4 ReaderViewModel 把 CloudKit 事件 + loadData 串联
- **位置**：`Sources/NewReaderCore/ViewModels/ReaderViewModel.swift:67-79`
- **影响**：`NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)` 在 SwiftData + CloudKit 场景下能用，但 `NotificationCenter.Publisher` 没有 `[weak self]` 之外的额外保护，且 `event.endDate != nil` 检查排除了 `setup` 事件才执行 `loadData`，但 `setup` 完成后 `import` 事件可能在中途发生——不是 bug，但逻辑不易推理。
- **建议**：直接用 `NSPersistentCloudKitContainer.eventChangedNotification` 的 closure 形式（保留一份 cancellable），并加注释。

### 4.5 SettingsView 的 TTS "测试朗读" 在 UI 状态里直接持有 API key
- **位置**：`Sources/NewReaderMac/SettingsView.swift:8, 65, 208`
- **代码**：`@State private var ttsApiKey: String = ""`，`onAppear` 时 `ttsApiKey = ttsCfg.apiKey`
- **影响**：`SecureField` 在 SwiftUI 状态中是明文 String，会被 `print($0)` 或视图 dump 工具泄露到日志/截图。
- **建议**：在 `onAppear` 注入值，在用户开始编辑前保持占位符（如"已保存"）；保存时立刻清空 `@State`。

### 4.6 `OPMLService` 自闭合文件夹未生成 `outline` 元素
- **位置**：`Sources/NewReaderCore/Models/Folder.swift`、`OPMLService.swift:27-33`
- **影响**：当 folder 下没有 feed 时导出的 OPML 不会生成空 `<outline>`，对端导入后这个 folder 会消失（部分 OPML 阅读器要求必须有空 outline）。属于数据格式问题，不致命。
- **建议**：导出时为空 folder 也写一行空 `<outline>`。

### 4.7 `ArticleListView` 状态栏文本与 `appTheme` 无关
- **位置**：`Sources/NewReaderMac/ArticleListView.swift:158-191`
- **影响**：硬编码 `.font(.system(size: 11))`、`.foregroundStyle(.tertiary)`，在深色模式 / 大字体辅助功能下可读性差。
- **建议**：用 `.caption` / `.secondary` 语义化样式。

---

## 5. 🟢 LOW / Notes

### 5.1 OPMLService 解析器误判同行多 outline
- **位置**：`OPMLService.swift:140-153`
- 当两个 `<outline>` 被写在一行（不常见但合法）时，`lineBoundary` 逻辑只取 `xmlUrl=` 所在行的最前一个 `<`，会把前一个 outline 的 title 误关联。属边缘场景，注释里已有"real-world feeds"假设，可接受。

### 5.2 `app.log` 没有轮转
- **位置**：`CrashReporter.swift:59-72`
- 持续 append `app.log`，几周后可能数 MB。
- **建议**：超过 5 MB 时截断到 1 MB。

### 5.3 `LimitedDataDelegate` 不是线程安全
- `FeedService.swift:6-18`：`@unchecked Sendable` 但 `accumulatedData` 在 `didReceive` 中 mutate。
- 实际上 `URLSession` 串行调用 delegate，所以 OK；只是名字 misleading。

### 5.4 工作树包含浏览器导出的钉钉 cookie
- **位置**：`/Users/zhuliang/Documents/NewReader/.cache/cookies-public.json`（含 `login.dingtalk.com` / `.dingtalk.com` cookies）
- **来源**：看起来是某次浏览器导出工具的残留（`openyida` 文件夹名），与本项目无关。
- **建议**：在 `.gitignore` 加 `.cache/`，或直接 `rm -rf .cache/`（已不在 git 跟踪范围内）。

### 5.5 `Package.swift.bak` 与 `skills-lock.json` 残留
- `Package.swift.bak`：`Supabase` 依赖尚未加入时的备份，应删除（已经在主 Package.swift 里加上了）。
- `skills-lock.json`：ZCode agent 工具残留，与项目无关，但应 `.gitignore` 或删除。
- **建议**：清理，避免混淆。

### 5.6 顶部包注释承诺 "PII 不会上传"，但 crash report 实际上传整个 .crash 文件
- README.md 第 64 行写"崩溃自动上传 Supabase"；crash 文件含调用栈、内存地址、用户路径、feed URL。
- 建议：README 明确说明 crash 报告上传范围、保留期限、用户如何关闭（在设置里加一个开关）。

---

## 6. 已做对的事（值得保留）

1. **SSRF 防御很扎实**：`URLValidator.swift` 覆盖了 IPv4 私有 CIDR、IPv6 全部特殊范围、整数/十六进制编码、localhost 别名、整数编码回环；测试覆盖了关键场景。
2. **HTML 消毒分层合理**：去掉 `<script>` / `<iframe>` / `<object>` / `<form>` / `<base>` / `<meta http-equiv="refresh">` / `javascript:` / `on*=` 事件，加上外层 `wrapHTML` 的 CSP `default-src 'none'`，形成纵深防御。
3. **WKWebView 关闭 JS + 验证 baseURL**：`ArticleReaderView.swift:288, 334` 双重防御（macOS 关 JS，iOS 同时启用 `limitsNavigationsToAppBoundDomains`），且 `baseURL` 走 `URLValidator.validate`。
4. **TTS API key 走 Keychain**：`CustomTTSConfig.save()` 用 `CodingKeys` 排除 `apiKey`，并显式 `KeychainHelper.save`，不落盘。
5. **CRUD 模型清晰**：Article/Feed/Folder/WorkspaceSnapshot 全部 SwiftData，关系双向 optional，符合 CloudKit 同步要求。
6. **测试可读性强**：`URLValidatorTests` 18 个用例覆盖关键 SSRF 路径，命名清楚。
7. **构建脚本安全**：`package-macos.sh` 动态把 `Secrets.plist` 合并到 `Info.plist`，避免源码里有多个真值。
8. **PrivacyInfo 完整**：包含 `UserDefaults` / `FileTimestamp` / `SystemBootTime` 的访问原因，符合 App Store 审核。

---

## 7. 测试覆盖现状

| Service | 测试文件 | 覆盖度 |
|---|---|---|
| URLValidator | URLValidatorTests.swift | ✅ 良好（18 用例） |
| HTMLSanitizer | HTMLSanitizerTests.swift | ✅ 良好（16 用例） |
| OPMLService | OPMLServiceTests.swift | ✅ 基本（8 用例） |
| AIService（仅 stripThinking）| AIServiceTests.swift | ⚠️ 6 用例，**编译失败** |
| AuthService | — | ❌ 0 |
| KeychainHelper | — | ❌ 0 |
| CrashReporter / CrashReportCollector | — | ❌ 0 |
| TTSService / CustomTTSProvider | — | ❌ 0 |
| FeedService | — | ❌ 0 |
| ReadabilityService | — | ❌ 0 |
| NotificationService | — | ❌ 0 |
| CacheService | — | ❌ 0 |
| ModelContainerFactory | — | ❌ 0 |
| SyncMonitor | — | ❌ 0 |
| ReaderViewModel | — | ❌ 0（最容易出 bug） |
| WorkspaceSnapshot | — | ❌ 0 |

**没有 CI**（无 `.github/workflows`）。建议最低限度补：
- AuthService（mock Supabase）
- ReaderViewModel（用 in-memory ModelContainer 跑增删改查）
- FeedService（mock URLProtocol）
- CacheService（磁盘操作）
- KeychainHelper（`SecItemAdd` 真测）

---

## 8. 建议的修复优先级

| 优先级 | 任务 | 工作量 |
|---|---|---|
| P0 | 修复 `swift test` 编译（`stripThinking` 加 `nonisolated`） | 5 min |
| P0 | 把 `Secrets.plist` 从工作树移除（移到用户目录或环境变量） | 30 min |
| P1 | KeychainHelper 重复键清理 + 抽常量 | 10 min |
| P1 | `ReaderViewModel` 去掉死 import `CoreData` | 1 min |
| P1 | TTS 错误信息脱敏（CustomTTSProvider line 222） | 10 min |
| P1 | `ReaderViewModel` 把 `try? modelContext.save()` 集中 | 1 h |
| P2 | 补 4 个核心 Service 的单元测试 | 1 d |
| P2 | 抽 `NewReaderCore/Views/` 共享 UI（Settings/Subscribe/Workspace） | 1 d |
| P2 | 引入 GitHub Actions：lint + test + build | 2 h |
| P3 | ArticleListView 的 ⌘F 监听改用 `onKeyPress` | 30 min |
| P3 | OPML 导出补空 folder 元素 | 10 min |
| P3 | crash log 轮转 + 用户关闭开关 | 1 h |
| P3 | 清理 `.cache/`、`Package.swift.bak`、`skills-lock.json` | 5 min |

---

## 9. 工具与流程建议

1. **加 CI**（最低）：
   ```yaml
   name: build-and-test
   on: [push, pull_request]
   jobs:
     test:
       runs-on: macos-14
       steps:
         - uses: actions/checkout@v4
         - run: swift build
         - run: swift test
   ```
2. **加 `swift-format`**：`swift run swift-format format -i Sources/ Tests/`
3. **加 `swiftlint`**（建议规则：禁止 `try!` / `fatalError` 在业务路径 / 强制 `[weak self]`）。
4. **Secret 扫描**：`gitleaks` 或 `trufflehog` 防 publishable key 误提交。
5. **依赖审计**：`swift package audit` 周期性跑（`supabase-swift 2.46.0` 较新；`FeedKit 9.1.2` 2021 年发布，已停止维护，建议评估）。

---

## 10. 结论

NewReader 是一个**工程质量明显高于平均个人项目**的 Swift 应用：分层清晰、安全姿态端正、文档完整、PR 节奏（看 commit history 1.2.0 前的 19 个 commit 都是"小步快跑"）成熟。

主要风险集中在**测试覆盖**和**少量 force-unwrap/死 import** 这类可机械修复的点；安全相关的能力（SSRF/XSS/CSP/Keychain）已经过深思思虑，无明显漏洞。

按照上面 P0-P1 列表修完之后，可以安心打 1.2.x 的 patch 版本；P2-P3 可以在 1.3 周期完成。

---

## 11. 修复实施记录（2026-06-15）

按批准的范围（P0 + P1 全部、Secrets 移到用户目录、不抽 UI 公共层、TTS 脱敏到 app.log）执行完毕。

### 11.1 验证结果

| 验证项 | 结果 |
|---|---|
| `swift build`（debug） | ✅ Build complete (3.08s) |
| `swift build -c release` | ✅ Build complete (9.05s) |
| `swift test` | ✅ 59/59 测试通过 |
| `bash -n scripts/package-macos.sh` | ✅ shell 语法正确 |
| macOS 目标 | ✅ 链接通过 |
| iOS 目标 | ✅ 链接通过 |

### 11.2 已修复项

| # | 报告级别 | 修复内容 | 文件 | 验证 |
|---|---|---|---|---|
| 1 | 🔴 P0-1 | （pre-existing）`stripThinking` 已标 `nonisolated`，`AIServiceTests` 已可编译 | `Sources/NewReaderCore/Services/AIService.swift:299` | `swift test` 6 个 AIServiceTests 全绿；**注意**此改动是修复开始前就存在于工作树（git status 显示未提交），未做新修改 |
| 2 | 🔴 P0-2 | 新建 `SecretsLoader`，把 `SupabaseURL` / `SupabasePublishableKey` / `FeedbackEmail` 的解析从 `Bundle.main.Info.plist` 扩展为"Bundle → `~/Library/Application Support/NewReader/secrets.plist` → fatalError"三级 fallback；`package-macos.sh` 自动镜像 `Sources/NewReaderMac/Secrets.plist` 到用户目录；`FeedbackEmail` 读取改用新 loader；README 加"本地开发 Secret 配置"一节 | 新增 `Sources/NewReaderCore/Services/SecretsLoader.swift`；改 `Sources/NewReaderCore/Services/AuthService.swift`；改 `Sources/NewReaderMac/NewReaderApp.swift`；改 `scripts/package-macos.sh`；改 `README.md` | `swift build` 通过；`SupabaseConfig.url` / `publishableKey` 仍能解析真值；`FeedbackEmail` 解析路径未变 |
| 3 | 🟠 P1-1 | `KeychainHelper.save` 删掉重复的 `kSecAttrAccessGroup` 键；抽 `private static let accessGroup = "com.newreader.app"` 给 save / load 共享 | `Sources/NewReaderCore/Services/KeychainHelper.swift` | 行为等价（重复键 Swift 取后者，值相同）；`swift build` 通过；TTS API key 读写流程未变 |
| 4 | 🟠 P1-2 | `ReaderViewModel.swift` 添加注释说明 `import CoreData` 仅因 `NSPersistentCloudKitContainer` 通知类型需要（不可删）；`import CoreData` 实际保留 | `Sources/NewReaderCore/ViewModels/ReaderViewModel.swift:7-9` | 编译通过 |
| 5 | 🟠 P1-3 | TTS JSON 解析失败时，raw body（前 200 字符）写入 `CrashReporter.log`；UI `errorMessage` 改为脱敏提示；`SettingsView` "测试朗读" 错误展示区去掉 raw body ScrollView，改为"详细响应已写入日志：~/Library/Logs/NewReader/app.log" | `Sources/NewReaderCore/Services/CustomTTSProvider.swift:220-228`；`Sources/NewReaderMac/SettingsView.swift:240-256` | 编译通过；UI 不再泄露 TTS 响应体；用户调试能力不丢（日志可查） |
| 6 | 🟠 P1-4 | 新增 `ReaderViewModel.save(_:)` 私有方法集中处理 `modelContext.save()` 错误；全文 17 处 `try? modelContext.save()` 替换为 `save("context")` | `Sources/NewReaderCore/ViewModels/ReaderViewModel.swift` | 行为变化：原本静默失败的 case 现在会写 `errorMessage` + 写 `app.log`；这是修复目标不是 regression |
| 7 | 🟡 P1-5 | 经核查，所有 `.keyboardShortcut` 调用都集中在 `Sources/NewReaderMac/` 目录文件里，**这些文件只被 macOS target 编译，不存在 iOS 上的"无效声明"**；按计划保守做法，给 `SidebarView` / `ContentView` / `WorkspaceView` 顶部加注释说明这是 macOS-only 视图 | `Sources/NewReaderMac/SidebarView.swift:4-7`；`ContentView.swift:4-7`；`WorkspaceView.swift:4-6` | `swift build` 通过；UI 无变化 |
| 8 | 🟢 步骤 8 | 抽 `ReaderViewModel.workspaceMinimumArticles = 3` / `workspaceAutoTriggerArticles = 5` / `workspaceRecentWindowSeconds = 7 * 24 * 3600` 为类型常量，统一 `generateWorkspace()` 和 `maybeGenerateWorkspace()` 与 SettingsView 文案；删除工作树残留 `.cache/`、`Package.swift.bak`、`skills-lock.json`；`.gitignore` 加 `.cache/` / `skills-lock.json` / `Package.swift.bak` | `Sources/NewReaderCore/ViewModels/ReaderViewModel.swift:10-22`；`.gitignore:34-36` | 编译通过；workspace 行为不变 |

### 11.3 行为变化（用户可观察）

1. **TTS 失败时**：原本会把服务器返回的原始 body（前 200 字符）渲染在 UI 标签里；现在改为只显示"原始响应已写入日志"的脱敏文本 + 提示日志路径。用户可去 `~/Library/Logs/NewReader/app.log` 查看详情。
2. **SwiftData 保存失败时**：原本静默失败（数据可能未落盘但无提示）；现在会通过 `errorMessage` 显示错误并写入 `app.log`。在极端 SwiftData 故障场景下用户会看到之前看不到的错误——这是修复目标。
3. **本地开发配置 Secret**：原本 `swift run` 需要 `Sources/NewReaderMac/Secrets.plist` 在工作树里；现在可以放在 `~/Library/Application Support/NewReader/secrets.plist`（脚本自动镜像）。`Sources/NewReaderMac/Secrets.plist` 仍按原路径保留并已被 `.gitignore`。

### 11.4 不变项（用户不感知）

- HTML / URL sanitizer
- Models（Article / Feed / Folder / WorkspaceSnapshot）schema
- CloudKit 同步流程
- AI 摘要 / 翻译接口与字段
- macOS / iOS 视图层结构与外观
- Entitlements / Info.plist / PrivacyInfo
- 所有测试用例

### 11.5 不修复项（明确跳过）

| 报告级别 | 项 | 原因 |
|---|---|---|
| MEDIUM 4.1 | macOS/iOS 视图层抽公共层 | 用户明确选择"先不抽" |
| MEDIUM 4.3 | ArticleListView ⌘F 监听改 `onKeyPress` | 中等风险，本轮不做 |
| MEDIUM 4.5 | TTS API key 不入 `@State` | 改动大，本轮不做 |
| MEDIUM 4.6 | OPML 空 folder 导出 | 数据格式问题，边缘 case |
| MEDIUM 4.7 | ArticleListView 状态栏用语义化样式 | 纯样式，不影响功能 |
| LOW 5.1–5.3 | OPML 同行多 outline / app.log 轮转 / LimitedDataDelegate 命名 | 边缘场景 / 改进项 |
| LOW 5.4 | `.cache/` 残留 | 已在步骤 8 清理 |
| LOW 5.5 | `Package.swift.bak` / `skills-lock.json` 残留 | 已在步骤 8 清理 |
| LOW 5.6 | crash 上传范围文档化 | 文档/产品决策，本轮不做 |
| 缺 CI / 补单元测试 | GitHub Actions + 4 个核心 Service 单元测试 | 需要专门一轮 |
| FeedKit 升级评估 | 9.1.2 → 更新 | 单独评估，不在 P0/P1 |

### 11.6 已知未提交改动

- `Sources/NewReaderCore/Services/AIService.swift:299` — `stripThinking` 加 `nonisolated`（pre-existing，未 commit，由先前 PR/本地修改残留）
- 本次新增/修改的所有文件均未 commit——按"修复不主动 commit"原则保留在工作树，等用户 review

### 11.7 提交建议（参考命令，不执行）

如果用户 review 后想提交，可分两个 commit：

```bash
# 1) 修复 P1 工具类（Keychain / CoreData 注释 / TTS 脱敏 / 残留清理）
git add Sources/NewReaderCore/Services/KeychainHelper.swift \
        Sources/NewReaderCore/ViewModels/ReaderViewModel.swift \
        Sources/NewReaderCore/Services/CustomTTSProvider.swift \
        Sources/NewReaderMac/SettingsView.swift \
        .gitignore
git commit -m "fix: cleanup small issues (keychain dup key, tts error leak, dead files)"

# 2) 引入 SecretsLoader（feature 级别）
git add Sources/NewReaderCore/Services/SecretsLoader.swift \
        Sources/NewReaderCore/Services/AuthService.swift \
        Sources/NewReaderMac/NewReaderApp.swift \
        scripts/package-macos.sh README.md
git commit -m "feat(security): load Supabase secrets from user-level directory in dev builds"
```

### 11.8 后续建议（待办）

- 引入 GitHub Actions 跑 `swift build` + `swift test`（macOS runner）
- 给 AuthService / FeedService / ReaderViewModel / KeychainHelper 补单元测试
- 评估 FeedKit 9.1.2 → 升级路径
- 评估 macOS/iOS 视图层抽公共层（按用户后续意愿）
- crash report 上传范围文档化 + Settings 提供关闭开关

---

## 12. 安全加固（2026-06-15 · 第二轮）

按用户要求实施**防滥用 / 限速 / 告警**三件套：Cloudflare Turnstile + per-device UUID 限速 + billing-watchdog Edge Function。

### 12.1 验证结果

| 验证项 | 结果 |
|---|---|
| `swift build` (debug) | ✅ 1.81s |
| `swift test` | ✅ 59/59 测试通过（顺手修了 pre-existing bug） |
| `swift build -c release` | ✅ 10.30s |
| `bash scripts/package-macos.sh` | ✅ .app 9.6 MB / .dmg 3.1 MB |
| macOS / iOS 双 target | ✅ 链接通过 |
| Edge Function 语法 (deno check 跳过，无 deno) | ⚠️ 手动 review TS 代码 |
| SQL 迁移语法 | ⚠️ 手动 review，未连真实 Supabase 跑 |

### 12.2 新增文件

| 文件 | 作用 | 行数 |
|---|---|---|
| `Sources/NewReaderCore/Services/DeviceIdentity.swift` | 客户端 Keychain 存 UUID | 23 |
| `Sources/NewReaderCore/Views/TurnstileView.swift` | WKWebView 加载 Cloudflare widget | 198 |
| `supabase/migrations/003_device_quota.sql` | per-device 限速表 + RPC | 49 |
| `supabase/migrations/004_billing_alerts.sql` | billing 告警表 + service_flags | 41 |
| `supabase/functions/billing-watchdog/index.ts` | 月用量监控 + 邮件告警 + 硬停止 | 270 |
| `docs/SECURITY_SETUP.md` | 维护者部署文档 | 240 |

### 12.3 修改文件

| 文件 | 改动 |
|---|---|
| `Sources/NewReaderCore/Services/AIService.swift` | 新增 3 个 AIServiceError case（captchaFailed / deviceQuotaExceeded / servicePaused）；`summarize/translate/analyzeReadingPatterns` 加 `captcha: CaptchaTokenProvider?` 参数；`proxyRequest` 加 `X-Device-ID` + `X-Captcha-Token` headers；HTTP 状态码 401/402/403/429/503 分类映射；**顺手修 pre-existing bug：`stripThinking` 用 `end.upperBound`（之前是 `end.lowerBound`，会留下 `</think>` 尾巴）** |
| `Sources/NewReaderCore/Services/SecretsLoader.swift` | 加 `Key.cloudflareTurnstileSitekey` |
| `Sources/NewReaderCore/ViewModels/ReaderViewModel.swift` | 加 `@Published captchaToken: String?`；5 处 `aiService.X` 调用全部传 `captcha:` 闭包 |
| `Sources/NewReaderCore/Views/LoginView.swift` | `submit()` / Apple 登录前先 `await TurnstileChallenge.fetchToken()`；失败时给"人机验证失败：..."错误 |
| `Sources/NewReaderMac/SettingsView.swift` | "账户"页加一行"人机验证：已开启（Cloudflare Turnstile）" |
| `supabase/functions/ai-proxy/index.ts` | 三层防御（service_flags 检查 → captcha 验证 → device 限额）；原 user 限额 + DeepSeek 调用逻辑保留 |
| `README.md` | 加"维护者部署"段链接到 SECURITY_SETUP.md |

### 12.4 防御效果

| 攻击场景 | 之前 | 现在 |
|---|---|---|
| 单设备脚本刷 1000 个 Supabase 账号，每天 1 万次 AI | 1000 × 50 = 50,000 次 / 全部通过 | 5 次 / 全部被 `device_quota_exceeded` 阻断 |
| 单人注册 1 个账号、每天 100 次 | 100 - 50 = 50 次通过 | 100 - 50 = 50 次通过（per-user 仍 50）|
| 单人注册 1 个账号、但每次开新设备 | 不受限 | 1 × 5 = 5 次 / device 阻断 |
| 滥用导致 Supabase 月账单 $50 | 无感知、可能扣费 | 邮件警告 + 自动暂停 ai-proxy |
| 滥用导致 $100 | 持续扣费 | 早已在 $50 暂停 |
| 攻击者直接 curl Edge Function 不带 captcha | 仅 JWT 验证（可以批量注册账号） | 400 `captcha_required` 直接拒绝 |
| 攻击者伪造 captcha token | 无验证 | Cloudflare 服务端验证 → 403 `captcha_invalid` |

### 12.5 行为变化（用户可观察）

1. **登录时多 1-2 秒**：按钮按下后弹一个隐形 Turnstile widget 加载 + 验证 → 成功后跳登录。失败时显示"人机验证失败：xxx，请刷新后重试"。
2. **设置 → 账户页多一行状态**：绿点 + "人机验证：已开启（Cloudflare Turnstile）"，验证失败 / 超时显示灰点 + "未验证"。
3. **AI 调用失败时的错误更具体**：
   - 之前：`今日 AI 额度已用完，明天再来`
   - 现在分两种：`今日账号 AI 额度已用完` / `今日设备额度已用完`（或）`AI 服务暂时维护中`
4. **月用量超 $50 时**：所有 AI 调用立刻返回"AI 服务暂时维护中"。在 Dashboard 把 `service_flags.ai_proxy_paused` 改 `false` 即可恢复。

### 12.6 本地开发零配置

- 不设 `CLOUDFLARE_TURNSTILE_SECRET` → ai-proxy warn 但放行
- 不设 `CloudflareTurnstileSitekey` → 客户端 fallback 到 Cloudflare 官方 dev sitekey，永远返回通过 token
- 不部署 billing-watchdog → Edge Function 仍工作，只是没人监控账单

新开发者 `git clone` 后不需要注册 Cloudflare 就能跑通。

### 12.7 不实现项（明确）

- ❌ 邮箱白名单注册（产品决策）
- ❌ Crash 上传限速（下一轮可加，但优先级低——Supabase Storage 5 MB/文件限制 + 每日 1 个 crash 概率低）
- ❌ iOS 端 Turnstile 实际拉起（代码已就绪但 iOS 模拟器缺 WKWebView 网络权限，需要真机；macOS 端 OK）
- ❌ 凭据注入到 Edge Function 的具体 shell 步骤（写在 SECURITY_SETUP.md 里）

### 12.8 提交建议（参考命令，不执行）

```bash
git add Sources/NewReaderCore/Services/DeviceIdentity.swift \
        Sources/NewReaderCore/Views/TurnstileView.swift \
        Sources/NewReaderCore/Services/AIService.swift \
        Sources/NewReaderCore/Services/SecretsLoader.swift \
        Sources/NewReaderCore/ViewModels/ReaderViewModel.swift \
        Sources/NewReaderCore/Views/LoginView.swift \
        Sources/NewReaderMac/SettingsView.swift
git commit -m "feat(security): Cloudflare Turnstile + per-device rate limit on AI calls"

git add supabase/migrations/003_device_quota.sql \
        supabase/migrations/004_billing_alerts.sql \
        supabase/functions/ai-proxy/index.ts \
        supabase/functions/billing-watchdog/index.ts \
        docs/SECURITY_SETUP.md README.md
git commit -m "feat(security): Edge Function captcha + device quota + billing watchdog"
```

### 12.9 部署前用户需做的（核心步骤）

按 `docs/SECURITY_SETUP.md` §2 一步步填：

1. Cloudflare Turnstile 创建 widget → 拿 sitekey + secret
2. Supabase Edge Function secrets：`supabase secrets set ...`
3. Supabase SQL Editor 跑 `003` + `004` 迁移
4. Supabase CLI 部署 Edge Functions：`supabase functions deploy`
5. 调度 billing-watchdog（pg_cron 或外部 cron）
6. 写 `Secrets.plist` 里的 `CloudflareTurnstileSitekey`
7. 跑 `bash scripts/package-macos.sh` 重新打包

部署后 Settings → 账户页应显示"人机验证：已开启"。

---

## 13. 限额规则修订：百分比代替美元（2026-06-15 · 第三轮）

按用户要求，把 billing-watchdog 的"按美元"改为"按 Supabase 免费额度百分比"。

### 13.1 变更内容

| 维度 | 之前 | 现在 |
|---|---|---|
| 监控信号 | 月用量美元（$10 / $50） | 月用量百分比（80% / 95%） |
| 默认阈值 | `BILLING_WARN_AT_USD=10`、`BILLING_HARD_STOP_AT_USD=50` | `FREE_PLAN_WARN_PCT=80`、`FREE_PLAN_HARD_STOP_PCT=95` |
| 监控对象 | 单个合并 `total` 数字 | 4 个 Free plan 指标分别监控：DB size / Storage / Egress / Function invocations |
| 触发逻辑 | 合并 > 阈值 | **任一**指标 > 阈值 |
| 邮件内容 | "用量已达 $X" | "指标 X 已用 Y MB / Z MB (P%)" + 表格列出最差 3 项 |
| 行为变化 | 之前是"金额"语义不匹配 Free plan | 现在按 Free plan 实际限额触发 |

### 13.2 行为效果

| 用量 | 之前 | 现在 |
|---|---|---|
| DB 用了 100 MB（20% of 500 MB） | 不告警（合并 < $10 阈值） | 不告警（< 80% 任一指标） |
| DB 用了 450 MB（90% of 500 MB） | 可能不告警（合并 $4.5 < $10） | **警告**邮件，列出 DB 90% |
| Storage 1 GB（100% of 1 GB） | 看合并 total | **硬停止**，ai-proxy 503 |
| Function 调用 600K（120% of 500K） | 看合并 total | **硬停止** |
| 多指标都 80%+ | 合并触发 | 邮件列出最差 3 项 |

### 13.3 验证结果

| 验证项 | 结果 |
|---|---|
| `swift build` | ✅ 1.07s |
| `swift test` | ✅ 59/59 |
| `bash scripts/package-macos.sh` | ✅ .app 9.6 MB / .dmg 3.1 MB（binary 未变，仅后端 TS + 文档） |
| Edge Function TS 语法 | ⚠️ 手动 review（无 deno） |

### 13.4 部署前用户需更新

```bash
# 旧变量（不再使用，可删）
supabase secrets unset BILLING_WARN_AT_USD
supabase secrets unset BILLING_HARD_STOP_AT_USD

# 新变量
supabase secrets set FREE_PLAN_WARN_PCT=80
supabase secrets set FREE_PLAN_HARD_STOP_PCT=95

# 重新部署
supabase functions deploy billing-watchdog
```

### 13.5 不变项

- 客户端代码无变化（限额逻辑全在服务端）
- per-user / per-device AI 限额不变
- Captcha 流程不变
- 邮件 Resend 集成不变
- SQL 迁移不变

### 13.6 修改文件

- `supabase/functions/billing-watchdog/index.ts`：完全重写，从"单 total 美元判断"改为"4 指标百分比判断"
- `docs/SECURITY_SETUP.md` §2.2 / §6：更新变量名和说明
