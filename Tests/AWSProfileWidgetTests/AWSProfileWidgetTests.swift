import XCTest
@testable import AWSProfileWidget

final class AWSProfileWidgetTests: XCTestCase {
    
    var tempCredentialsURL: URL!
    var manager: AWSCredentialsManager!
    
    override func setUp() {
        super.setUp()
        
        // Create temporary credentials file for testing
        let tempDir = FileManager.default.temporaryDirectory
        tempCredentialsURL = tempDir.appendingPathComponent("test_credentials_\(UUID().uuidString)")
        
        // Create test credentials content
        let testContent = """
        [default]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        
        [profile1]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        
        [profile2]
        aws_access_key_id = AKIAI44QH8DHBEXAMPLE
        aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
        
        [zebra-profile]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE2
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY2
        
        [alpha-profile]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE3
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY3
        """
        
        try! testContent.write(to: tempCredentialsURL, atomically: true, encoding: .utf8)
        
        // Initialize manager with test credentials path
        manager = AWSCredentialsManager(credentialsPath: tempCredentialsURL)
    }
    
    override func tearDown() {
        // Clean up temporary file
        try? FileManager.default.removeItem(at: tempCredentialsURL)
        super.tearDown()
    }
    
    // MARK: - Core Functionality Tests
    
    func testLoadProfilesReturnsAllNonDefaultProfiles() throws {
        let profiles = try manager.loadProfiles()
        
        // Should have 4 profiles (excluding default)
        XCTAssertEqual(profiles.count, 4)
        
        // Verify no "default" profile in results
        XCTAssertFalse(profiles.contains(where: { $0.name == "default" }))
        
        // Verify all expected profiles are present
        let profileNames = profiles.map { $0.name }
        XCTAssertTrue(profileNames.contains("profile1"))
        XCTAssertTrue(profileNames.contains("profile2"))
        XCTAssertTrue(profileNames.contains("zebra-profile"))
        XCTAssertTrue(profileNames.contains("alpha-profile"))
    }
    
    func testLoadProfilesAreAlphabeticallySorted() throws {
        let profiles = try manager.loadProfiles()
        
        // Verify alphabetical ordering
        let names = profiles.map { $0.name }
        XCTAssertEqual(names, names.sorted())
        
        // Specifically check that alpha comes before zebra
        XCTAssertEqual(profiles[0].name, "alpha-profile")
        XCTAssertEqual(profiles[3].name, "zebra-profile")
    }
    
    func testGetActiveProfileIdentifiesCorrectProfile() throws {
        let activeProfile = try manager.getActiveProfile()
        
        // Should identify profile1 as active (matches default credentials)
        XCTAssertNotNil(activeProfile)
        XCTAssertEqual(activeProfile?.name, "profile1")
        XCTAssertTrue(activeProfile?.isActive ?? false)
        XCTAssertEqual(activeProfile?.accessKeyId, "AKIAIOSFODNN7EXAMPLE")
    }
    
    func testGetActiveProfileReturnsNilWhenNoMatch() throws {
        // Create credentials file with no matching profile
        let noMatchContent = """
        [default]
        aws_access_key_id = AKIAUNMATCHEDKEY
        aws_secret_access_key = unmatchedsecret
        
        [profile1]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        """
        
        try noMatchContent.write(to: tempCredentialsURL, atomically: true, encoding: .utf8)
        
        let activeProfile = try manager.getActiveProfile()
        XCTAssertNil(activeProfile)
    }
    
    func testGetActiveProfileReturnsNilWhenNoDefault() throws {
        // Create credentials file without default section
        let noDefaultContent = """
        [profile1]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        """
        
        try noDefaultContent.write(to: tempCredentialsURL, atomically: true, encoding: .utf8)
        
        let activeProfile = try manager.getActiveProfile()
        XCTAssertNil(activeProfile)
    }
    
    // MARK: - Parsing Tests
    
