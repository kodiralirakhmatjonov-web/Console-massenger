import Foundation

struct ConsoleIdentity: Codable, Equatable {
    let nodeID: String
    let fingerprint: String
    let publicKeyBase64: String
    let createdAt: Date
}
