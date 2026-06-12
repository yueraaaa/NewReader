# NewReader

精致、安全的 RSS 阅读器，内置 AI 摘要与翻译、TTS 语音朗读、全文提取、阅读兴趣分析。支持 macOS 15+ 与 iOS 18+。

![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift)
![macOS](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple)
![iOS](https://img.shields.io/badge/iOS-18%2B-000000?logo=apple)
![License](https://img.shields.io/badge/license-MIT-blue)

[🌐 产品介绍](https://newreader.netlify.app) · [📦 下载最新版](https://github.com/yueraaaa/NewReader/releases/latest) · [📖 使用文档](https://newreader.netlify.app/docs)

[English](README_EN.md) · [中文](#-特性)

---

## ✨ 特性

| 特性 | 说明 |
|------|------|
| **多格式订阅** | 支持 RSS 2.0、Atom、JSON Feed，自动解析 |
| **AI 摘要** | OpenAI 兼容 API，一键生成文章摘要 |
| **多语翻译** | 中文、英语、日语、韩语互译 |
| **TTS 语音朗读** | Apple 系统语音 + 自定义 TTS API 双引擎，断点续播 |
| **全文提取** | 从摘要 Feed 自动拉取完整正文 |
| **离线缓存** | 本地缓存文章，断网可读 |
| **OPML 导入导出** | 迁移订阅源一键完成 |
| **崩溃上报** | 崩溃自动上传 Supabase，邮件实时通知 |
| **iCloud 同步** | SwiftData + CloudKit，跨设备自动同步 |
| **分类管理** | 新建分类收纳订阅源，可折叠、重命名、删除 |
| **工作台分析** | AI 分析阅读兴趣，生成关键词关系图谱 |
| **主题切换** | 浅色 / 深色 / 跟随系统，即时生效 |
| **键盘导航** | J/K 键浏览文章，⌘F 聚焦搜索，全键盘高效操作 |
| **日期分组** | 文章按今天 / 昨天 / 本周自动分组，快速定位 |
| **安全优先** | Keychain 加密、WKWebView 沙箱、SSRF 防护、HTML 深度消毒 |

## 🔒 安全性

- **API Key**：使用 macOS / iOS Keychain 加密存储，明文不落磁盘
- **WKWebView**：禁用 JavaScript + Content-Security-Policy，阻止脚本注入
- **URL 校验**：协议白名单（仅 http/https）+ 全量私有 IP / IPv6 拦截，防 SSRF
- **HTML 消毒**：移除 script / iframe / 事件处理器 / javascript: / base / form / meta refresh
- **OPML 限制**：导入文件大小上限 5MB，防内存耗尽
- **App Sandbox**：macOS App Sandbox 启用，进程级隔离

## 🛠 技术栈

Swift 6 · SwiftUI · SwiftData · FeedKit · WKWebView · AVFoundation · Supabase · CloudKit

## 🚀 构建

```bash
# macOS
swift build -c release
cp .build/release/NewReaderMac NewReader.app/Contents/MacOS/NewReaderMac
open NewReader.app

# 或使用打包脚本
bash scripts/package-macos.sh
```

**依赖**：macOS 15+ / iOS 18+，Xcode 16+。

## 📦 安装

### macOS

从 [Releases](https://github.com/yueraaaa/NewReader/releases) 下载 `NewReader.dmg`，打开后将 **NewReader.app** 拖入 `/Applications`。

首次运行时，在 **系统设置 → 隐私与安全性** 中点击「仍要打开」。

### iOS

通过 Xcode 编译安装到设备。打开 `Package.swift`，选择 **NewReaderiOS** target，连接 iPhone 后运行。

## 📄 许可

MIT License
