import SwiftUI

enum ConsoleTab: String, CaseIterable {
    case terminals
    case network
    case identity

    var title: String {
        switch self {
        case .terminals: return "TERMINALS"
        case .network: return "NETWORK"
        case .identity: return "IDENTITY"
        }
    }

    var symbol: String {
        switch self {
        case .terminals: return "rectangle.stack"
        case .network: return "antenna.radiowaves.left.and.right"
        case .identity: return "person.crop.square"
        }
    }
}

struct MainConsoleView: View {
    @State private var selectedTab: ConsoleTab = .terminals

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .terminals:
                    TerminalsView(onOpenNetwork: { selectedTab = .network })
                case .network:
                    NetworkView()
                case .identity:
                    IdentityView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ConsoleTabBar(selected: $selectedTab)
        }
        .background(ConsoleTheme.background)
    }
}

private struct ConsoleTabBar: View {
    @Binding var selected: ConsoleTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ConsoleTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.20)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 17, weight: .semibold))

                        Text(tab.title)
                            .font(.console(8, weight: .bold))
                            .tracking(0.6)
                    }
                    .foregroundStyle(selected == tab ? ConsoleTheme.accent : ConsoleTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selected == tab ? ConsoleTheme.accent.opacity(0.07) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ConsoleTheme.line)
                .frame(height: 1)
        }
    }
}
