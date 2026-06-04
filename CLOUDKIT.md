# CloudKit 同步配置指南

NewReader 使用 SwiftData + CloudKit 实现跨设备同步。以下是在本地运行 / 发布时需要完成的配置。

## 前提条件

- 有效的 Apple Developer Program 会员
- Xcode 16+

## 1. 在 Apple Developer 中配置 CloudKit Container

1. 登录 [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. 选择 **Identifiers** → 找到 App ID (`com.newreader.app`)
3. 勾选 **iCloud** 能力 → 勾选 **CloudKit**
4. 创建 / 使用容器 `iCloud.com.newreader.app`

## 2. Xcode 项目配置

本项目为 Swift Package,打开 `Package.swift` 即可在 Xcode 中工作:

### macOS (NewReaderMac)

1. 选择 target → **Signing & Capabilities**
2. Team 选择你的开发者账号
3. **+ Capability** → **iCloud**
   - 勾选 **CloudKit**
   - Container 选择 `iCloud.com.newreader.app`
4. **+ Capability** → **Background Modes**
   - 勾选 **Remote Notifications** (用于 CloudKit 静默推送)
5. `NewReaderMac/NewReader.entitlements` 中 `aps-environment` 改为 `production`（发布）

### iOS (NewReaderiOS)

步骤与 macOS 相同,使用 `Sources/NewReaderiOS/NewReader.entitlements`。

## 3. 编译与打包

### 命令行（仅本地测试,不含签名）

```bash
swift build -c release
```

CLI 构建 **不包含** iCloud 权限,CloudKit 初始化为静默失败 → 应用退化到本地持久存储。

### Xcode（含 CloudKit）

在 Xcode 中 Archive → Distribute App,使用 Developer ID（macOS 独立分发）或 App Store Connect（iOS）。

### macOS 打包脚本

```bash
bash scripts/package-macos.sh
```

生成的 `.app` bundle 已包含 entitlements 文件,但必须通过 Xcode 或 `codesign` 对其签名后 CloudKit 才会生效:

```bash
codesign --deep --force --verbose --sign "Developer ID Application: ..." \
  --entitlements Sources/NewReaderMac/NewReader.entitlements \
  NewReader.app
```

## 4. 工作原理

```
init() → ModelContainerFactory.makeContainer()
  ├─ Tier 1: CloudKit(.private("iCloud.com.newreader.app"))
  │   ├─ 成功 → 自动同步 Feed/Article/Folder
  │   └─ 失败 → 回退到 Tier 2
  ├─ Tier 2: 本地持久 SQLite
  │   └─ 失败 → 回退到 Tier 3
  └─ Tier 3: 内存 (不保存)
```

- **未登录 iCloud** → Tier 1 可能成功初始化容器,但同步暂停。UI 显示"未激活",用户登录后自动恢复。
- **首设备已使用** → 已有本地数据不会自动迁移到 CloudKit,需在同一设备继续使用或在其他设备重新添加订阅源。
- **Article.contentHTML** → 大长文可能超过 CloudKit 单条记录 1 MB 上限,极端情况下该文章不同步（不影响其他数据）。

## 5. UI 状态

- **设置 → 存储** 面板显示 iCloud 同步状态（绿点 = 已激活,灰点 = 未激活）
- **未登录** → 显示提示:登录 iCloud 后自动开启跨设备同步
- **已登录** → 显示:Feed 和文章自动通过 iCloud 同步
