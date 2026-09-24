import SwiftUI

struct ConsoleRootView: View {
    @EnvironmentObject private var session: ConsoleSession
    @Environment(\.scenePhase) private var scenePhase

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
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                guard !Task.isCancelled, scenePhase == .active, session.bootstrapState == .ready else { continue }
                await session.refreshNetwork()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, session.bootstrapState == .ready else { return }
            Task {
                await ConsoleNotifications.shared.refreshAuthorizationStatus()
                await session.refreshNetwork()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .consolePushTokenUpdated)) { _ in
            Task { await session.syncPushRegistration(force: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .consoleRemoteEvent)) { _ in
            Task { await session.refreshNetwork() }
        }
    }
}
