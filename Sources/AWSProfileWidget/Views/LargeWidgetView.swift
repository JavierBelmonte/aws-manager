import SwiftUI
import WidgetKit

/// Large widget view showing active profile with details and complete list of profiles
@available(macOS 14.0, *)
struct LargeWidgetView: View {
    let entry: AWSProfileEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header section
            HStack {
                Text("AWS Profile Manager")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                // Timestamp
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(formattedTimestamp)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            
            // Active profile section with details
            if let errorMessage = entry.errorMessage {
                // Error state
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Error")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 8)
            } else if let activeProfile = entry.activeProfile {
                // Active profile with details
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(activeProfile.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "key.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(activeProfile.maskedAccessKey)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontDesign(.monospaced)
                        }
                    }
                }
                .padding(.vertical, 8)
            } else {
                // No active profile
                HStack(spacing: 8) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Active Profile")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Available profiles section
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Profiles (\(entry.availableProfiles.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                if entry.availableProfiles.isEmpty {
                    Text("No profiles configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(displayedProfiles) { profile in
                                LargeProfileRowView(profile: profile)
                            }
                            
                            // Show indicator if there are more profiles
                            if entry.availableProfiles.count > 10 {
                                Text("+ \(entry.availableProfiles.count - 10) more profiles")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    /// Returns up to 10 profiles for display
    private var displayedProfiles: [AWSProfile] {
        Array(entry.availableProfiles.prefix(10))
    }
    
    /// Formats the timestamp for display
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
}

// MARK: - Large Profile Row View

/// Individual profile row for large widget with masked access key
@available(macOS 14.0, *)
struct LargeProfileRowView: View {
    let profile: AWSProfile
    
    var body: some View {
        let intent = SwitchProfileIntent()
        intent.profileName = profile.name
        
        return Button(intent: intent) {
            HStack(spacing: 8) {
                // Active indicator
                Image(systemName: profile.isActive ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundColor(profile.isActive ? .accentColor : .secondary)
                    .frame(width: 16)
                
                // Profile details
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.caption)
                        .fontWeight(profile.isActive ? .semibold : .regular)
                        .foregroundColor(profile.isActive ? .primary : .secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 8))
                        Text(profile.maskedAccessKey)
                            .font(.system(size: 9))
                            .fontDesign(.monospaced)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Switch icon (only show for non-active profiles)
                if !profile.isActive {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(profile.isActive ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

@available(macOS 14.0, *)
struct LargeWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with active profile and multiple available profiles
            LargeWidgetView(entry: AWSProfileEntry(
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
                    ),
                    AWSProfile(
                        id: "qa",
                        name: "qa",
                        accessKeyId: "AKIAIOSFODNN7EXAMPLE3",
                        isActive: false,
                        lastUpdated: Date()
                    ),
                    AWSProfile(
                        id: "demo",
                        name: "demo",
                        accessKeyId: "AKIAI44QH8DHBEXAMPLE3",
                        isActive: false,
                        lastUpdated: Date()
                    )
                ],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("With Multiple Profiles")
            
            // Preview with many profiles (>10)
            LargeWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: AWSProfile(
                    id: "production",
                    name: "production",
                    accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                    isActive: true,
                    lastUpdated: Date()
                ),
                availableProfiles: (1...15).map { i in
                    AWSProfile(
                        id: "profile\(i)",
                        name: "profile\(i)",
                        accessKeyId: "AKIAIOSFODNN7EXAMPL\(i)",
                        isActive: i == 1,
                        lastUpdated: Date()
                    )
                },
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("With Many Profiles")
            
            // Preview with no active profile
            LargeWidgetView(entry: AWSProfileEntry(
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
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("No Active Profile")
            
            // Preview with error
            LargeWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: nil,
                availableProfiles: [],
                errorMessage: "Credentials file not found"
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("With Error")
            
            // Preview with no profiles configured
            LargeWidgetView(entry: AWSProfileEntry(
                date: Date(),
                activeProfile: nil,
                availableProfiles: [],
                errorMessage: nil
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("No Profiles Configured")
            
            // Dark mode preview
            LargeWidgetView(entry: AWSProfileEntry(
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
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
