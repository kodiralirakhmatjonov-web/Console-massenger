import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: ConsoleSession

    var body: some View {
        Group {
            if session.identity == nil {
                InitializeIdentityView()
            } else {
                TerminalsView()
            }
        }
        .background(ConsoleTheme.background.ignoresSafeArea())
    }
}
