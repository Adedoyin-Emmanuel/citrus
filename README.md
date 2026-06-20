# Citrus

The lightweight macOS menu bar app for converting, compressing, and optimizing images and videos. Built by Adedoyin Emmanuel Adeniyi

## Product Direction

Citrus is not a visual wrapper around FFmpeg. It is a dead-simple macOS utility for people who just want their images and videos to be smaller.

The interface asks for one thing — how small — in plain language:

- Smaller
- Balanced
- Best Quality

Drop files, pick a level, hit Compress. Technical encoding details (format, resolution, bitrate) are handled automatically inside the processing layer, never surfaced in the primary workflow.

## Phase 1

The current foundation includes:

- SwiftPM macOS app target
- Status-bar popover entry point
- Floating panel with drag and drop and multi-file import
- File picker import
- Queue models and view model
- Real native processing engine (no third-party binaries):
  - Images via ImageIO — resize + lossy re-encode to JPEG / PNG / HEIC
  - Video via AVFoundation — transcode/compress to MP4 / MOV at chosen resolution
- Kind-aware controls (image vs video properties resolved automatically)
- Output respects the chosen location (Downloads by default), with non-clobbering names
- Job progress, status, cancel, remove, and clear-finished actions
- Per-job size savings readout
- UserDefaults-backed settings
- Local "job finished" notifications

Citrus uses Apple's native media frameworks rather than wrapping FFmpeg, keeping the app small, fast, and dependency-free.

## Running

For development:

```bash
cd app
swift run
```

To produce a real, notification-capable `Citrus.app` bundle:

```bash
cd app
./Scripts/build-app.sh
open .build/Citrus.app
```

Notifications require the bundled `.app` (they are suppressed when launched via `swift run` because there is no bundle identity).

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
