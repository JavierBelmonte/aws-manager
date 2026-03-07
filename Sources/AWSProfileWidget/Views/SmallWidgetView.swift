import SwiftUI
import WidgetKit

/// Small widget view showing only the active profile
struct SmallWidgetView: View {
    let entry: AWSProfileEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("AWS Profile")
                .font(.caption2)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Spacer()
            
            // Active profile or error state
            if let errorMessage = entry.errorMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            } else if let activeProfile = entry.activeProfile {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                    
                    Text(activeProfile.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Text("No active profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Timestamp
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(formattedTimestamp)
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Formats the timestamp for display
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
}

// MARK: - Previews

struct SmallWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with active profile
            SmallWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: AWSProfile(
                    id: "production",
                    name: "production",
                    accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                    isActive: true,
                    lastUpdated: Date()
                ),
                availableProfiles: [],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("With Active Profile")
            
            // Preview without active profile
            SmallWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: nil,
                availableProfiles: [],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("No Active Profile")
            
            // Preview with error
            SmallWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: nil,
                availableProfiles: [],
                errorMessage: "Credentials file not found"
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("With Error")
            
            // Dark mode preview
            SmallWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: AWSProfile(
                    id: "staging",
                    name: "staging",
                    accessKeyId: "AKIAI44QH8DHBEXAMPLE",
                    isActive: true,
                    lastUpdated: Date()
                ),
                availableProfiles: [],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
