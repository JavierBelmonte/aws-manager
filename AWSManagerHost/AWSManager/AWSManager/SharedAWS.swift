import Foundation
import WidgetKit

struct AWSState: Codable, Equatable {
    var profile: String
    var region: String
    var accountId: String
    var updatedAt: Date
}

final class AWSStateStore {
    static let suite = "group.tech.bizland.awsmanager"
    static let key = "aws_state"

    static func save(_ state: AWSState) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(state) {
            defaults.set(data, forKey: key)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    static func load() -> AWSState? {
        guard let defaults = UserDefaults(suiteName: suite) else { return nil }
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(AWSState.self, from: data)
    }
}

final class AWSCredentialsManager {
    private let credentialsPath: URL
    private let configPath: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        credentialsPath = home.appendingPathComponent(".aws/credentials")
        configPath = home.appendingPathComponent(".aws/config")
    }

    struct ProfileInfo {
        let name: String
        let region: String
        let accountId: String
    }

    /// List all profile names (excluding "default")
    func listProfiles() -> [String] {
        let sections = parseINI(at: credentialsPath)
        return sections.keys.filter { $0 != "default" }.sorted()
    }

    /// Read the currently active profile (the one matching [default] credentials)
    func readActiveProfile() -> ProfileInfo? {
        let sections = parseINI(at: credentialsPath)
        guard let defaultCreds = sections["default"],
              let defaultKey = defaultCreds["aws_access_key_id"] else {
            return nil
        }

        var matchedName: String?
        for (name, creds) in sections where name != "default" {
            if creds["aws_access_key_id"] == defaultKey {
                matchedName = name
                break
            }
        }

        let profileName = matchedName ?? "default"
        let region = readRegion(for: profileName)
        let accountId = fetchAccountId(profile: profileName)

        return ProfileInfo(name: profileName, region: region, accountId: accountId)
    }

    /// Switch active profile by copying its credentials to [default]
    func switchProfile(to profileName: String) -> Bool {
        var sections = parseINI(at: credentialsPath)
        guard let profileCreds = sections[profileName] else { return false }

        // Backup
        let backupPath = credentialsPath.appendingPathExtension("bak")
        try? FileManager.default.removeItem(at: backupPath)
        try? FileManager.default.copyItem(at: credentialsPath, to: backupPath)

        // Copy profile credentials to default
        sections["default"] = profileCreds

        // Write back
        return writeINI(sections, to: credentialsPath)
    }

    /// Add a new profile to credentials file
    func addProfile(name: String, accessKeyId: String, secretAccessKey: String, sessionToken: String = "") -> Bool {
        var sections = parseINI(at: credentialsPath)

        // Backup
        let backupPath = credentialsPath.appendingPathExtension("bak")
        try? FileManager.default.removeItem(at: backupPath)
        try? FileManager.default.copyItem(at: credentialsPath, to: backupPath)

        var creds: [String: String] = [
            "aws_access_key_id": accessKeyId,
            "aws_secret_access_key": secretAccessKey
        ]
        if !sessionToken.isEmpty {
            creds["aws_session_token"] = sessionToken
        }
        sections[name] = creds

        return writeINI(sections, to: credentialsPath)
    }

    /// Delete a profile from credentials file
    func deleteProfile(name: String) -> Bool {
        guard name != "default" else { return false }
        var sections = parseINI(at: credentialsPath)

        // Backup
        let backupPath = credentialsPath.appendingPathExtension("bak")
        try? FileManager.default.removeItem(at: backupPath)
        try? FileManager.default.copyItem(at: credentialsPath, to: backupPath)

        sections.removeValue(forKey: name)
        return writeINI(sections, to: credentialsPath)
    }

    // MARK: - Private

    private func readRegion(for profile: String) -> String {
        let configSections = parseINI(at: configPath)
        if let region = configSections["profile \(profile)"]?["region"] {
            return region
        }
        if let region = configSections["default"]?["region"] {
            return region
        }
        return "us-east-1"
    }

    private func fetchAccountId(profile: String) -> String {
        // Try to get account ID via AWS CLI (best-effort)
        let paths = ["/opt/homebrew/bin/aws", "/usr/local/bin/aws", "/usr/bin/aws"]
        guard let awsPath = paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            return "—"
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: awsPath)
        p.arguments = ["sts", "get-caller-identity", "--profile", profile, "--query", "Account", "--output", "text"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()

        do {
            try p.run()
            p.waitUntilExit()
            guard p.terminationStatus == 0 else { return "—" }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            return output.isEmpty ? "—" : output
        } catch {
            return "—"
        }
    }

    private func parseINI(at url: URL) -> [String: [String: String]] {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return [:] }

        var result: [String: [String: String]] = [:]
        var currentSection: String?

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(";") { continue }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let name = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    currentSection = name
                    result[name] = result[name] ?? [:]
                }
                continue
            }

            if let eq = trimmed.firstIndex(of: "="), let section = currentSection {
                let key = trimmed[..<eq].trimmingCharacters(in: .whitespaces)
                let value = trimmed[trimmed.index(after: eq)...].trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    result[section]?[key] = value
                }
            }
        }
        return result
    }

    private func writeINI(_ sections: [String: [String: String]], to url: URL) -> Bool {
        var output = ""
        // default first, then alphabetically
        let sorted = sections.keys.sorted { lhs, rhs in
            if lhs == "default" { return true }
            if rhs == "default" { return false }
            return lhs < rhs
        }

        for section in sorted {
            guard let pairs = sections[section] else { continue }
            output += "[\(section)]\n"
            for key in pairs.keys.sorted() {
                if let value = pairs[key] {
                    output += "\(key) = \(value)\n"
                }
            }
            output += "\n"
        }

        do {
            try output.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
}
