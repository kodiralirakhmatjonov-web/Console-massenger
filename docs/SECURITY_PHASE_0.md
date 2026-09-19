# Console Security Phase 0

This document defines what build 0.1 does and does not claim.

## Implemented

- A local Ed25519 signing Identity can be generated on-device.
- Private key bytes are stored through `flutter_secure_storage`.
- The public Node ID and fingerprint are derived from SHA-256 of the public key.
- The server transport foundation is designed around opaque ciphertext frames.
- Destructive UI wording describes only the local data the prototype actually deletes.

## Not implemented yet

- recovery phrase / recovery protocol;
- multi-device identity;
- server challenge-response authentication;
- X25519 session key agreement;
- Double Ratchet or another audited asynchronous messaging protocol;
- production E2EE;
- remote identity verification;
- server-enforced Handshake authorization;
- metadata-minimization guarantees;
- hardware-backed non-exportable private keys.

## Product language rule

The UI must never claim more than the architecture can prove. For example:

- `ДАННЫЕ ДОСТАВЛЕНЫ` must only be shown after a real delivery signal exists.
- `ВЫВОД ПОДТВЕРЖДЁН` must only be shown after an explicit read acknowledgement exists.
- `СЖЕЧЬ ТЕРМИНАЛ` must state exactly which local/server copies are affected.
- Do not use `невозможно взломать`, `zero trace`, or similar absolute claims.
