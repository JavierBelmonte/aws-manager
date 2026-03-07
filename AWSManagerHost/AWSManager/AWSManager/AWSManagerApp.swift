import SwiftUI

@main
struct AWSManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("AWSManager", id: "main") {
            ContentView()
                .onOpenURL { _ in
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 600, height: 450)
        .commands {
            // Remove "New Window" from File menu
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Re-open the window if all windows were closed
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}
