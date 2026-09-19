import SwiftUI

@main
struct ConsoleApp: App {
    @StateObject private var session = ConsoleSession()

    var body: some Scene {
        WindowGroup {
            ConsoleRootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
    }
}
