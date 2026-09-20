# Console Production Core v1

This update turns the realtime prototype into a durable messaging core without claiming E2EE.

## Client

- Messages render optimistically and are persisted locally per Identity + Terminal.
- Unsent messages survive relaunch and return to the durable offline queue.
- WebSocket reconnect uses bounded exponential backoff and heartbeat frames.
- Queue flush happens after a real `channel_ready` frame, not immediately after `resume()`.
- Server ACK, peer delivery receipt and peer read receipt map to distinct UI states.
- History is merged with local optimistic/queued messages by stable `client_id`.

## Server

- Message sender identity is derived from the membership-checked WebSocket instead of trusting `sender_node` from the payload.
- Durable Objects persist delivery/read receipt metadata.
- History returns a real delivery state for the requesting participant.
- Duplicate `client_id` frames remain idempotent.

## Security boundary

This version still does **not** implement end-to-end encryption or strong cryptographic request authentication. Message content remains server-visible. The UI therefore continues to state `E2EE: НЕ АКТИВИРОВАНО`.
