import Foundation
import os.log

/// Errors that can occur during credentials operations
enum CredentialsError: Error {
    case fileNotFound
    case permissionDenied
    case invalidFormat(String)
    case writeFailed(String)
    case backupFailed(String)
}

extension CredentialsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Credentials file not found at ~/.aws/credentials"
        case .permissionDenied:
            return "Permission denied accessing credentials file"
        case .invalidFormat(let details):
            return "Invalid credentials format: \(details)"
        case .writeFailed(let details):
            return "Failed to write credentials: \(details)"
        case .backupFailed(let details):
            return "Failed to create backup: \(details)"
        }
    }
}

/// Manager for AWS credentials file operations
class AWSCredentialsManager {
    static let shared = AWSCredentialsManager()
    
    private let credentialsPath: URL
    private let configPath: URL
    private let defaultRegion = "us-east-1"
    private let logger = Logger(subsystem: "com.awsmanager.widget", category: "credentials")
    
    init(credentialsPath: URL? = nil, configPath: URL? = nil) {
        if let path = credentialsPath {
            self.credentialsPath = path
        } else {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            self.credentialsPath = homeDirectory
                .appendingPathComponent(".aws")
                .appendingPathComponent("credentials")
        }
        
        if let path = configPath {
            self.configPath = path
        } else {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            self.configPath = homeDirectory
                .appendingPathComponent(".aws")
                .appendingPathComponent("config")
        }
    }
    
    /// Load all profiles from credentials file
    func loadProfiles() throws -> [AWSProfile] {
        logger.info("Loading profiles from credentials file")
        
        // Parse the credentials file
        let sections = try parseCredentialsFile()
        
        // Convert dictionary to array of AWSProfile
        var profiles: [AWSProfile] = []
        let currentDate = Date()
        
        for (sectionName, credentials) in sections {
            // Filter out "default" profile
            if sectionName == "default" {
                continue
            }
            
            // Extract access key id
            guard let accessKeyId = credentials["aws_access_key_id"] else {
                logger.warning("Profile \(sectionName) missing aws_access_key_id, skipping")
                continue
            }
            
            // Create profile (isActive will be determined by getActiveProfile)
            let profile = AWSProfile(
                id: sectionName,
                name: sectionName,
                accessKeyId: accessKeyId,
                isActive: false,
                lastUpdated: currentDate
            )
            
            profiles.append(profile)
        }
        
        // Sort alphabetically by name
        profiles.sort { $0.name < $1.name }
        
        logger.info("Loaded \(profiles.count) profiles")
        return profiles
    }
    
    /// Get the currently active profile
    func getActiveProfile() throws -> AWSProfile? {
        logger.info("Getting active profile")
        
        // Parse the credentials file
        let sections = try parseCredentialsFile()
        
        // Get credentials from "default" section
        guard let defaultCredentials = sections["default"] else {
            logger.info("No default profile found")
            return nil
        }
        
        guard let defaultAccessKeyId = defaultCredentials["aws_access_key_id"] else {
            logger.warning("Default profile missing aws_access_key_id")
            return nil
        }
        
        // Compare with other profiles to find match
        for (sectionName, credentials) in sections {
            // Skip the default section itself
            if sectionName == "default" {
                continue
            }
            
            // Check if access key matches
            if let accessKeyId = credentials["aws_access_key_id"],
               accessKeyId == defaultAccessKeyId {
                // Found matching profile
                let profile = AWSProfile(
                    id: sectionName,
                    name: sectionName,
                    accessKeyId: accessKeyId,
                    isActive: true,
                    lastUpdated: Date()
                )
                
                logger.info("Active profile identified: \(sectionName)")
                return profile
            }
        }
        
        // No matching profile found
        logger.info("No matching profile found for default credentials")
        return nil
    }
    
    /// Set a profile as active by copying its credentials to default
    func setActiveProfile(profileName: String) throws {
        logger.info("Setting active profile to: \(profileName)")
        
        // Parse the credentials file to get all profiles
        let sections = try parseCredentialsFile()
        
        // Validate that the profile exists
        guard let profileCredentials = sections[profileName] else {
            logger.error("Profile '\(profileName)' not found in credentials file")
            throw CredentialsError.invalidFormat("Profile '\(profileName)' does not exist")
        }
        
        // Create backup before modifying
        do {
            try createBackup()
        } catch {
            logger.error("Failed to create backup before profile switch: \(error.localizedDescription)")
            throw error
        }
        
        // Create updated sections with new default
        var updatedSections = sections
        updatedSections["default"] = profileCredentials
        
        // Write the updated credentials file
        do {
            try writeCredentialsFile(sections: updatedSections)
            logger.info("Successfully updated credentials file with profile: \(profileName)")
        } catch {
            logger.error("Failed to write credentials file: \(error.localizedDescription)")
            
            // Attempt rollback from backup
            let backupPath = credentialsPath.appendingPathExtension("bak")
            if FileManager.default.fileExists(atPath: backupPath.path) {
                do {
                    try FileManager.default.removeItem(at: credentialsPath)
                    try FileManager.default.copyItem(at: backupPath, to: credentialsPath)
                    logger.info("Successfully rolled back to backup after write failure")
                } catch {
                    logger.error("Failed to rollback from backup: \(error.localizedDescription)")
                }
            }
            
            throw CredentialsError.writeFailed(error.localizedDescription)
        }
        
        // Update region in config file
        do {
            try updateRegionForProfile(profileName: profileName)
            logger.info("Successfully updated region for profile: \(profileName)")
        } catch {
            logger.warning("Failed to update region in config file: \(error.localizedDescription)")
            // Don't fail the entire operation if region update fails
            // The credentials switch was successful
        }
    }
    
