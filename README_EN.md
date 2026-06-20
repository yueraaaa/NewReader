# REAL READER

A cross-platform RSS reader built with Flutter. Integrated with AI translation/summarization (Minimax), cloud sync (Supabase), and a premium magazine-style UI design system.

## Features

- **RSS Subscription Management** — Add, edit, delete, and categorize RSS feeds
- **Article Reading** — List view, read/unread status, favorites, reading progress tracking
- **OPML Import/Export** — Standard OPML format, migrate from other readers
- **AI Enhancement** — One-click translation to Chinese, smart summarization, text-to-speech
- **Cloud Sync** — Supabase real-time sync, seamless multi-device experience
- **Third-party Login** — Apple / GitHub / Email one-click login
- **Ad-free · No registration limits · Lightweight**

## Supported Platforms

- macOS
- Windows
- iOS

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x / Dart 3.x |
| State Management | flutter_bloc |
| Local Storage | sqflite (SQLite) |
| Cloud Service | Supabase |
| AI Service | Minimax API |
| RSS Parsing | webfeed_revised |
| Routing | go_router |

## Quick Start

### Install Dependencies

```bash
flutter pub get
```

### Run

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# iOS
flutter run -d iphone
```

### Build

```bash
flutter build macos
flutter build ios
flutter build windows
```

## API Configuration

Configure on first use via in-app settings or environment variables:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase Project URL |
| `SUPABASE_ANON_KEY` | Supabase Anonymous Key |
| `MINIMAX_API_KEY` | Minimax API Key |
| `MINIMAX_GROUP_ID` | Minimax Group ID |

Or configure directly in the app at「Settings > API Configuration」.

## Login & Sync

### Usage Modes

| Scenario | Login Required | Cloud Sync |
|----------|---------------|------------|
| Supabase not configured | ❌ No | ❌ Unavailable |
| Supabase configured | ✅ Yes | ✅ Available |

### Login Flow

```
App Launch
    │
    ▼
Check if Supabase is configured
    │
    ├─ No → Enter main interface (offline mode, all data stored locally)
    │
    └─ Yes → Show login page
              │
              ▼
        Choose login method: Apple / GitHub / Email
              │
              ▼
           Login success
              │
              ▼
         Enter main interface (cloud sync enabled)
```

### Third-party Login

- **Apple Login**: Via Supabase OAuth, one-click sign-in
- **GitHub Login**: Via Supabase OAuth, one-click sign-in
- **Email Login**: Enter email + password, or register a new account

### Data Sync

- **Local-first**: All operations write to local SQLite first, immediate response
- **Silent sync**: Background async push to Supabase, network errors don't affect local usage
- **Multi-device sync**: After login, data automatically stays in sync across all devices

To enable multi-device sync, configure Supabase in「Settings > API Configuration」and log in.

## Project Structure

```
lib/
├── core/              # Core: theme, routing, configuration
├── data/              # Data layer: models, datasources, repository implementations
├── domain/           # Business layer: entities, repository interfaces
└── presentation/      # Presentation layer: pages, widgets, BLoCs
```

## Design System

UI design follows "The Editorial Sanctuary" philosophy:
- **Newsreader** serif font for article body text
- **Inter** sans-serif font for UI labels
- Light/dark dual mode (dark mode doesn't use pure black)
- No borders, differentiate layers through background color shades

See `UI/desktop/stitch/slate_serif/DESIGN.md` for details.

## License

MIT License
