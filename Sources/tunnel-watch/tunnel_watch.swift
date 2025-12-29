import Foundation
import TunnelWatchCore

@main
struct TunnelWatchCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("-h") || args.contains("--help") {
            print(usage)
            return
        }

        let command = args.first
        let commandArgs = command == nil || command == "status" ? args.dropFirst(command == nil ? 0 : 1) : args.dropFirst(1)

        guard command == nil || command == "status" else {
            fputs("Unknown command: \(command!)\n\n", stderr)
            print(usage)
            Darwin.exit(2)
        }

        do {
            let options = try Options.parse(Array(commandArgs))

            let client = TfLClient(
                baseURL: options.baseURL,
                appId: options.appId,
                appKey: options.appKey
            )

            let service = TunnelStatusService(client: client)
            let result = try await service.fetchTunnelStatus(tunnelName: options.tunnelName)

            if options.json {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(result)
                FileHandle.standardOutput.write(data)
                FileHandle.standardOutput.write("\n".data(using: .utf8)!)
            } else {
                if options.quiet {
                    print(result.state.rawValue.uppercased())
                } else {
                    print("\(result.tunnelName): \(result.state.rawValue.uppercased()) — \(result.severityDescription)")
                }
            }

            switch result.state {
            case .open:
                Darwin.exit(0)
            case .closed:
                Darwin.exit(1)
            case .unknown:
                Darwin.exit(3)
            }
        } catch {
            fputs("Error: \(error)\n", stderr)
            Darwin.exit(2)
        }
    }
}

private let usage = """
Usage:
  tunnel-watch status [--tunnel-name <name>] [--json] [--quiet] [--base-url <url>]

Environment:
  TFL_APP_ID
  TFL_APP_KEY

Exit codes:
  0: open
  1: closed
  2: error
  3: unknown

Examples:
  tunnel-watch status
  tunnel-watch status --tunnel-name "Rotherhithe Tunnel"
  tunnel-watch status --json
"""

private struct Options {
    var tunnelName: String = "Rotherhithe Tunnel"
    var json: Bool = false
    var quiet: Bool = false
    var baseURL: URL = URL(string: "https://api.tfl.gov.uk")!
    var appId: String? = ProcessInfo.processInfo.environment["TFL_APP_ID"]
    var appKey: String? = ProcessInfo.processInfo.environment["TFL_APP_KEY"]

    static func parse(_ args: [String]) throws -> Options {
        enum ParseError: Swift.Error, CustomStringConvertible {
            case missingValue(String)
            case invalidURL(String)
            case unknownFlag(String)

            var description: String {
                switch self {
                case .missingValue(let f): return "Missing value for \(f)"
                case .invalidURL(let u): return "Invalid URL: \(u)"
                case .unknownFlag(let f): return "Unknown flag: \(f)"
                }
            }
        }

        var o = Options()
        var i = 0
        while i < args.count {
            let a = args[i]
            switch a {
            case "--tunnel-name":
                guard i + 1 < args.count else { throw ParseError.missingValue(a) }
                o.tunnelName = args[i + 1]
                i += 2
            case "--json":
                o.json = true
                i += 1
            case "--quiet":
                o.quiet = true
                i += 1
            case "--base-url":
                guard i + 1 < args.count else { throw ParseError.missingValue(a) }
                guard let url = URL(string: args[i + 1]) else { throw ParseError.invalidURL(args[i + 1]) }
                o.baseURL = url
                i += 2
            case "--app-id":
                guard i + 1 < args.count else { throw ParseError.missingValue(a) }
                o.appId = args[i + 1]
                i += 2
            case "--app-key":
                guard i + 1 < args.count else { throw ParseError.missingValue(a) }
                o.appKey = args[i + 1]
                i += 2
            default:
                throw ParseError.unknownFlag(a)
            }
        }
        return o
    }
}
