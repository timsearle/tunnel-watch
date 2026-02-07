# tunnel-watch

Report whether the Rotherhithe Tunnel is open or closed, powered by the TfL Road Disruption API.

## Build

```bash
# Debug build
swift build

# Release build
swift build -c release

# Tests
swift test
```

## Install (Homebrew)

```bash
brew tap timsearle/tap
brew install tunnel-watch

# Upgrade later
brew upgrade tunnel-watch
```

## Install (Linux / Raspberry Pi)

```bash
swift build -c release
install -m 755 .build/release/tunnel-watch /usr/local/bin/tunnel-watch
```

## Quickstart (CLI)

```bash
# Help
./.build/release/tunnel-watch --help
./.build/release/tunnel-watch help status

# Status (defaults to "Rotherhithe Tunnel")
tunnel-watch status

# Quiet output for scripts
# Exit codes: 0=open, 1=closed, 2=error, 3=unknown
tunnel-watch status --quiet

# JSON output
tunnel-watch status --json

# Override the name we match on
tunnel-watch status --tunnel-name "Rotherhithe Tunnel"
```

## Flags (common)

| Option | Description |
|--------|-------------|
| `--help` | Show help |
| `--version` | Show version |

## TfL credentials (optional)

If you have credentials, set these environment variables:

```bash
export TFL_APP_ID=...
export TFL_APP_KEY=...
```

Or pass them explicitly:

```bash
tunnel-watch status --app-id "..." --app-key "..."
```

## Apple (iOS / Widget / CarPlay)

This repo includes an Apple-facing support library (`TunnelWatchAppleSupport`) intended for reuse by future iOS / WidgetKit / CarPlay UIs.

- `TunnelStatusFetcher` gives you a simple `TunnelStatusSnapshot` (open/closed/unknown)
- `TunnelStatusSimpleView` is a basic SwiftUI view for displaying the snapshot
- `TunnelWatchCarPlay.makeStatusTemplate(...)` builds a simple `CPListTemplate` when compiled for CarPlay
- `TunnelWatchWidgetProvider` provides WidgetKit-friendly entries when compiled with WidgetKit

## CI / Releases

- CI: `.github/workflows/ci.yml` runs `swift test` on push/PR.
- Release: `.github/workflows/release.yml` runs on manual dispatch and:
  - computes the next **minor** tag (e.g. `v0.0.0` → `v0.1.0`)
  - builds `tunnel-watch-macos-arm64.zip` and creates a GitHub Release
  - treats releases as **immutable** (reruns verify the existing asset but do not overwrite it)
  - triggers `timsearle/homebrew-tap`’s `update-formula.yml` to update the Homebrew formula

Required secret:
- `HOMEBREW_TAP_TOKEN`: token that can run workflows on `timsearle/homebrew-tap`.
