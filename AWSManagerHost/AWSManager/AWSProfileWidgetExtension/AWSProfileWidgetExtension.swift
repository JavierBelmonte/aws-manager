import WidgetKit
import SwiftUI
import Foundation

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), state: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, state: AWSStateStore.load())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration, state: AWSStateStore.load())
        let next = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        return Timeline(entries: [entry], policy: .after(next))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let state: AWSState?
}

struct AWSProfileWidgetExtensionEntryView: View {
    static let widgetVersion = "v4"
    var entry: Provider.Entry

    var body: some View {
        Group {
            if let s = entry.state {
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.profile)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    Text(s.accountId)
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                    Text(s.region)
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    HStack {
                        Text(s.updatedAt, style: .relative)
                        Spacer()
                        Text(Self.widgetVersion)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Abri AWSManager para sincronizar")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .widgetURL(URL(string: "awsmanager-jb-123://open"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct AWSProfileWidgetExtension: Widget {
    let kind: String = "AWSProfileWidgetExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            AWSProfileWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("AWS Profile")
        .description("Muestra el perfil AWS activo y la region.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
