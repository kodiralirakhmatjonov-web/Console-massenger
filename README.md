# Console Messenger

**Secure terminal for human communication.**

Build 0.1 establishes the real product foundation instead of a throwaway mockup.

## Included in this update

### Flutter client

- premium dark-first Console visual system;
- local Ed25519 Identity creation;
- private key storage through platform secure storage;
- deterministic Node ID and public-key fingerprint;
- Identity view;
- Terminal list;
- Discover Node flow;
- Handshake ritual;
- Terminal UI with optimistic local sending states;
- semantically careful Burn Terminal flow;
- RU CORE system language.

### Cloudflare network foundation

- Worker routing;
- SQLite-backed Durable Object per terminal;
- WebSocket Hibernation API;
- persist-before-ACK message pipeline;
- realtime fan-out;
- encrypted-frame-only transport schema;
- opaque history endpoint.

The mobile client is **not wired to the network transport yet** because production E2EE/authentication has not been specified. This is intentional: Console will not send plaintext just to make the demo appear more complete.

## Project state

```text
Phase 0  Security specification       IN PROGRESS
Phase 1  Flutter product prototype    STARTED
Phase 2  Cloudflare transport core    STARTED
Phase 3  Crypto identity/auth         PARTIAL
Phase 4  Production E2EE              NOT STARTED
```

## Platform scaffolding

This repository can initially exist without generated `ios/`, `android/`, and `web/` folders. On a machine or CI runner with Flutter installed, run:

```bash
./scripts/bootstrap_flutter_platforms.sh
```

The script generates the Flutter platform scaffolding, restores the Console source files, runs dependency resolution and analysis, and targets the current TestFlight bundle ID:

```text
com.iumrah.beta
```

## Cloudflare server

```bash
cd server
npm install
npm run check
npx wrangler dev
```

See:

- `docs/SECURITY_PHASE_0.md`
- `docs/NETWORK_PROTOCOL_V0.md`
- `server/README.md`

## Next engineering step

Implement signed server challenge authentication and the Handshake state machine before connecting real message traffic from the Flutter client.
