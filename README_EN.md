# NewReader

A polished, secure RSS reader with AI summarization, multi-language translation, TTS voice reading, and reading-interest analysis. Built with Swift 6 + SwiftUI. Available on macOS 15+ and iOS 18+.

![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift)
![macOS](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple)
![iOS](https://img.shields.io/badge/iOS-18%2B-000000?logo=apple)
![License](https://img.shields.io/badge/license-MIT-blue)

[🌐 Website](https://newreader.netlify.app) · [📦 Latest Release](https://github.com/yueraaaa/NewReader/releases/latest) · [📖 Documentation](https://newreader.netlify.app/docs_en)

[中文 README](README.md) · [English](#-features)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Multi-format Feeds** | RSS 2.0, Atom, JSON Feed — auto-parsed |
| **AI Summarization** | OpenAI-compatible API, one-tap summaries |
| **Translation** | Chinese ↔ English / Japanese / Korean |
| **TTS Reading** | Apple system voice + custom TTS API, pause & resume |
| **Full-text Extraction** | Auto-fetch full articles from summary feeds |
| **Offline Cache** | Read cached articles offline |
| **OPML Import/Export** | One-click feed migration |
| **Crash Reporting** | Auto-upload to Supabase, instant email notification |
| **iCloud Sync** | SwiftData + CloudKit, cross-device auto-sync |
| **Category Management** | Organize feeds into collapsible, renamable categories |
| **Workspace Analysis** | AI-powered reading-interest keyword graph |
| **Theme Switching** | Light / Dark / System, instant |
| **Keyboard Navigation** | J/K to browse, \u2318F to search, full keyboard control |
| **Date Grouping** | Articles grouped by Today / Yesterday / This Week |
| **Security First** | Keychain encryption, WKWebView sandbox, SSRF prevention, HTML sanitization |

## 🔒 Security

- **API Key**: Encrypted in macOS/iOS Keychain, never in plaintext
- **WKWebView**: JavaScript disabled + Content-Security-Policy
- **URL Validation**: HTTPS/HTTP only, full private IP / IPv6 blocking (SSRF prevention)
- **HTML Sanitization**: Strips script, iframe, event handlers, javascript:, base, form, meta refresh
- **OPML Limit**: 5 MB max file size on import
- **App Sandbox**: macOS App Sandbox enabled, process-level isolation

## 🆕 What's new in v1.3.0

- 🛡️ **Cloudflare Turnstile** invisible CAPTCHA (login + every AI call)
- 📱 **Per-device rate limit**: 5 AI calls/day/device (Keychain UUID)
- 👤 **Per-user rate limit**: 50 AI calls/day (existing)
- 📊 **billing-watchdog** Edge Function: monitors Supabase free tier (80% warn / 95% hard-stop)
- 🔄 **ai-proxy auto-resume** when usage drops below threshold
- 🐛 Fix `stripThinking` leaking `</think>`, KeychainHelper duplicate key, `try?` silent failure, TTS error body leak
- 📖 New doc [`docs/SECURITY_SETUP.md`](docs/SECURITY_SETUP.md) — operator deployment guide

Full audit trail in [`CODE_AUDIT_REPORT.md`](CODE_AUDIT_REPORT.md).

## 🛠 Tech Stack

Swift 6 \u00b7 SwiftUI \u00b7 SwiftData \u00b7 FeedKit \u00b7 WKWebView \u00b7 AVFoundation \u00b7 Supabase \u00b7 CloudKit

## 🚀 Build

```bash
# macOS
swift build -c release
cp .build/release/NewReaderMac NewReader.app/Contents/MacOS/NewReaderMac
open NewReader.app

# Or use the packaging script
bash scripts/package-macos.sh
```

**Requirements**: macOS 15+ / iOS 18+, Xcode 16+.

## 📦 Installation

### macOS

Download `NewReader.dmg` from [Releases](https://github.com/yueraaaa/NewReader/releases), open it, and drag **NewReader.app** into `/Applications`.

On first launch, go to **System Settings → Privacy & Security** and click "Open Anyway".

### iOS

Build and install via Xcode. Open `Package.swift`, select the **NewReaderiOS** target, connect your iPhone, and run.

## 📄 License

MIT License
