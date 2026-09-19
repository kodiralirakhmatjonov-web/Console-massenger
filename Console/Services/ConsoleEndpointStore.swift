import Foundation

final class ConsoleEndpointStore {
    private let key = "console.server.endpoint"

    var value: URL? {
        get {
            if let stored = UserDefaults.standard.string(forKey: key),
               let url = URL(string: stored),
               !stored.isEmpty {
                return url
            }

            if let plistValue = Bundle.main.object(forInfoDictionaryKey: "CONSOLE_SERVER_URL") as? String,
               !plistValue.isEmpty,
               let url = URL(string: plistValue) {
                return url
            }

            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.absoluteString ?? "", forKey: key)
        }
    }
}
