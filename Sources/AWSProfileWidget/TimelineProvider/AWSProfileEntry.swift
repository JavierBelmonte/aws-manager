import WidgetKit
import Foundation

/// Timeline entry for the AWS Profile Widget
struct AWSProfileEntry: TimelineEntry {
    let date: Date
    let activeProfile: AWSProfile?
    let availableProfiles: [AWSProfile]
    let errorMessage: String?
}
