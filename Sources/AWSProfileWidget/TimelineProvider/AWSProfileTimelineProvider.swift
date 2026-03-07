import WidgetKit
import SwiftUI

/// Timeline provider for AWS Profile Widget
struct AWSProfileTimelineProvider: TimelineProvider {
    typealias Entry = AWSProfileEntry
    
    /// Provides placeholder data for widget preview
    func placeholder(in context: Context) -> AWSProfileEntry {
        AWSProfileEntry(
            date: Date(),
            activeProfile: AWSProfile(
                id: "example",
                name: "example",
                accessKeyId: "AKIAIOSFODNN7EXAMPLE",
                isActive: true,
                lastUpdated: Date()
            ),
            availableProfiles: [
                AWSProfile(
                    id: "profile1",
                    name: "profile1",
                    accessKeyId: "AKIAI44QH8DHBEXAMPLE",
                    isActive: false,
                    lastUpdated: Date()
                ),
                AWSProfile(
                    id: "profile2",
                    name: "profile2",
                    accessKeyId: "AKIAIOSFODNN7EXAMPLE2",
                    isActive: false,
                    lastUpdated: Date()
                )
            ],
            errorMessage: nil
        )
    }
    
    /// Provides snapshot for quick preview (uses real data if available)
    func getSnapshot(in context: Context, completion: @escaping (AWSProfileEntry) -> Void) {
        // For preview context, use placeholder data
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        
        // For actual snapshot, try to load real data quickly
        let entry = loadCurrentEntry()
        completion(entry)
    }
    
    /// Provides timeline with refresh policy
    func getTimeline(in context: Context, completion: @escaping (Timeline<AWSProfileEntry>) -> Void) {
        let currentDate = Date()
        
        // Load current entry with real data
        let entry = loadCurrentEntry()
        
        // Schedule next refresh in 5 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        
        // Create timeline with single entry and refresh policy
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
    
    /// Load current entry from credentials manager
    private func loadCurrentEntry() -> AWSProfileEntry {
        let currentDate = Date()
        let manager = AWSCredentialsManager.shared
        
        do {
            // Load all available profiles
            var availableProfiles = try manager.loadProfiles()
            
            // Get the active profile
            let activeProfile = try manager.getActiveProfile()
            
            // Mark the active profile in the available profiles list
            if let active = activeProfile {
                availableProfiles = availableProfiles.map { profile in
                    AWSProfile(
                        id: profile.id,
                        name: profile.name,
                        accessKeyId: profile.accessKeyId,
                        isActive: profile.id == active.id,
                        lastUpdated: currentDate
                    )
                }
            }
            
            return AWSProfileEntry(
                date: currentDate,
                activeProfile: activeProfile,
                availableProfiles: availableProfiles,
                errorMessage: nil
            )
            
        } catch let error as CredentialsError {
            // Handle specific credentials errors
            return AWSProfileEntry(
                date: currentDate,
                activeProfile: nil,
                availableProfiles: [],
                errorMessage: error.localizedDescription
            )
            
        } catch {
            // Handle unexpected errors
            return AWSProfileEntry(
                date: currentDate,
                activeProfile: nil,
                availableProfiles: [],
                errorMessage: "Unexpected error: \(error.localizedDescription)"
            )
        }
    }
}
