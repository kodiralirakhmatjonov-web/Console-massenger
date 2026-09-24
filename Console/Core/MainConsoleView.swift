import SwiftUI

enum ConsoleTab: String, CaseIterable {
    case terminals
    case network
    case identity
    case settings

    var title: String {
        switch self {
        case .terminals: return "TERMINALS"
        case .network: return "NETWORK"
        case .identity: return "IDENTITY"
        case .settings: return "SETTINGS"
        }
    }

    var compactTitle: String {
        switch self {
        case .terminals: return "ЧАТЫ"
        case .network: return "СЕТЬ"
        case .identity: return "ID"
        case .settings: return "НАСТРОЙКИ"
        }
    }

    var subtitle: String {
        switch self {
        case .terminals: return "ACTIVE CHANNELS"
        case .network: return "DISCOVER NODES"
        case .identity: return "LOCAL SIGNATURE"
        case .settings: return "CONTROL CENTER"
        }
    }

    var symbol: String {
        switch self {
        case .terminals: return "bubble.left.and.bubble.right.fill"
        case .network: return "point.3.connected.trianglepath.dotted"
        case .identity: return "person.text.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
        case .terminals: return "1"
        case .network: return "2"
        case .identity: return "3"
        case .settings: return "4"
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

            ZStack(alignment: .top) {
                ConsoleBackdrop()

                if wide {
                    HStack(spacing: 0) {
                        ConsoleNavigationRail(
                            selected: $selectedTab,
                            compact: compactRail,
                            online: session.networkOnline,
                            handle: session.profile?.handle,
                            handshakeCount: session.incomingHandshakes.count
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

                        if !session.terminalFullscreenActive {
                            ConsoleTabBar(
                                selected: $selectedTab,
                                handshakeCount: session.incomingHandshakes.count
                            )
                        }
                    }
                }

                if let event = session.activityEvent {
                    ConsoleActivityBanner(event: event) {
                        session.dismissActivity()
                    }
                    .padding(.horizontal, wide ? 24 : 12)
                    .padding(.top, 10)
                    .frame(maxWidth: wide ? 620 : .infinity)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
                    .task(id: event.id) {
                        try? await Task.sleep(nanoseconds: 4_500_000_000)
                        if session.activityEvent?.id == event.id {
                            withAnimation(.snappy) { session.dismissActivity() }
                        }
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
        case .settings:
            SettingsView()
        }
    }
}

private struct ConsoleNavigationRail: View {
    @Binding var selected: ConsoleTab
    let compact: Bool
    let online: Bool
    let handle: String?
    let handshakeCount: Int

    var body: some View {
        VStack(alignment: compact ? .center : .leading, spacing: 0) {
            brand
                .padding(.horizontal, compact ? 14 : 18)
                .padding(.top, 20)
                .padding(.bottom, 24)

            VStack(spacing: 8) {
                ForEach(ConsoleTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.snappy(duration: 0.22)) { selected = tab }
                    } label: {
                        HStack(spacing: 13) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: tab.symbol)
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(width: 22, height: 22)

                                if tab == .network && handshakeCount > 0 {
                                    Text("\(min(handshakeCount, 9))")
                                        .font(.system(size: 8, weight: .black, design: .rounded))
                                        .foregroundStyle(.black)
                                        .frame(width: 14, height: 14)
                                        .background(ConsoleTheme.accent)
                                        .clipShape(Circle())
                                        .offset(x: 7, y: -7)
                                }
                            }

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
    let handshakeCount: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(ConsoleTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.20)) { selected = tab }
                } label: {
                    VStack(spacing: 5) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 17, weight: .semibold))
                                .frame(height: 20)

                            if tab == .network && handshakeCount > 0 {
                                Text("\(min(handshakeCount, 9))")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundStyle(.black)
                                    .frame(width: 14, height: 14)
                                    .background(ConsoleTheme.accent)
                                    .clipShape(Circle())
                                    .offset(x: 9, y: -5)
                            }
                        }

                        Text(tab.compactTitle)
                            .font(.console(6.8, weight: .black))
                            .tracking(0.15)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .foregroundStyle(selected == tab ? ConsoleTheme.accent : ConsoleTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 59)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selected == tab ? ConsoleTheme.accent.opacity(0.075) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 7)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(ConsoleTheme.line).frame(height: 1)
        }
    }
}

private struct ConsoleActivityBanner: View {
    let event: ConsoleActivityEvent
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.console(9, weight: .black))
                    .foregroundStyle(ConsoleTheme.text)
                Text(event.detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(11)
        .background(.ultraThinMaterial)
        .background(ConsoleTheme.backgroundRaised.opacity(0.82))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(ConsoleTheme.lineStrong, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .shadow(color: ConsoleTheme.shadow, radius: 20, y: 8)
    }

    private var symbol: String {
        switch event.kind {
        case .handshake: return "link.badge.plus"
        case .connection: return "checkmark.shield.fill"
        case .message: return "bubble.left.fill"
        case .system: return "terminal.fill"
        }
    }

    private var color: Color {
        switch event.kind {
        case .handshake, .message, .connection: return ConsoleTheme.accent
        case .system: return ConsoleTheme.cyan
        }
    }
}
