# Console Realtime V1

Status: transport foundation.

## Runtime

- iOS: native Swift/SwiftUI.
- Foreground realtime: WebSocket.
- Edge ingress: Cloudflare Worker.
- Room coordination: Durable Objects.
- Persistence: SQLite-backed Durable Object storage.
- Attachments and APNs are not part of this update.

## Latency model

The sender renders locally before server acknowledgement. Network latency therefore does not block the local message bubble.

The server then persists the ciphertext frame and sends an acknowledgement. Other active participants receive the persisted frame over their existing WebSocket.

## Security boundary

Realtime V1 does not authenticate nodes yet and is not production-ready for private communication.

Before public testing we still need:

- signed Identity challenge authentication;
- device/session tokens;
- Handshake authorization;
- terminal membership enforcement;
- selected audited E2EE protocol;
- replay protection at the cryptographic layer;
- rate limiting and abuse controls.

No UI should claim that a channel is cryptographically secure until those layers are implemented and tested.
