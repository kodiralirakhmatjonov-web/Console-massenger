import SwiftUI

struct ConsoleRootView: View {
    @EnvironmentObject private var session: ConsoleSession

    var body: some View {
        ZStack {
            ConsoleTheme.background.ignoresSafeArea()

            switch session.bootstrapState {
            case .needsIdentity:
                InitializeIdentityView()
            case .needsHandle:
                HandleSetupView()
            case .ready:
                MainConsoleView()
            }
        }
        .task {
            await session.bootstrap()
        }
    }
}
