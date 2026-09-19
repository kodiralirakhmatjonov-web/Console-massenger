# Console Messenger

Native iOS-first messenger prototype.

## Current first-version loop

1. Initialize local Identity.
2. Choose a public `@handle`.
3. Configure the Cloudflare Worker endpoint.
4. Search another Node in `NETWORK`.
5. Send a Handshake request.
6. The other Node accepts or rejects it.
7. Acceptance creates a 1:1 Terminal.
8. Foreground messages use a persistent WebSocket and optimistic UI.

## Client

- Swift
- SwiftUI
- CryptoKit local signing identity
- Keychain
- URLSession / URLSessionWebSocketTask
- iOS 17+
- Bundle ID: `com.iumrah.beta`

## Server

- Cloudflare Worker
- Durable Objects
- SQLite-backed Durable Object storage

## Security notice

The first internal alpha does **not** claim E2EE. Message content is server-visible until the reviewed encryption phase is integrated.
