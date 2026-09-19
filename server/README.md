# Console Realtime Server

Cloudflare Worker + one Durable Object instance per Terminal.

## Routes

- `GET /health`
- `GET /v1/terminals/:terminalId/history?limit=50`
- `GET /v1/terminals/:terminalId/socket?node=:nodeId` with WebSocket upgrade

## Message frame

The realtime transport currently accepts only ciphertext payloads:

```json
{
  "type": "message",
  "client_id": "01H...",
  "sender_node": "node_A1B2C3D4",
  "ciphertext": "base64-or-protocol-envelope"
}
```

Fields such as `plaintext`, `text`, and `body` are explicitly rejected.

This is a transport invariant only. It does **not** claim that Console E2EE is complete yet.
The cryptographic protocol and authenticated Identity-to-device binding remain separate phases.

## Delivery pipeline

1. client optimistic render;
2. WebSocket send;
3. Durable Object persists ciphertext;
4. sender receives `server_ack`;
5. room fans out persisted frame to other active sockets.

This order lets the client distinguish local/pending from server-persisted delivery.
