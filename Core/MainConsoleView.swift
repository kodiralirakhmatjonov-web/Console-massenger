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
        ZStack {
            ConsoleBackdrop()

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
        }
    }
}

private struct ConsoleTabBar: View {
    @Binding var selected: ConsoleTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ConsoleTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 7) {
                        Capsule()
                            .fill(selected == tab ? ConsoleTheme.accent : Color.clear)
                            .frame(width: 20, height: 2)
                            .shadow(color: selected == tab ? ConsoleTheme.accent.opacity(0.45) : .clear, radius: 5)

                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .semibold))

                        Text(tab.title)
                            .font(.console(7.5, weight: .black))
                            .tracking(0.7)
                    }
                    .foregroundStyle(selected == tab ? ConsoleTheme.text : ConsoleTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 61)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 5)
        .padding(.bottom, 3)
        .background(Color.black.opacity(0.97))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ConsoleTheme.line)
                .frame(height: 1)
        }
    }
}