    func testParseCredentialsHandlesComments() throws {
        let contentWithComments = """
        # This is a comment
        [default]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE
        ; This is also a comment
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        
        [profile1]
        aws_access_key_id = AKIAI44QH8DHBEXAMPLE
        aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
        """
        
        try contentWithComments.write(to: tempCredentialsURL, atomically: true, encoding: .utf8)
        
        let profiles = try manager.loadProfiles()
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles[0].name, "profile1")
    }
    
    func testParseCredentialsHandlesEmptyLines() throws {
        let contentWithEmptyLines = """
        
        [default]
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE
        
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        
        
        [profile1]
        
        aws_access_key_id = AKIAI44QH8DHBEXAMPLE
        aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
        
        """
        
        try contentWithEmptyLines.write(to: tempCredentialsURL, atomically: true, encoding: .utf8)
        
        let profiles = try manager.loadProfiles()
        XCTAssertEqual(profiles.count, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testLoadProfilesThrowsFileNotFoundError() {
        let nonExistentPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent_\(UUID().uuidString)")
        let managerWithBadPath = AWSCredentialsManager(credentialsPath: nonExistentPath)
        
        XCTAssertThrowsError(try managerWithBadPath.loadProfiles()) { error in
            guard case CredentialsError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error, got \(error)")
                return
            }
        }
    }
    
    func testLoadProfilesThrowsInvalidFormatError() throws {
        // Create invalid credentials file (key-value outside section)
        let invalidContent = """
        aws_access_key_id = AKIAIOSFODNN7EXAMPLE
        [default]
        aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        """
        
        try invalidContent.write(to: tempCredentialsURL, atomically: true, encoding: .utf8)
        
        XCTAssertThrowsError(try manager.loadProfiles()) { error in
            guard case CredentialsError.invalidFormat = error else {
                XCTFail("Expected invalidFormat error, got \(error)")
                return
            }
        }
    }
    
    // MARK: - Model Tests
    
    func testAWSProfileMaskedAccessKey() {
        let profile = AWSProfile(
            id: "test",
            name: "test",
            accessKeyId: "AKIAIOSFODNN7EXAMPLE",
            isActive: false,
            lastUpdated: Date()
        )
        
        XCTAssertEqual(profile.maskedAccessKey, "AKIA...")
    }
    
    func testAWSProfileMaskedAccessKeyWithShortKey() {
        let profile = AWSProfile(
            id: "test",
            name: "test",
            accessKeyId: "ABC",
            isActive: false,
            lastUpdated: Date()
        )
        
        XCTAssertEqual(profile.maskedAccessKey, "ABC...")
    }
    
    // MARK: - UserDefaults Cache Tests
    
    func testSaveAndLoadCachedProfiles() {
        let testDefaults = UserDefaults(suiteName: "test.cache.\(UUID().uuidString)")!
        
        // Create test profiles
        let profiles = [
            AWSProfile(id: "p1", name: "profile1", accessKeyId: "AKIA1234", isActive: true, lastUpdated: Date()),
            AWSProfile(id: "p2", name: "profile2", accessKeyId: "AKIA5678", isActive: false, lastUpdated: Date())
        ]
        
        // Save profiles
        testDefaults.saveCachedProfiles(profiles)
        
        // Load profiles
        let loadedProfiles = testDefaults.loadCachedProfiles()
        
        // Verify
        XCTAssertEqual(loadedProfiles.count, 2)
        XCTAssertEqual(loadedProfiles[0].id, "p1")
        XCTAssertEqual(loadedProfiles[0].name, "profile1")
        XCTAssertEqual(loadedProfiles[0].accessKeyId, "AKIA1234")
        XCTAssertTrue(loadedProfiles[0].isActive)
        XCTAssertEqual(loadedProfiles[1].id, "p2")
        XCTAssertEqual(loadedProfiles[1].name, "profile2")
        
        // Cleanup
        testDefaults.clearCache()
    }
    
    func testLoadCachedProfilesReturnsEmptyArrayWhenNoCacheExists() {
        let testDefaults = UserDefaults(suiteName: "test.cache.\(UUID().uuidString)")!
        
        let loadedProfiles = testDefaults.loadCachedProfiles()
        
        XCTAssertEqual(loadedProfiles.count, 0)
    }
    
    func testSaveAndLoadLastActiveProfile() {
        let testDefaults = UserDefaults(suiteName: "test.cache.\(UUID().uuidString)")!
        
        // Save active profile name
        testDefaults.saveLastActiveProfile("production")
        
        // Load active profile name
        let loadedProfileName = testDefaults.loadLastActiveProfile()
        
        // Verify
        XCTAssertEqual(loadedProfileName, "production")
        
        // Cleanup
        testDefaults.clearCache()
    }
    
    func testLoadLastActiveProfileReturnsNilWhenNoCacheExists() {
        let testDefaults = UserDefaults(suiteName: "test.cache.\(UUID().uuidString)")!
        
        let loadedProfileName = testDefaults.loadLastActiveProfile()
        
        XCTAssertNil(loadedProfileName)
    }
    
    func testSaveAndLoadLastUpdateTime() {
        let testDefaults = UserDefaults(suiteName: "test.cache.\(UUID().uuidString)")!
        
        // Save timestamp
        let timestamp = Date()
        testDefaults.saveLastUpdateTime(timestamp)
        
        // Load timestamp
        let loadedTimestamp = testDefaults.loadLastUpdateTime()
        
        // Verify (allowing for small time difference due to encoding)
        XCTAssertNotNil(loadedTimestamp)
        XCTAssertEqual(loadedTimestamp?.timeIntervalSince1970 ?? 0, timestamp.timeIntervalSince1970, accuracy: 1.0)
        
        // Cleanup
        testDefaults.clearCache()
    }
    
    func testLoadLastUpdateTimeReturnsNilWhenNoCacheExists() {
        let testDefaults = UserDefaults(suiteName: "test.cache.\(UUID().uuidString)")!
        
        let loadedTimestamp = testDefaults.loadLastUpdateTime()
        
        XCTAssertNil(loadedTimestamp)
    }
    
    func testClearCacheRemovesAllCachedData() {
        let testDefaults = UserDefaults(suiteName: "test.cache.\(UUID().uuidString)")!
        
        // Save all types of data
        let profiles = [
            AWSProfile(id: "p1", name: "profile1", accessKeyId: "AKIA1234", isActive: true, lastUpdated: Date())
        ]
        testDefaults.saveCachedProfiles(profiles)
        testDefaults.saveLastActiveProfile("production")
        testDefaults.saveLastUpdateTime(Date())
        
        // Clear cache
        testDefaults.clearCache()
        
        // Verify all data is cleared
        XCTAssertEqual(testDefaults.loadCachedProfiles().count, 0)
        XCTAssertNil(testDefaults.loadLastActiveProfile())
        XCTAssertNil(testDefaults.loadLastUpdateTime())
    }
}
