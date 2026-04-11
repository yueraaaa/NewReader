# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

REAL READER is a cross-platform RSS reader built with Flutter. It features AI-powered translation/summarization (via Minimax), cloud sync (via Supabase), and an editorial-style UI inspired by high-end print journals ("The Editorial Sanctuary" design system).

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run on target platform
flutter run -d macos
flutter run -d windows
flutter run -d iphone

# Analyze / lint
flutter analyze

# Run tests
flutter test

# Run a specific test file
flutter test test/data/models/feed_model_test.dart

# Build
flutter build macos
flutter build ios
flutter build windows
```

## Environment Variables (required at runtime)

Set these via `flutter run` arguments or shell environment:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous (public) key |
| `MINIMAX_API_KEY` | Minimax API key for AI features |
| `MINIMAX_GROUP_ID` | Minimax group ID |

Example: `flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...`

## Architecture

**Clean Architecture** with 3 layers:
- `lib/presentation/` — UI (pages, widgets, BLoCs)
- `lib/domain/` — Business logic (entities, repository interfaces)
- `lib/data/` — Data access (models, datasources, repository implementations)

**State Management:** flutter_bloc (BLoC pattern)

**Routing:** go_router with ShellRoute that auto-selects `DesktopShell` or `MobileShell` based on platform detection via `universal_platform`.

**Local Storage:** sqflite (SQLite) — tables: `feeds`, `articles`, `categories`, `settings`, `sync_metadata`

**Cloud Sync:** Supabase — same schema as SQLite, synced via `SyncService` with last-write-wins conflict resolution

**Key BLoCs:**
- `AuthBloc` — Apple/GitHub/Email login, auth state
- `FeedBloc` — RSS feeds and categories CRUD
- `ArticleBloc` — Articles with read/favorite/progress tracking
- `SettingsBloc` — Theme mode, font size, reading speed
- `AiBloc` — Minimax translation, summarization, TTS

**Design System:** Defined in `UI/desktop/stitch/slate_serif/DESIGN.md` and `UI/mobile/stitch/slate_serif/DESIGN.md`. Uses Newsreader (serif) for editorial content, Inter for UI labels. Color palette via `AppColors` class — NO pure black in dark mode (uses `surface-dim` approach).

## Important Patterns

- **Models** use `Equatable` and `fromMap`/`toMap` for SQLite serialization
- **Local datasources** handle SQLite CRUD; remote datasources handle HTTP/API calls
- **Repository implementations** sit between BLoCs and datasources
- **OPML import/export** handled by `OpmlService` in `lib/data/services/`
- **AI features** (translate/summarize) are independent — each calls Minimax separately, results stored in BLoC state, do not overwrite original article content
