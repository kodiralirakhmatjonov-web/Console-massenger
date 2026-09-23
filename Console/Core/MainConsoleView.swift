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

    var subtitle: String {
        switch self {
        case .terminals: return "ACTIVE CHANNELS"
        case .network: return "DISCOVER NODES"
        case .identity: return "LOCAL SIGNATURE"
        }
    }

    var symbol: String {
        switch self {
        case .terminals: return "rectangle.stack.fill"
        case .network: return "point.3.connected.trianglepath.dotted"
        case .identity: return "person.text.rectangle.fill"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
        case .terminals: return "1"
        case .network: return "2"
        case .identity: return "3"
        }
    }
}

struct MainConsoleView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var selectedTab: ConsoleTab = .terminals

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 760
            let compactRail = proxy.size.width < 960

            ZStack {
                ConsoleBackdrop()

                if wide {
                    HStack(spacing: 0) {
                        ConsoleNavigationRail(
                            selected: $selectedTab,
                            compact: compactRail,
                            online: session.networkOnline,
                            handle: session.profile?.handle
                        )
                        .frame(width: compactRail ? 92 : 236)

                        Rectangle()
                            .fill(ConsoleTheme.line)
                            .frame(width: 1)

                        content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        ConsoleTabBar(selected: $selectedTab)
                    }
                }
            }
        }
        .background(ConsoleTheme.background)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .terminals:
            TerminalsView(onOpenNetwork: { selectedTab = .network })
        case .network:
            NetworkView()
        case .identity:
            IdentityView()
        }
    }
}

private struct ConsoleNavigationRail: View {
    @Binding var selected: ConsoleTab
    let compact: Bool
    let online: Bool
    let handle: String?

    var body: some View {
        VStack(alignment: compact ? .center : .leading, spacing: 0) {
            brand
                .padding(.horizontal, compact ? 14 : 18)
                .padding(.top, 20)
                .padding(.bottom, 24)

            VStack(spacing: 8) {
                ForEach(ConsoleTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.snappy(duration: 0.22)) {
                            selected = tab
                        }
                    } label: {
                        HStack(spacing: 13) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 22)

                            if !compact {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tab.title)
                                        .font(.console(10, weight: .black))
                                        .tracking(0.55)
                                    Text(tab.subtitle)
                                        .font(.console(7, weight: .bold))
                                        .foregroundStyle(selected == tab ? ConsoleTheme.accent.opacity(0.68) : ConsoleTheme.muted)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .foregroundStyle(selected == tab ? ConsoleTheme.accent : ConsoleTheme.secondary)
                        .padding(.horizontal, compact ? 0 : 13)
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: compact ? .center : .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected == tab ? ConsoleTheme.accent.opacity(0.075) : Color.clear)
                        )
                        .overlay {
                            if selected == tab {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(tab.shortcut, modifiers: [.command])
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            VStack(alignment: compact ? .center : .leading, spacing: 9) {
                HStack(spacing: 7) {
                    ConsoleStatusDot(active: online)
                    if !compact {
                        Text(online ? "NETWORK READY" : "NETWORK IDLE")
                            .font(.console(8, weight: .black))
                            .foregroundStyle(online ? ConsoleTheme.accent : ConsoleTheme.muted)
                    }
                }

                if !compact {
                    Text(handle.map { "@\($0)" } ?? "IDENTITY LOCAL")
                        .font(.console(9, weight: .bold))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .lineLimit(1)

                    Text("E2EE // NOT ACTIVE")
                        .font(.console(7, weight: .black))
                        .foregroundStyle(ConsoleTheme.warning)
                }
            }
            .padding(compact ? 14 : 18)
        }
        .background(ConsoleTheme.backgroundRaised.opacity(0.91))
    }

    private var brand: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ConsoleTheme.accent.opacity(0.10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
                    }
                Text(">_")
                    .font(.console(12, weight: .black))
                    .foregroundStyle(ConsoleTheme.accent)
            }
            .frame(width: 38, height: 38)

            if !compact {
                VStack(alignment: .leading, spacing: 1) {
                    Text("CONSOLE")
                        .font(.consoleDisplay(18, weight: .heavy))
                        .tracking(0.2)
                        .foregroundStyle(ConsoleTheme.text)
                    Text("HUMAN PROTOCOL")
                        .font(.console(7, weight: .black))
                        .tracking(1.0)
                        .foregroundStyle(ConsoleTheme.muted)
                }
            }
        }
    }
}

private struct ConsoleTabBar: View {
    @Binding var selected: ConsoleTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ConsoleTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.20)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.title)
                            .font(.console(7.5, weight: .black))
                            .tracking(0.45)
                    }
                    .foregroundStyle(selected == tab ? ConsoleTheme.accent : ConsoleTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
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
            Rectangle().fill(ConsoleTheme.line).frame(height: 1)
        }
    }
}
