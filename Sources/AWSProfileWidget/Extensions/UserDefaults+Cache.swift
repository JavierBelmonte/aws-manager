import Foundation

/// Extension for UserDefaults to handle App Group caching
extension UserDefaults {
    /// Shared UserDefaults for App Group
    static let appGroup = UserDefaults(suiteName: "group.com.awsmanager.widget")!
    
    // MARK: - Cache Keys
    
    private enum CacheKeys {
        static let profileCache = "profileCache"
        static let lastActiveProfile = "lastActiveProfile"
        static let lastUpdateTime = "lastUpdateTime"
    }
    
    // MARK: - Profile Cache Methods
    
    /// Save cached profiles to UserDefaults
    /// - Parameter profiles: Array of AWSProfile to cache
    func saveCachedProfiles(_ profiles: [AWSProfile]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let encoded = try? encoder.encode(profiles) {
            set(encoded, forKey: CacheKeys.profileCache)
            synchronize()
        }
    }
    
    /// Load cached profiles from UserDefaults
    /// - Returns: Array of cached AWSProfile, or empty array if none found
    func loadCachedProfiles() -> [AWSProfile] {
        guard let data = data(forKey: CacheKeys.profileCache) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let profiles = try? decoder.decode([AWSProfile].self, from: data) {
            return profiles
        }
        
        return []
    }
    
    // MARK: - Last Active Profile Methods
    
    /// Save the last active profile name
    /// - Parameter profileName: Name of the active profile
    func saveLastActiveProfile(_ profileName: String) {
        set(profileName, forKey: CacheKeys.lastActiveProfile)
        synchronize()
    }
    
    /// Load the last active profile name
    /// - Returns: Name of the last active profile, or nil if none found
    func loadLastActiveProfile() -> String? {
        return string(forKey: CacheKeys.lastActiveProfile)
    }
    
    // MARK: - Timestamp Methods
    
    /// Save the last update timestamp
    /// - Parameter timestamp: Date of the last update
    func saveLastUpdateTime(_ timestamp: Date) {
        set(timestamp, forKey: CacheKeys.lastUpdateTime)
        synchronize()
    }
    
    /// Load the last update timestamp
    /// - Returns: Date of the last update, or nil if none found
    func loadLastUpdateTime() -> Date? {
        return object(forKey: CacheKeys.lastUpdateTime) as? Date
    }
    
    // MARK: - Clear Cache
    
    /// Clear all cached data
    func clearCache() {
        removeObject(forKey: CacheKeys.profileCache)
        removeObject(forKey: CacheKeys.lastActiveProfile)
        removeObject(forKey: CacheKeys.lastUpdateTime)
        synchronize()
    }
}
