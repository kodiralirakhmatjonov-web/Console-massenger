# Console Network v0.1

Realtime transport foundation for Console.

## What it does now

- Cloudflare Worker routes each terminal to a named Durable Object.
- Durable Object uses the WebSocket Hibernation API.
- Each terminal has SQLite-backed Durable Object storage.
- Server only accepts opaque `ciphertext` frames; no plaintext message field exists in the protocol.
- Frames are persisted before the sender receives `ack: persisted`.
- Persisted frames are fanned out to other live WebSocket clients in the same terminal.
- `/history` returns opaque encrypted frames for later client-side decryption.

## Important security boundary

This is a transport foundation, **not production authentication or E2EE**.

The `node` query parameter is not authenticated yet. Do not treat it as proof of Identity. Before public deployment, Console still needs challenge-response authentication, membership authorization, Handshake state enforcement, replay protection, rate limits, and the final E2EE protocol.

## Local commands

```bash
npm install
npm run check
npx wrangler dev
```

Health endpoint:

```text
GET /health
```

Realtime endpoint:

```text
GET /v1/terminal/:terminalId/socket?node=:nodeId
Upgrade: websocket
```

History endpoint:

```text
GET /v1/terminal/:terminalId/history?limit=50&before=<unix_ms>
```
