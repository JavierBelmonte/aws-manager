import Foundation

struct AWSState: Codable {
    var profile: String
    var region: String
    var accountId: String
    var updatedAt: Date
}

final class AWSStateStore {
    static let suite = "group.tech.bizland.awsmanager"
    static let key = "aws_state"

    static func load() -> AWSState? {
        guard let defaults = UserDefaults(suiteName: suite) else { return nil }
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(AWSState.self, from: data)
    }
}
