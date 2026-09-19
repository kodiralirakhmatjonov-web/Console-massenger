# Console — First Version Alpha

This update establishes the first coherent end-to-end product loop:

`Initialize Identity → choose @handle → Network → search Node → Handshake → accept → Terminal → realtime chat`

## Product rules implemented

- No fake chats on first launch.
- A Terminal does not exist before Handshake acceptance.
- `@handle` is a discovery alias, not the cryptographic identity.
- Stable Node ID remains separate from handle.
- The Console language is used for system actions without making false security claims.
- Frequent chat interaction remains simple and familiar.
- The sender renders messages optimistically before network acknowledgement.

## Navigation

- `TERMINALS`
- `NETWORK`
- `IDENTITY`

## Known alpha limitations

- No APNs yet.
- No offline persistent message queue yet.
- No attachments/voice/replies.
- No groups.
- No read receipts.
- No audited E2EE yet.
- Server endpoint is configured from `IDENTITY → NETWORK ENDPOINT` for internal TestFlight testing.

These are deliberate boundaries for the first version.
