import AppIntents
import Foundation
import os.log

/// App Intent for switching the active AWS profile from the widget
struct SwitchProfileIntent: AppIntent {
    static var title: LocalizedStringResource = "Switch AWS Profile"
    static var description = IntentDescription("Switches the active AWS profile to the specified profile name")
    
    /// The name of the profile to switch to
    @Parameter(title: "Profile Name")
    var profileName: String
    
    /// Perform the profile switch operation
    func perform() async throws -> some IntentResult {
        let logger = Logger(subsystem: "com.awsmanager.widget", category: "intent")
        logger.info("SwitchProfileIntent invoked for profile: \(self.profileName)")
        
        let manager = AWSCredentialsManager.shared
        
        do {
            // Attempt to switch the active profile
            try manager.setActiveProfile(profileName: profileName)
            
            logger.info("Successfully switched to profile: \(self.profileName)")
            
            // Return success result
            return .result(
                dialog: IntentDialog("Successfully switched to profile \(profileName)")
            )
            
        } catch let error as CredentialsError {
            // Handle specific credentials errors
            logger.error("Failed to switch profile: \(error.localizedDescription)")
            
            // Throw the error - AppIntents will handle displaying it to the user
            throw error
            
        } catch {
            // Handle unexpected errors
            logger.error("Unexpected error switching profile: \(error.localizedDescription)")
            
            // Re-throw the error
            throw error
        }
    }
}
