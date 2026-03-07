# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AWS Profile Widget for macOS — a native SwiftUI/WidgetKit app that displays and switches AWS profiles from the Notification Center or desktop. Reads/writes `~/.aws/credentials` and `~/.aws/config`.

**Requirements:** macOS 13.0+, Xcode 15.0+, Swift 5.9+

## Build & Test Commands

```bash
swift build              # Build the Swift package (library only)
swift test               # Run tests (requires Xcode toolchain for XCTest)
swift package resolve    # Resolve dependencies
```

The Xcode host app lives in `AWSManagerHost/AWSManager/` — open it in Xcode to build the full app + widget extension (Cmd+B to build, Cmd+U to test).

## Architecture

There are **two parallel implementations** in this repo:

### 1. Swift Package Library (`Sources/AWSProfileWidget/`)
A standalone SPM library with its own credentials parser and widget views. This is the "spec-driven" implementation from `.kiro/specs/`.

- **`Manager/AWSCredentialsManager.swift`** — Singleton that parses `~/.aws/credentials` (INI format), manages profile switching with backup/rollback, and updates region in `~/.aws/config`. Core business logic lives here.
- **`Models/AWSProfile.swift`** — Profile model with credential masking (first 4 chars + "...")
- **`TimelineProvider/`** — WidgetKit timeline provider (5-min refresh)
- **`Views/`** — Small/Medium/Large widget views in SwiftUI
- **`Intents/SwitchProfileIntent.swift`** — AppIntent for profile switching
- **`Extensions/UserDefaults+Cache.swift`** — App Group cache (suite: `group.com.awsmanager.widget`)

### 2. Xcode Host App (`AWSManagerHost/AWSManager/`)
The actual runnable macOS app + widget extension. Uses a different approach:

- **`AWSManager/SharedAWS.swift`** — `AWSCLI` class shells out to `aws` CLI for profile listing, account ID, and region. `AWSStateStore` shares state via App Group (`group.tech.bizland.awsmanager`) using JSON-encoded `AWSState`.
- **`AWSManager/ContentView.swift`** — Main app UI with profile picker
- **`AWSProfileWidgetExtension/AWSProfileWidgetExtension.swift`** — Widget that reads shared state from `AWSStateStore`
- **`AWSProfileWidgetExtension/SharedAWSWidget.swift`** — Widget-side copy of shared types

The host app uses `AppIntentTimelineProvider` and communicates via URL scheme `awsmanager-jb-123://`.

### Key Differences Between the Two
| | SPM Library | Host App |
|---|---|---|
| Credentials access | Direct file parsing | AWS CLI subprocess |
| App Group suite | `group.com.awsmanager.widget` | `group.tech.bizland.awsmanager` |
| Profile switching | Writes to credentials file | Updates shared UserDefaults |

## Testing

Tests are in `Tests/AWSProfileWidgetTests/` and target the SPM library. The spec calls for property-based tests using SwiftCheck (currently commented out in `Package.swift`). Many test tasks from the spec are still pending.

## Security Notes

- Access keys are always masked in UI (show only first 4 characters)
- Credentials file is backed up to `.bak` before any modification
- `AWSCredentialsManager.setActiveProfile()` includes rollback on write failure