    /// Create backup of credentials file
    func createBackup() throws {
        logger.info("Creating backup of credentials file")
        
        // Check if credentials file exists
        guard FileManager.default.fileExists(atPath: credentialsPath.path) else {
            logger.error("Cannot create backup: credentials file not found")
            throw CredentialsError.fileNotFound
        }
        
        // Create backup path (.bak extension)
        let backupPath = credentialsPath.appendingPathExtension("bak")
        
        do {
            // Remove existing backup if it exists
            if FileManager.default.fileExists(atPath: backupPath.path) {
                try FileManager.default.removeItem(at: backupPath)
                logger.debug("Removed existing backup file")
            }
            
            // Copy credentials file to backup
            try FileManager.default.copyItem(at: credentialsPath, to: backupPath)
            logger.info("Successfully created backup at: \(backupPath.path)")
        } catch {
            logger.error("Failed to create backup: \(error.localizedDescription)")
            throw CredentialsError.backupFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Region Management
    
    /// Update the region in config file for the specified profile
    private func updateRegionForProfile(profileName: String) throws {
        logger.info("Updating region for profile: \(profileName)")
        
        // Parse config file (or create empty if doesn't exist)
        var configSections: [String: [String: String]]
        
        if FileManager.default.fileExists(atPath: configPath.path) {
            configSections = try parseConfigFile()
        } else {
            logger.info("Config file doesn't exist, will create it")
            configSections = [:]
        }
        
        // Get region for the profile (use default if not found)
        let profileSectionName = "profile \(profileName)"
        let region = configSections[profileSectionName]?["region"] ?? defaultRegion
        
        logger.info("Using region '\(region)' for profile '\(profileName)'")
        
        // Update default section with the region
        if configSections["default"] == nil {
            configSections["default"] = [:]
        }
        configSections["default"]?["region"] = region
        
        // Write updated config file
        try writeConfigFile(sections: configSections)
        logger.info("Successfully updated config file with region: \(region)")
    }
    
    /// Parse config file in INI format
    private func parseConfigFile() throws -> [String: [String: String]] {
        logger.debug("Parsing config file")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            logger.info("Config file not found at: \(self.configPath.path)")
            return [:]
        }
        
        // Check if file is readable
        guard FileManager.default.isReadableFile(atPath: configPath.path) else {
            logger.error("Permission denied reading config file")
            throw CredentialsError.permissionDenied
        }
        
        // Read file contents
        let contents: String
        do {
            contents = try String(contentsOf: configPath, encoding: .utf8)
        } catch {
            logger.error("Failed to read config file: \(error.localizedDescription)")
            throw CredentialsError.invalidFormat("Unable to read config file: \(error.localizedDescription)")
        }
        
        var result: [String: [String: String]] = [:]
        var currentSection: String?
        
        // Parse line by line (same logic as credentials file)
        for (lineNumber, line) in contents.components(separatedBy: .newlines).enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") || trimmedLine.hasPrefix(";") {
                continue
            }
            
            // Check for section header [section_name] or [profile section_name]
            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                let sectionName = String(trimmedLine.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                if sectionName.isEmpty {
                    logger.warning("Empty section name at line \(lineNumber + 1)")
                    continue
                }
                currentSection = sectionName
                result[sectionName] = [:]
                continue
            }
            
            // Parse key=value pairs
            if let equalIndex = trimmedLine.firstIndex(of: "=") {
                guard let section = currentSection else {
                    logger.warning("Key-value pair found outside of section at line \(lineNumber + 1)")
                    continue
                }
                
                let key = trimmedLine[..<equalIndex].trimmingCharacters(in: .whitespaces)
                let value = trimmedLine[trimmedLine.index(after: equalIndex)...].trimmingCharacters(in: .whitespaces)
                
                if !key.isEmpty {
                    result[section]?[key] = value
                }
            }
        }
        
