# Console Server — Realtime Core v1

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
- durable message history;
- delivery receipts;
- read receipts;
- durable receipt metadata;
- server-side sender binding to the membership-checked WebSocket node.

## Security status

This is a production-oriented realtime core, **not yet an E2EE secure messenger**.

The Identity signing key is local on iOS, but strong cryptographic request authentication and audited E2EE are not implemented yet. Message content is currently visible to the server.

Before any public privacy/security claim we still need:

1. cryptographic request authentication;
2. device binding;
3. audited E2EE protocol (not custom crypto);
4. replay protection;
5. APNs privacy design;
6. abuse/rate limiting;
7. independent security review.

The UI explicitly reports that E2EE is not enabled.
