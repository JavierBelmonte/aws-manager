import Foundation

/// Model representing an AWS profile with credentials
struct AWSProfile: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let accessKeyId: String
    let isActive: Bool
    let lastUpdated: Date
    
    /// Returns masked version of access key (first 4 chars + "...")
    var maskedAccessKey: String {
        guard accessKeyId.count >= 4 else {
            return accessKeyId + "..."
        }
        return String(accessKeyId.prefix(4)) + "..."
    }
}
