# NewReader

精致、安全的 RSS 阅读器，内置 AI 摘要与翻译、TTS 语音朗读、全文提取。支持 macOS 15+ 与 iOS 18+。

![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift)
![macOS](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple)
![iOS](https://img.shields.io/badge/iOS-18%2B-000000?logo=apple)
![License](https://img.shields.io/badge/license-MIT-blue)

[🌐 产品介绍](https://newreader.netlify.app) · [📦 下载最新版](https://github.com/yueraaaa/NewReader/releases/latest)

---

## ✨ 特性

| 特性 | 说明 |
|------|------|
| **多格式订阅** | 支持 RSS 2.0、Atom、JSON Feed，自动解析 |
| **AI 摘要** | 接入 OpenAI 兼容 API（支持 DeepSeek / 通义千问等），一键生成文章摘要 |
| **多语翻译** | 中文、英语、日语、韩语互译 |
| **TTS 语音朗读** | 支持 Apple 系统语音 + 自定义 TTS API 双引擎，可调语速，断点续播 |
| **全文提取** | 从摘要 Feed 自动拉取完整正文 |
| **离线缓存** | 本地缓存文章，断网可读 |
| **OPML 导入导出** | 迁移订阅源一键完成 |
| **崩溃上报** | 崩溃自动上传至 Supabase，邮件实时通知 |
| **iCloud 同步** | SwiftData + CloudKit 跨设备自动同步订阅源、文章、阅读状态 |
| **订阅源改名** | 右键订阅源可重命名，iOS 左滑即可操作 |
| **分类管理** | 新建分类收纳订阅源，支持折叠、重命名、删除 |
| **主题切换** | 浅色/深色/跟随系统，即时生效 |
| **键盘导航** | J/K 键浏览文章，阅读更高效 |
| **自动已读** | 打开文章自动标记已读，蓝点即时消失 |
| **即显提示** | 工具栏图标悬停即时显示功能说明，无需等待 |
| **安全优先** | API Key Keychain 加密存储、WKWebView 禁用 JS、IPv6 SSRF 防护、HTML 深度消毒 |

## 🔒 安全性

- **API Key**：使用 macOS/iOS Keychain 加密存储，不落盘明文
- **WKWebView**：禁用 JavaScript + Content-Security-Policy，阻止脚本注入
- **URL 校验**：协议白名单（仅 http/https）+ 私有 IP 拦截，防 SSRF
- **HTML 消毒**：移除 script / iframe / 事件处理器 / javascript: 链接
- **OPML**：导入文件大小上限 5MB，防内存耗尽

## 🛠 技术栈

Swift 6 · SwiftUI · SwiftData · FeedKit · WKWebView · AVFoundation · OpenAI API

## 🚀 构建

```bash
# macOS
swift build -c release
./.build/release/NewReaderMac

# 或使用 Xcode
open Package.swift
```

**依赖**：macOS 15+ / iOS 18+，Xcode 16+。

## 📦 安装

### macOS

从 [Releases](https://github.com/yueraaaa/NewReader/releases) 下载 `NewReader-macOS.zip`，解压后拖入 `/Applications`。

首次运行时，由于未签名，请在 **系统设置 → 隐私与安全性** 中点击「仍要打开」。

### iOS

通过 Xcode 编译安装到设备。

## 🔑 配置 AI

1. 打开应用 → **设置**（⌘,）→ **AI**
2. 填入 OpenAI 兼容 API 端点（默认 `https://api.openai.com/v1`）
3. 填入 API Key
4. 选择模型（如 `gpt-4o-mini`、`deepseek-chat`）
5. 保存

支持任何 OpenAI 兼容服务：OpenAI、Azure、DeepSeek、通义千问等。

## 📄 许可

MIT License
