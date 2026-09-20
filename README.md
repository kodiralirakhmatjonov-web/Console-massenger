Console Network compile fix

Fixes the current GitHub Actions Swift compile failure where NetworkView
references the production visual system components but the repository has
an older ConsoleComponents.swift.

Restores:
- ConsoleBackdrop
- ConsoleMetricStrip
- ConsoleSystemLine
- ConsoleWindowCard
- ConsoleSectionLabel
- ConsoleStatusPill
- ConsoleCommandButton

No backend, Bundle ID, signing, workflow, or Cloudflare configuration changes.
