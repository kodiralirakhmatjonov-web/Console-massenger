# Console Network Protocol v0.1

The first network layer intentionally transports only opaque encrypted payloads.

## Client → server frame

```json
{
  "type": "frame",
  "id": "client-generated-unique-id",
  "ciphertext": "BASE64URL_OR_PROTOCOL_ENVELOPE",
  "sentAt": 1789842000000
}
```

No `text`, `message`, `body`, or other plaintext field is part of the transport frame.

## Server acknowledgement

```json
{
  "type": "ack",
  "id": "client-generated-unique-id",
  "state": "persisted",
  "receivedAt": 1789842000123
}
```

`persisted` means the opaque frame has been written to the terminal's Durable Object SQLite storage. It does **not** mean that another user has read the message.

## Server → recipient frame

```json
{
  "type": "frame",
  "id": "client-generated-unique-id",
  "sender": "NODE_ID",
  "ciphertext": "BASE64URL_OR_PROTOCOL_ENVELOPE",
  "sentAt": 1789842000000,
  "receivedAt": 1789842000123
}
```

## Required before production

- cryptographic challenge-response authentication;
- terminal membership authorization;
- Handshake state machine;
- device key model;
- final E2EE session protocol;
- replay protection and deduplication rules;
- rate limiting / abuse controls;
- push notification envelope design;
- attachment encryption.