        logger.debug("Successfully parsed \(result.count) sections from config file")
        return result
    }
    
    /// Write config file in INI format
    private func writeConfigFile(sections: [String: [String: String]]) throws {
        logger.debug("Writing config file")
        
        var output = ""
        
        // Sort sections (default first, then alphabetically)
        let sortedSectionNames = sections.keys.sorted { lhs, rhs in
            if lhs == "default" { return true }
            if rhs == "default" { return false }
            return lhs < rhs
        }
        
        for sectionName in sortedSectionNames {
            guard let settings = sections[sectionName] else { continue }
            
            // Write section header
            output += "[\(sectionName)]\n"
            
            // Write key-value pairs (sorted for consistency)
            let sortedKeys = settings.keys.sorted()
            for key in sortedKeys {
                if let value = settings[key] {
                    output += "\(key) = \(value)\n"
                }
            }
            
            // Add blank line between sections
            output += "\n"
        }
        
        // Ensure .aws directory exists
        let awsDirectory = configPath.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: awsDirectory.path) {
            try FileManager.default.createDirectory(at: awsDirectory, withIntermediateDirectories: true)
            logger.debug("Created .aws directory")
        }
        
        // Write to file
        do {
            try output.write(to: configPath, atomically: true, encoding: .utf8)
            logger.debug("Successfully wrote config file")
        } catch {
            logger.error("Failed to write config file: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    /// Write credentials to file in INI format
    private func writeCredentialsFile(sections: [String: [String: String]]) throws {
        logger.debug("Writing credentials file")
        
        var output = ""
        
        // Sort sections to ensure consistent output (default first, then alphabetically)
        let sortedSectionNames = sections.keys.sorted { lhs, rhs in
            if lhs == "default" { return true }
            if rhs == "default" { return false }
            return lhs < rhs
        }
        
        for sectionName in sortedSectionNames {
            guard let credentials = sections[sectionName] else { continue }
            
            // Write section header
            output += "[\(sectionName)]\n"
            
            // Write key-value pairs (sorted for consistency)
            let sortedKeys = credentials.keys.sorted()
            for key in sortedKeys {
                if let value = credentials[key] {
                    output += "\(key) = \(value)\n"
                }
            }
            
            // Add blank line between sections
            output += "\n"
        }
        
        // Write to file
        do {
            try output.write(to: credentialsPath, atomically: true, encoding: .utf8)
            logger.debug("Successfully wrote credentials file")
        } catch {
            logger.error("Failed to write credentials file: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Parse credentials file in INI format
    private func parseCredentialsFile() throws -> [String: [String: String]] {
        logger.debug("Parsing credentials file")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: credentialsPath.path) else {
            logger.error("Credentials file not found at: \(self.credentialsPath.path)")
            throw CredentialsError.fileNotFound
        }
        
        // Check if file is readable
        guard FileManager.default.isReadableFile(atPath: credentialsPath.path) else {
            logger.error("Permission denied reading credentials file")
            throw CredentialsError.permissionDenied
        }
        
        // Read file contents
        let contents: String
        do {
            contents = try String(contentsOf: credentialsPath, encoding: .utf8)
        } catch {
            logger.error("Failed to read credentials file: \(error.localizedDescription)")
            throw CredentialsError.invalidFormat("Unable to read file: \(error.localizedDescription)")
        }
        
        var result: [String: [String: String]] = [:]
        var currentSection: String?
        
        // Parse line by line
        for (lineNumber, line) in contents.components(separatedBy: .newlines).enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmedLine.isEmpty {
                continue
            }
            
            // Skip comments (lines starting with # or ;)
            if trimmedLine.hasPrefix("#") || trimmedLine.hasPrefix(";") {
                continue
            }
            
            // Check for section header [section_name]
            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                let sectionName = String(trimmedLine.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                if sectionName.isEmpty {
                    logger.warning("Empty section name at line \(lineNumber + 1)")
                    throw CredentialsError.invalidFormat("Empty section name at line \(lineNumber + 1)")
                }
                currentSection = sectionName
                result[sectionName] = [:]
                continue
            }
            
            // Parse key=value pairs
            if let equalIndex = trimmedLine.firstIndex(of: "=") {
                guard let section = currentSection else {
                    logger.warning("Key-value pair found outside of section at line \(lineNumber + 1)")
                    throw CredentialsError.invalidFormat("Key-value pair outside of section at line \(lineNumber + 1)")
                }
                
                let key = trimmedLine[..<equalIndex].trimmingCharacters(in: .whitespaces)
                let value = trimmedLine[trimmedLine.index(after: equalIndex)...].trimmingCharacters(in: .whitespaces)
                
                if key.isEmpty {
                    logger.warning("Empty key at line \(lineNumber + 1)")
                    throw CredentialsError.invalidFormat("Empty key at line \(lineNumber + 1)")
                }
                
                result[section]?[key] = value
            } else {
                // Line doesn't match any expected format
                logger.warning("Invalid line format at line \(lineNumber + 1): \(trimmedLine)")
                throw CredentialsError.invalidFormat("Invalid line format at line \(lineNumber + 1)")
            }
        }
        
        logger.debug("Successfully parsed \(result.count) sections from credentials file")
        return result
    }
}
