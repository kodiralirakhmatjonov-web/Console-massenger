# Console Server — First Version Alpha

Cloudflare Worker + Durable Objects.

## What works

- identity directory (`@handle` + stable Node ID);
- Node search;
- incoming/outgoing Handshake requests;
- accept/reject Handshake;
- 1:1 Terminal creation;
- membership enforcement before history/WebSocket access;
- realtime WebSocket fan-out;
- optimistic client messages + server ACK;
- message deduplication by `client_id`;
- durable message history.

## Security status

This is an **internal alpha transport**, not a production secure messenger.

The Identity signing key is local on iOS, but request authentication and audited E2EE are intentionally not claimed in this version. Message content is currently visible to the server.

Before any public privacy/security claim we must add:

1. cryptographic request authentication;
2. device binding;
3. audited E2EE protocol (not custom crypto);
4. replay protection;
5. APNs privacy design;
6. abuse/rate limiting;
7. independent security review.

The UI explicitly reports that E2EE is not enabled.
