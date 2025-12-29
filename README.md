# tunnel-watch

A tiny CLI to report whether the Rotherhithe Tunnel is open or closed, powered by the TfL Road Disruption API.

## Install / Build

```sh
swift build -c release
```

## Usage

```sh
# Defaults to "Rotherhithe Tunnel"
swift run tunnel-watch status

# JSON output
swift run tunnel-watch status --json

# Quiet output for scripts
swift run tunnel-watch status --quiet

# Override the name we match on (case-insensitive substring match)
swift run tunnel-watch status --tunnel-name "Rotherhithe Tunnel"
```

## TfL credentials (optional)

Set these environment variables if you have them:

```sh
export TFL_APP_ID=...
export TFL_APP_KEY=...
```
