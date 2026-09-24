import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var session: ConsoleSession

    @StateObject private var notifications = ConsoleNotifications.shared

    @AppStorage("console.appearance") private var appearanceRaw = ConsoleAppearance.system.rawValue
    @AppStorage("console.notifications.enabled") private var notificationsEnabled = true
    @AppStorage("console.notifications.previews") private var notificationPreviews = true
    @AppStorage("console.notifications.sound") private var notificationSound = true
    @AppStorage("console.effects.enabled") private var effectsEnabled = true
    @AppStorage("console.effects.reduceMotion") private var reduceMotion = false
    @AppStorage("console.interface.showProtocolHints") private var showProtocolHints = true
    @AppStorage("console.interface.compactTerminalList") private var compactTerminalList = false

    @State private var endpoint = ""
    @State private var endpointMessage: String?
    @State private var notificationMessage: String?
    @State private var isRequestingNotifications = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ConsoleBackdrop()

                ScrollView {
                    VStack(spacing: 18) {
                        ConsoleHeader(
                            path: "console://settings",
                            title: "Настройки",
                            trailing: "CONTROL"
                        )

                        ConsoleMetricStrip(metrics: [
                            ("THEME", appearanceTitle, ConsoleTheme.accent),
                            ("NOTIFY", notificationsEnabled ? authorizationStatusShort : "OFF", notificationsEnabled ? ConsoleTheme.accent : ConsoleTheme.warning),
                            ("EFFECTS", effectsEnabled ? "READY" : "OFF", effectsEnabled ? ConsoleTheme.cyan : ConsoleTheme.muted)
                        ])

                        if proxy.size.width >= 980 {
                            HStack(alignment: .top, spacing: 14) {
                                VStack(spacing: 14) {
                                    profileCard
                                    appearanceCard
                                    effectsCard
                                    aboutCard
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 14) {
                                    notificationsCard
                                    privacyCard
                                    networkCard
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            profileCard
                            notificationsCard
                            appearanceCard
                            privacyCard
                            effectsCard
                            networkCard
                            aboutCard
                        }
                    }
                    .consolePageFrame(maxWidth: 1240)
                    .padding(.horizontal, proxy.size.width >= 760 ? 28 : 14)
                    .padding(.top, proxy.size.width >= 760 ? 26 : 16)
                    .padding(.bottom, 34)
                }
            }
        }
        .task {
            endpoint = session.endpointStore.value?.absoluteString ?? ""
            await notifications.refreshAuthorizationStatus()
        }
        .onChange(of: notificationsEnabled) { _, enabled in
            Task {
                if enabled {
                    let granted = await notifications.requestAuthorization()
                    if granted {
                        notificationMessage = "УВЕДОМЛЕНИЯ АКТИВИРОВАНЫ"
                        await session.syncPushRegistration(force: true)
                    } else {
                        notificationMessage = "ДОСТУП НЕ ПРЕДОСТАВЛЕН"
                    }
                } else {
                    notificationMessage = "УВЕДОМЛЕНИЯ ОТКЛЮЧЕНЫ"
                    await session.disablePushRegistration()
                }
            }
        }
        .onChange(of: notificationPreviews) { _, _ in
            guard notificationsEnabled else { return }
            Task { await session.syncPushRegistration(force: true) }
        }
        .onChange(of: notificationSound) { _, _ in
            guard notificationsEnabled else { return }
            Task { await session.syncPushRegistration(force: true) }
        }
    }

    private var appearanceTitle: String {
        ConsoleAppearance(rawValue: appearanceRaw)?.title.uppercased() ?? "СИСТЕМА"
    }

    private var authorizationStatusShort: String {
        switch notifications.authorizationStatus {
        case .authorized: return "ON"
        case .provisional: return "QUIET"
        case .notDetermined: return "ASK"
        default: return "OFF"
        }
    }

    private var profileCard: some View {
        ConsoleWindowCard(title: "settings://profile") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 13) {
                    ConsoleNodeGlyph(active: true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("@\(session.profile?.handle ?? "unknown")")
                            .font(.consoleDisplay(20, weight: .bold))
                            .foregroundStyle(ConsoleTheme.text)
                        Text("ЛОКАЛЬНАЯ IDENTITY")
                            .font(.console(8.5, weight: .black))
                            .foregroundStyle(ConsoleTheme.accent)
                    }

                    Spacer(minLength: 0)

                    ConsoleStatusPill(text: session.networkOnline ? "CONNECTED" : "OFFLINE", active: session.networkOnline)
                }

                Rectangle().fill(ConsoleTheme.line).frame(height: 1)

                settingsValueRow(title: "Узел", value: session.identity?.nodeID ?? "—")
                settingsValueRow(title: "Отпечаток", value: session.identity?.fingerprint ?? "—")
                settingsValueRow(title: "Сервер", value: session.endpointStore.value?.host ?? "не задан")

                HStack(spacing: 12) {
                    ConsoleCommandButton(title: "КОПИРОВАТЬ NODE ID") {
                        UIPasteboard.general.string = session.identity?.nodeID
                    }

                    ConsoleCommandButton(title: "КОПИРОВАТЬ ОТПЕЧАТОК") {
                        UIPasteboard.general.string = session.identity?.fingerprint
                    }
                }
            }
        }
    }

    private var notificationsCard: some View {
        ConsoleWindowCard(title: "settings://notifications") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ConsoleSystemLine(
                        text: notificationsEnabled ? "activity channel enabled" : "activity channel disabled",
                        tone: notificationsEnabled ? .success : .warning
                    )
                    Spacer(minLength: 0)
                }

                settingsToggleRow(
                    icon: "bell.badge.fill",
                    color: ConsoleTheme.accent,
                    title: "Уведомления",
                    subtitle: "Сообщения, Handshake и системная активность",
                    isOn: $notificationsEnabled
                )

                settingsToggleRow(
                    icon: "text.bubble.fill",
                    color: ConsoleTheme.cyan,
                    title: "Предпросмотр",
                    subtitle: "Показывать текст сообщения в пуше",
                    isOn: $notificationPreviews,
                    disabled: !notificationsEnabled
                )

                settingsToggleRow(
                    icon: "speaker.wave.2.fill",
                    color: ConsoleTheme.warning,
                    title: "Звук",
                    subtitle: "Звук для пушей и локальных событий",
                    isOn: $notificationSound,
                    disabled: !notificationsEnabled
                )

                settingsInfoRow(
                    icon: "hand.raised.circle.fill",
                    color: ConsoleTheme.secondary,
                    title: "Системный доступ",
                    value: notifications.statusTitle
                )

                if let notificationMessage {
                    ConsoleSystemLine(text: notificationMessage, tone: .success)
                }

                Button {
                    guard !isRequestingNotifications else { return }
                    isRequestingNotifications = true
                    Task {
                        let granted = await notifications.requestAuthorization()
                        await session.syncPushRegistration(force: granted)
                        await MainActor.run {
                            notificationMessage = granted ? "РАЗРЕШЕНИЕ ПОЛУЧЕНО" : "РАЗРЕШЕНИЕ НЕ ПОЛУЧЕНО"
                            isRequestingNotifications = false
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isRequestingNotifications {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "bell.badge")
                        }
                        Text("ПРОВЕРИТЬ И АКТИВИРОВАТЬ")
                        Spacer()
                        Text("APNs")
                            .font(.console(8, weight: .black))
                    }
                    .font(.console(10, weight: .black))
                    .foregroundStyle(ConsoleTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var appearanceCard: some View {
        ConsoleWindowCard(title: "settings://appearance") {
            VStack(alignment: .leading, spacing: 16) {
                ConsoleSystemLine(text: "readability mode configured for public users", tone: .success)

                VStack(alignment: .leading, spacing: 10) {
                    Text("ОФОРМЛЕНИЕ")
                        .font(.console(8, weight: .black))
                        .foregroundStyle(ConsoleTheme.muted)

                    Picker("Оформление", selection: $appearanceRaw) {
                        ForEach(ConsoleAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                settingsToggleRow(
                    icon: "rectangle.tophalf.inset.filled",
                    color: ConsoleTheme.accent,
                    title: "Подсказки протокола",
                    subtitle: "Показывать console:// строки и служебные статусы в чате",
                    isOn: $showProtocolHints
                )

                settingsToggleRow(
                    icon: "rectangle.grid.1x2.fill",
                    color: ConsoleTheme.cyan,
                    title: "Компактный список чатов",
                    subtitle: "Плотнее отображать список терминалов",
                    isOn: $compactTerminalList
                )
            }
        }
    }

    private var privacyCard: some View {
        ConsoleWindowCard(title: "settings://privacy") {
            VStack(alignment: .leading, spacing: 16) {
                settingsInfoRow(
                    icon: "checkmark.shield.fill",
                    color: ConsoleTheme.accent,
                    title: "Handshake",
                    value: "Незнакомцы проходят запрос соединения"
                )

                settingsInfoRow(
                    icon: "eye.slash.fill",
                    color: ConsoleTheme.warning,
                    title: "E2EE",
                    value: "Пока не заявляется в этой версии"
                )

                settingsInfoRow(
                    icon: "person.crop.circle.badge.questionmark",
                    color: ConsoleTheme.secondary,
                    title: "Публичность",
                    value: "Показывается только handle и открытая сигнатура"
                )

                Text("Настройки приватности формулируются честно: приложение не создаёт ложного ощущения безопасности и не обещает то, чего архитектура ещё не поддерживает.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(4)
            }
        }
    }

    private var effectsCard: some View {
        ConsoleWindowCard(title: "settings://effects") {
            VStack(alignment: .leading, spacing: 16) {
                settingsToggleRow(
                    icon: "sparkles.rectangle.stack.fill",
                    color: ConsoleTheme.cyan,
                    title: "Console FX",
                    subtitle: "Включить визуальные hacker / protocol эффекты в чатах",
                    isOn: $effectsEnabled
                )

                settingsToggleRow(
                    icon: "figure.walk.motion",
                    color: ConsoleTheme.secondary,
                    title: "Меньше движения",
                    subtitle: "Снизить анимацию эффектов и вспышек",
                    isOn: $reduceMotion,
                    disabled: !effectsEnabled
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("КАК ПРОВЕРИТЬ")
                        .font(.console(8, weight: .black))
                        .foregroundStyle(ConsoleTheme.muted)

                    Text("Откройте любой Terminal и отправьте команду /hacked, /panic, /trace, /breach, /ghost или /wake. Эффект появится локально. Если вторая сторона использует новую версию Console, эффект появится и у неё после получения такого сообщения.")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .lineSpacing(4)
                }

                VStack(alignment: .leading, spacing: 7) {
                    effectCommandRow("/hacked", description: "симуляция внешнего вмешательства")
                    effectCommandRow("/panic", description: "красный аварийный режим")
                    effectCommandRow("/trace", description: "поиск маршрута / источника")
                    effectCommandRow("/breach", description: "режим нарушения периметра")
                    effectCommandRow("/ghost", description: "режим тени / исчезновения")
                    effectCommandRow("/wake", description: "сигнал пробуждения / внимания")
                }
            }
        }
    }

    private var networkCard: some View {
        ConsoleWindowCard(title: "settings://network") {
            VStack(alignment: .leading, spacing: 16) {
                ConsoleField(prompt: "https://api.example.com", text: $endpoint)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                HStack(spacing: 12) {
                    ConsolePrimaryButton(title: "СОХРАНИТЬ СЕРВЕР") {
                        do {
                            try session.saveServerURL(endpoint)
                            endpoint = session.endpointStore.value?.absoluteString ?? endpoint
                            endpointMessage = "АДРЕС СЕТИ СОХРАНЁН"
                        } catch {
                            endpointMessage = error.localizedDescription
                        }
                    }

                    ConsolePrimaryButton(title: "ПРОВЕРИТЬ СЕТЬ") {
                        Task { await session.refreshNetwork() }
                    }
                }

                settingsInfoRow(
                    icon: "dot.radiowaves.left.and.right",
                    color: session.networkOnline ? ConsoleTheme.accent : ConsoleTheme.warning,
                    title: "Состояние",
                    value: session.networkOnline ? "СЕТЬ ДОСТУПНА" : "СЕТЬ НЕ ПОДКЛЮЧЕНА"
                )

                if let endpointMessage {
                    ConsoleSystemLine(
                        text: endpointMessage,
                        tone: endpointMessage.contains("СОХРАН") ? .success : .warning
                    )
                }
            }
        }
    }

    private var aboutCard: some View {
        ConsoleCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("О Console")
                    .font(.consoleDisplay(20, weight: .bold))
                    .foregroundStyle(ConsoleTheme.text)

                Text("Console — терминал человеческого общения. Эта версия улучшает читаемость интерфейса, добавляет светлую тему, полноценные настройки, управление уведомлениями и визуальные Console FX для демонстрации продукта.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(4)

                Rectangle().fill(ConsoleTheme.line).frame(height: 1)

                HStack {
                    settingsMiniInfo(title: "Версия", value: "1.2.0")
                    Spacer()
                    settingsMiniInfo(title: "Платформы", value: "iPhone • iPad • Mac")
                    Spacer()
                    settingsMiniInfo(title: "Transport", value: "Realtime V1")
                }
            }
        }
    }

    private func settingsValueRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.console(7.5, weight: .black))
                .foregroundStyle(ConsoleTheme.muted)
            Text(value)
                .font(.console(9, weight: .bold))
                .foregroundStyle(ConsoleTheme.secondary)
                .textSelection(.enabled)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
    }

    private func settingsInfoRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            SettingsGlyph(icon: icon, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ConsoleTheme.text)
                Text(value)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 1)
    }

    private func settingsToggleRow(icon: String, color: Color, title: String, subtitle: String, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack(spacing: 12) {
            SettingsGlyph(icon: icon, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(disabled ? ConsoleTheme.muted : ConsoleTheme.text)
                Text(subtitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .disabled(disabled)
        }
        .opacity(disabled ? 0.55 : 1)
    }

    private func effectCommandRow(_ command: String, description: String) -> some View {
        HStack(spacing: 12) {
            Text(command)
                .font(.console(10, weight: .black))
                .foregroundStyle(ConsoleTheme.accent)
                .frame(width: 82, alignment: .leading)

            Text(description)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(ConsoleTheme.secondary)

            Spacer(minLength: 0)
        }
    }

    private func settingsMiniInfo(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.console(7.5, weight: .black))
                .foregroundStyle(ConsoleTheme.muted)
            Text(value)
                .font(.console(9, weight: .bold))
                .foregroundStyle(ConsoleTheme.text)
        }
    }
}

private struct SettingsGlyph: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(color.opacity(0.12))
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 38, height: 38)
    }
}
