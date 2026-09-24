import SwiftUI

@main
struct ConsoleApp: App {
    @UIApplicationDelegateAdaptor(ConsoleAppDelegate.self) private var appDelegate
    @StateObject private var session = ConsoleSession()
    @AppStorage("console.appearance") private var appearanceRaw = ConsoleAppearance.system.rawValue

    private var preferredScheme: ColorScheme? {
        ConsoleAppearance(rawValue: appearanceRaw)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            ConsoleRootView()
                .environmentObject(session)
                .preferredColorScheme(preferredScheme)
        }
    }
}
