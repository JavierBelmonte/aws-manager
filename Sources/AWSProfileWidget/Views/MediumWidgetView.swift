import SwiftUI
import WidgetKit

/// Medium widget view showing active profile and a compact list of available profiles
@available(macOS 14.0, *)
struct MediumWidgetView: View {
    let entry: AWSProfileEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side: Active profile section
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
                            .font(.title3)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                } else if let activeProfile = entry.activeProfile {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                        
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(activeProfile.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.secondary)
                            .font(.title3)
                        
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
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider
            Divider()
            
            // Right side: Available profiles list
            VStack(alignment: .leading, spacing: 4) {
                Text("Available Profiles")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.bottom, 4)
                
                if entry.availableProfiles.isEmpty {
                    Text("No profiles configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxHeight: .infinity)
                } else {
                    VStack(spacing: 6) {
                        ForEach(compactProfiles) { profile in
                            ProfileRowView(profile: profile)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Returns up to 4 profiles for compact display
    private var compactProfiles: [AWSProfile] {
        Array(entry.availableProfiles.prefix(4))
    }
    
    /// Formats the timestamp for display
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
}

// MARK: - Profile Row View

/// Individual profile row with switch button
@available(macOS 14.0, *)
struct ProfileRowView: View {
    let profile: AWSProfile
    
    var body: some View {
        let intent = SwitchProfileIntent()
        intent.profileName = profile.name
        
        return Button(intent: intent) {
            HStack(spacing: 6) {
                // Active indicator
                Image(systemName: profile.isActive ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundColor(profile.isActive ? .accentColor : .secondary)
                
                // Profile name
                Text(profile.name)
                    .font(.caption)
                    .fontWeight(profile.isActive ? .semibold : .regular)
                    .foregroundColor(profile.isActive ? .primary : .secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Switch icon (only show for non-active profiles)
                if !profile.isActive {
                    Image(systemName: "arrow.right.circle")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

@available(macOS 14.0, *)
struct MediumWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with active profile and multiple available profiles
            MediumWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: AWSProfile(
                    id: "production",
                    name: "production",
                    accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                    isActive: true,
                    lastUpdated: Date()
                ),
                availableProfiles: [
                    AWSProfile(
                        id: "production",
                        name: "production",
                        accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                        isActive: true,
                        lastUpdated: Date()
                    ),
                    AWSProfile(
                        id: "staging",
                        name: "staging",
                        accessKeyId: "AKIAI44QH8DHBEXAMPLE",
                        isActive: false,
                        lastUpdated: Date()
                    ),
                    AWSProfile(
                        id: "development",
                        name: "development",
                        accessKeyId: "AKIAIOSFODNN7EXAMPLE2",
                        isActive: false,
                        lastUpdated: Date()
                    ),
                    AWSProfile(
                        id: "testing",
                        name: "testing",
                        accessKeyId: "AKIAI44QH8DHBEXAMPLE2",
                        isActive: false,
                        lastUpdated: Date()
                    )
                ],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("With Multiple Profiles")
            
            // Preview with no active profile
            MediumWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: nil,
                availableProfiles: [
                    AWSProfile(
                        id: "staging",
                        name: "staging",
                        accessKeyId: "AKIAI44QH8DHBEXAMPLE",
                        isActive: false,
                        lastUpdated: Date()
                    ),
                    AWSProfile(
                        id: "development",
                        name: "development",
                        accessKeyId: "AKIAIOSFODNN7EXAMPLE2",
                        isActive: false,
                        lastUpdated: Date()
                    )
                ],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("No Active Profile")
            
            // Preview with error
            MediumWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: nil,
                availableProfiles: [],
                errorMessage: "Credentials file not found"
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("With Error")
            
            // Preview with no profiles configured
            MediumWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: nil,
                availableProfiles: [],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("No Profiles Configured")
            
            // Dark mode preview
            MediumWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: AWSProfile(
                    id: "production",
                    name: "production",
                    accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                    isActive: true,
                    lastUpdated: Date()
                ),
                availableProfiles: [
                    AWSProfile(
                        id: "production",
                        name: "production",
                        accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                        isActive: true,
                        lastUpdated: Date()
                    ),
                    AWSProfile(
                        id: "staging",
                        name: "staging",
                        accessKeyId: "AKIAI44QH8DHBEXAMPLE",
                        isActive: false,
                        lastUpdated: Date()
                    ),
                    AWSProfile(
                        id: "development",
                        name: "development",
                        accessKeyId: "AKIAIOSFODNN7EXAMPLE2",
                        isActive: false,
                        lastUpdated: Date()
                    )
                ],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
