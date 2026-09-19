import SwiftUI

struct NetworkView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var query = ""
    @State private var results: [NetworkIdentity] = []
    @State private var searching = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                ConsoleTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        ConsoleHeader(
                            path: "console://network",
                            title: "NETWORK",
                            trailing: session.api.baseURL == nil ? "OFFLINE" : "READY"
                        )
                        .padding(.bottom, 8)

                        searchPanel
                        requestPanel
                        resultPanel

                        if let errorText {
                            Text(errorText)
                                .font(.console(10, weight: .bold))
                                .foregroundStyle(ConsoleTheme.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await session.refreshNetwork()
                }
            }
            .navigationDestination(for: HandshakeRequest.self) { request in
                HandshakeDetailView(request: request)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var searchPanel: some View {
        ConsoleCard {
            VStack(alignment: .leading, spacing: 13) {
                Text("ПОИСК УЗЛА")
                    .font(.console(10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)

                ConsoleField(prompt: "@handle или node_id", text: $query)
                    .onSubmit {
                        performSearch()
                    }

                HStack {
                    Button {
                        performSearch()
                    } label: {
                        Text(searching ? "СКАНИРОВАНИЕ..." : "СКАНИРОВАТЬ NETWORK")
                            .font(.console(10, weight: .bold))
                            .foregroundStyle(ConsoleTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(searching || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()

                    Image(systemName: "qrcode.viewfinder")
                        .foregroundStyle(ConsoleTheme.muted)
                }
            }
        }
    }

    private var requestPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ПОПЫТКИ ПОДКЛЮЧЕНИЯ")
                    .font(.console(10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)

                Spacer()

                Text(String(format: "%02d", session.incomingHandshakes.count))
                    .font(.console(10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.accent)
            }

            if session.incomingHandshakes.isEmpty {
                ConsoleCard {
                    Text("ВХОДЯЩИХ ЗАПРОСОВ: 0")
                        .font(.console(11, weight: .bold))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(session.incomingHandshakes) { request in
                    NavigationLink(value: request) {
                        ConsoleCard {
                            HStack(spacing: 12) {
                                ConsoleStatusDot(active: true)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("@\(request.peer?.handle ?? request.fromNode)")
                                        .font(.console(14, weight: .bold))
                                        .foregroundStyle(ConsoleTheme.text)
                                    Text("ЗАПРОС СОЕДИНЕНИЯ")
                                        .font(.console(9, weight: .bold))
                                        .foregroundStyle(ConsoleTheme.accent)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(ConsoleTheme.muted)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private var resultPanel: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("СОВПАДЕНИЯ")
                    .font(.console(10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(results) { identity in
                    ConsoleCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("@\(identity.handle)")
                                        .font(.console(15, weight: .bold))
                                        .foregroundStyle(ConsoleTheme.text)
                                    Text(identity.nodeID)
                                        .font(.console(9))
                                        .foregroundStyle(ConsoleTheme.muted)
                                }

                                Spacer()

                                Text("NODE")
                                    .font(.console(9, weight: .bold))
                                    .foregroundStyle(ConsoleTheme.accent)
                            }

                            Text(identity.fingerprint)
                                .font(.console(10, weight: .medium))
                                .foregroundStyle(ConsoleTheme.secondary)
                                .lineLimit(1)

                            Button {
                                requestConnection(identity)
                            } label: {
                                Text("УСТАНОВИТЬ СОЕДИНЕНИЕ  →")
                                    .font(.console(10, weight: .bold))
                                    .foregroundStyle(ConsoleTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, 6)
        }
    }

    private func performSearch() {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        searching = true
        errorText = nil

        Task {
            do {
                results = try await session.search(value)
            } catch {
                errorText = error.localizedDescription
            }
            searching = false
        }
    }

    private func requestConnection(_ identity: NetworkIdentity) {
        Task {
            do {
                try await session.requestConnection(to: identity)
                results.removeAll { $0.id == identity.id }
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
