# Console — Network Auto-Link + Identity Registry Fix + App Icon

This patch fixes the iOS app side of Network discovery and replaces the App Icon.

## Changes
- existing local Identity is automatically registered/upserted when the production endpoint becomes available;
- Network search no longer silently removes the current Identity from results; self-result is marked and cannot be handshaked;
- production endpoint is read from CONSOLE_SERVER_URL embedded at build time;
- endpoint parser rejects unresolved build placeholders and normalizes trailing slashes;
- Network/Identity show actual connection state;
- manual endpoint remains only as an Advanced override;
- marketing version default -> 1.0.1;
- AppIcon replaced from the user supplied Console artwork.

## Important
`.github/workflows` is protected by Console Auto Unpack, so the companion
`console-testflight-cloud-signing.yml` must be uploaded manually to
`.github/workflows/console-testflight-cloud-signing.yml`.
That workflow resolves `console-realtime.<account-subdomain>.workers.dev`
using the already-existing CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN secrets,
checks `/health`, and injects the exact endpoint into the archived app.
