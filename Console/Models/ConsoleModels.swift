import Foundation

struct ConsoleIdentity: Codable, Equatable {
    let nodeID: String
    let fingerprint: String
    let publicKeyBase64: String
    let createdAt: Date
}

struct ConsoleProfile: Codable, Equatable {
    var handle: String
}

struct NetworkIdentity: Codable, Identifiable, Hashable {
    let nodeID: String
    let handle: String
    let fingerprint: String
    let publicKey: String

    var id: String { nodeID }

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case handle
        case fingerprint
        case publicKey = "public_key"
    }
}

struct HandshakeRequest: Codable, Identifiable, Hashable {
    let id: String
    let fromNode: String
    let toNode: String
    let state: String
    let createdAt: String
    let peer: NetworkIdentity?

    enum CodingKeys: String, CodingKey {
        case id
        case fromNode = "from_node"
        case toNode = "to_node"
        case state
        case createdAt = "created_at"
        case peer
    }
}

struct TerminalSummary: Codable, Identifiable, Hashable {
    let id: String
    let peer: NetworkIdentity
    let createdAt: String
    let lastMessageAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case peer
        case createdAt = "created_at"
        case lastMessageAt = "last_message_at"
    }
}

struct TerminalMessage: Codable, Identifiable, Hashable {
    let seq: Int?
    let eventID: String?
    let clientID: String
    let senderNode: String
    let content: String
    let createdAt: String
    var delivery: MessageDelivery = .delivered

    var id: String { eventID ?? clientID }

    enum CodingKeys: String, CodingKey {
        case seq
        case eventID = "event_id"
        case clientID = "client_id"
        case senderNode = "sender_node"
        case content
        case createdAt = "created_at"
    }
}

enum MessageDelivery: Hashable {
    case sending
    case sent
    case delivered
    case failed
}

struct SearchResponse: Codable {
    let identities: [NetworkIdentity]
}

struct HandshakeListResponse: Codable {
    let incoming: [HandshakeRequest]
    let outgoing: [HandshakeRequest]
}

struct TerminalListResponse: Codable {
    let terminals: [TerminalSummary]
}

struct TerminalHistoryResponse: Codable {
    let terminalID: String
    let messages: [TerminalMessage]

    enum CodingKeys: String, CodingKey {
        case terminalID = "terminal_id"
        case messages
    }
}

struct RegisterIdentityRequest: Codable {
    let nodeID: String
    let handle: String
    let publicKey: String
    let fingerprint: String

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case handle
        case publicKey = "public_key"
        case fingerprint
    }
}

struct CreateHandshakeRequest: Codable {
    let fromNode: String
    let toNode: String

    enum CodingKeys: String, CodingKey {
        case fromNode = "from_node"
        case toNode = "to_node"
    }
}

struct HandshakeDecisionRequest: Codable {
    let nodeID: String
    let decision: String

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case decision
    }
}

struct HandshakeDecisionResponse: Codable {
    let state: String
    let terminal: TerminalSummary?
}
