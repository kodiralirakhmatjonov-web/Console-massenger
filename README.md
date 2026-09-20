Console UI Foundation Final Fix

Purpose:
- fixes current TestFlight compile error:
  Font has no member 'consoleDisplay'
- prevents another Theme / Components / Network / Identity version mismatch

Includes only:
- Console/Core/ConsoleTheme.swift
- Console/Components/ConsoleComponents.swift
- Console/Features/Network/NetworkView.swift
- Console/Features/Identity/IdentityView.swift

Preserves:
- com.console.beta
- Cloudflare auto endpoint
- current production network/search logic
- current visual system
- backend/signing/workflows untouched

Validation:
- all included Swift files pass swiftc frontend parse
- Font.consoleDisplay declaration verified
- required production UI component declarations verified
