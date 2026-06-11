# NewReader

A polished, secure RSS reader with AI summarization, multi-language translation, and TTS voice reading. Built with Swift 6 + SwiftUI. Available on macOS 15+ and iOS 18+.

![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift)
![macOS](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple)
![iOS](https://img.shields.io/badge/iOS-18%2B-000000?logo=apple)
![License](https://img.shields.io/badge/license-MIT-blue)

[🌐 Website](https://newreader.netlify.app) · [📦 Latest Release](https://github.com/yueraaaa/NewReader/releases/latest) · [中文 README](README.md)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Multi-format Feeds** | RSS 2.0, Atom, JSON Feed — auto-parsed |
| **AI Summarization** | One-tap article summaries via OpenAI-compatible API |
| **Translation** | Chinese ↔ English / Japanese / Korean |
| **TTS Reading** | Apple system voice + custom TTS API, pause & resume |
| **Full-text Extraction** | Auto-fetch full articles from summary feeds |
| **Offline Cache** | Read cached articles without internet |
| **OPML Import/Export** | One-click feed migration |
| **Crash Reporting** | Auto-upload to Supabase, instant email notification |
| **iCloud Sync** | SwiftData + CloudKit, cross-device auto-sync |
| **Theme Switching** | Light / Dark / System, instant |
| **Keyboard Navigation** | J/K keys to browse articles |

## 🔒 Security

- **API Key**: Encrypted in macOS/iOS Keychain, never stored in plaintext
- **WKWebView**: JavaScript disabled + Content-Security-Policy
- **URL Validation**: HTTPS/HTTP only, private IP / localhost blocked (SSRF prevention)
- **HTML Sanitization**: script / iframe / event handlers / javascript: links removed
- **OPML Limit**: 5 MB max file size on import
- **App Sandbox**: macOS App Sandbox enabled

## 🛠 Tech Stack

Swift 6 · SwiftUI · SwiftData · FeedKit · WKWebView · AVFoundation · Supabase

## 🚀 Build

```bash
# macOS
swift build --target NewReaderMac -c release

# Package as .app bundle
bash scripts/package-macos.sh
```

See [中文 README](README.md) for detailed Chinese documentation.
