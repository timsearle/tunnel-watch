import ArgumentParser
import Foundation
import TunnelWatchCore

#if canImport(Darwin)
import Darwin
private nonisolated(unsafe) let _stderr = Darwin.stderr
#else
import Glibc
private nonisolated(unsafe) let _stderr = Glibc.stderr
#endif

@main
struct TunnelWatch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tunnel-watch",
        abstract: "Report whether the Rotherhithe Tunnel is open or closed (TfL).",
        version: Version.current,
        subcommands: [Status.self],
        defaultSubcommand: Status.self
    )

    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Check tunnel status via TfL road disruptions."
        )

        @Option(name: .customLong("tunnel-name"), help: "Tunnel name to match in TfL disruptions (case-insensitive substring match).")
        var tunnelName: String = "Rotherhithe Tunnel"

        @Flag(name: .customLong("json"), help: "Output JSON to stdout.")
        var json: Bool = false

        @Flag(name: .customLong("quiet"), help: "Print only OPEN/CLOSED/UNKNOWN (stdout).")
        var quiet: Bool = false

        @Option(name: .customLong("base-url"), help: "TfL API base URL.")
        var baseURLString: String = "https://api.tfl.gov.uk"

        @Option(name: .customLong("app-id"), help: "TfL app id (defaults to env TFL_APP_ID).")
        var appId: String = ProcessInfo.processInfo.environment["TFL_APP_ID"] ?? ""

        @Option(name: .customLong("app-key"), help: "TfL app key (defaults to env TFL_APP_KEY).")
        var appKey: String = ProcessInfo.processInfo.environment["TFL_APP_KEY"] ?? ""

        func run() async throws {
            do {
                guard let baseURL = URL(string: baseURLString) else {
                    throw ValidationError("Invalid --base-url: \(baseURLString)")
                }

                let client = TfLClient(
                    baseURL: baseURL,
                    appId: appId.isEmpty ? nil : appId,
                    appKey: appKey.isEmpty ? nil : appKey
                )
                let service = TunnelStatusService(client: client)
                let result = try await service.fetchTunnelStatus(tunnelName: tunnelName)

                if json {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let data = try encoder.encode(result)
                    FileHandle.standardOutput.write(data)
                    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
                } else if quiet {
                    print(result.state.rawValue.uppercased())
                } else {
                    print("\(result.tunnelName): \(result.state.rawValue.uppercased()) — \(result.severityDescription)")
                }

                switch result.state {
                case .open:
                    TunnelWatch.exitProcess(0)
                case .closed:
                    TunnelWatch.exitProcess(1)
                case .unknown:
                    TunnelWatch.exitProcess(3)
                }
            } catch {
                fputs("Error: \(error)\n", _stderr)
                TunnelWatch.exitProcess(2)
            }
        }
    }

    static func exitProcess(_ code: Int32) -> Never {
        #if canImport(Darwin)
        Darwin.exit(code)
        #else
        Glibc.exit(code)
        #endif
    }
}

private enum Version {
    static let current = "0.1.0"
}
