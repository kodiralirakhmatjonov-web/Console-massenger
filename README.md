# Console — Console Beta App Store identity

This patch detaches Console from the any former application identity.

## New application identity

- Product: `Console`
- Bundle ID: `com.console.beta`
- Keychain identity service: `com.console.beta.identity`
- App Store Connect/TestFlight workflow Bundle ID: `com.console.beta`

## Apple setup

1. In Apple Developer → Certificates, Identifiers & Profiles → Identifiers, create an explicit App ID with Bundle ID `com.console.beta`.
2. In App Store Connect → Apps → + → New App, create a new iOS app named `Console` and choose `com.console.beta`.
3. Keep the existing GitHub Apple Team/API-key secrets; they belong to the developer team, not the old Iumrah app.
4. Upload this patch through the repository auto-unpack flow.
5. Run `Console — TestFlight Cloud Signing` as a new workflow run.

The project also declares `ITSAppUsesNonExemptEncryption = NO` for the current build configuration.
