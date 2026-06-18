# Citrus

The lightweight macOS menu bar app for converting, compressing, and optimizing images and videos. Built by Adedoyin Emmanuel Adeniyi

## Product Direction

Citrus is not a visual wrapper around FFmpeg. It is an outcome-first macOS utility for people who want media to be ready for the next place it needs to go.

The interface should use plain goals:

- Make Smaller
- Best Quality
- Web Optimized
- Email Friendly
- GitHub Upload

Technical encoding details belong inside the processing layer, not in the primary workflow.

## Phase 1

The current foundation includes:

- SwiftPM macOS app target
- SwiftUI `MenuBarExtra` entry point
- Floating panel with drag and drop
- File picker import
- Queue models and view model
- Mock async processing engine
- Job progress, status, cancel, remove, and clear-completed actions
- UserDefaults-backed settings
- Notification infrastructure

Real FFmpeg processing is intentionally deferred until the product flow and architecture are stable.

## Architecture

The app uses pragmatic MVVM:

- `App/` owns app composition and scene setup
- `Core/Queue/` owns queue orchestration
- `Core/Processing/` owns the processing protocol and mock engine
- `Core/Notifications/` owns local notification delivery
- `Core/Storage/` owns persisted settings
- `Features/` owns SwiftUI screens
- `Shared/` owns models, components, and extensions

The design goal is native, quiet, fast, and premium: system typography, restrained surfaces, compact rows, clear progress, and a single warm citrus accent.
