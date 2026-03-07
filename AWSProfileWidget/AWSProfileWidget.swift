import WidgetKit
import SwiftUI

@main
struct AWSProfileWidgetBundle: WidgetBundle {
    var body: some Widget {
        AWSProfileWidget()
    }
}

/// Main AWS Profile Widget
struct AWSProfileWidget: Widget {
    let kind: String = "AWSProfileWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AWSProfileTimelineProvider()) { entry in
            AWSProfileWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AWS Profile Manager")
        .description("View and switch between AWS profiles quickly from your desktop")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Entry view that switches between different widget sizes
struct AWSProfileWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: AWSProfileEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            if #available(macOS 14.0, *) {
                MediumWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        case .systemLarge:
            if #available(macOS 14.0, *) {
                LargeWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}
