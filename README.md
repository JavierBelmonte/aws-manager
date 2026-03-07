# AWS Profile Widget for macOS

A native macOS widget built with SwiftUI and WidgetKit that allows you to view and switch between AWS profiles directly from the Notification Center or desktop.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Project Structure

```
AWSProfileWidget/
├── Sources/
│   └── AWSProfileWidget/
│       ├── Models/
│       │   └── AWSProfile.swift
│       ├── Manager/
│       │   └── AWSCredentialsManager.swift
│       └── TimelineProvider/
│           ├── AWSProfileEntry.swift
│           └── AWSProfileTimelineProvider.swift
├── Tests/
│   └── AWSProfileWidgetTests/
│       └── AWSProfileWidgetTests.swift
├── AWSProfileWidget/
│   ├── AWSProfileWidget.swift
│   └── Info.plist
├── Package.swift
└── AWSProfileWidget.entitlements
```

## Setup

### 1. App Group Configuration

The widget uses an App Group to share data: `group.com.awsmanager.widget`

This is configured in:
- `AWSProfileWidget.entitlements`
- Xcode project capabilities

### 2. File Access Permissions

The widget requires access to `~/.aws/credentials`. Permissions are configured in:
- `Info.plist` with `NSHomeDirectoryUsageDescription`
- Entitlements file with sandbox permissions

### 3. Dependencies

The project uses Swift Package Manager with the following dependencies:
- **SwiftCheck**: Property-based testing framework (v0.12.0+)

To resolve dependencies:
```bash
swift package resolve
```

## Building

### Using Swift Package Manager

```bash
# Build the project
swift build

# Run tests
swift test
```

### Using Xcode

1. Open `AWSProfileWidget.xcodeproj` in Xcode
2. Select the AWSProfileWidget scheme
3. Build with ⌘B
4. Run tests with ⌘U

## Testing

The project includes both unit tests and property-based tests:

- **Unit Tests**: Verify specific examples and edge cases
- **Property Tests**: Verify universal properties across generated inputs (minimum 100 iterations)

All property tests are tagged with comments referencing design document properties.

## Installation

1. Build the widget extension in Xcode
2. Run the containing app
3. Add the widget to your Notification Center or desktop:
   - Right-click on desktop or open Notification Center
   - Click "Edit Widgets"
   - Search for "AWS Profile Manager"
   - Add the widget in your preferred size (Small, Medium, or Large)

## Widget Sizes

- **Small**: Shows only the active profile name
- **Medium**: Shows active profile + compact list of available profiles
- **Large**: Shows active profile + full list with masked access keys

## Security

- Access keys are always masked (showing only first 4 characters)
- Credentials file is backed up before any modifications
- All operations are logged using macOS unified logging system

## License

[Add your license here]
