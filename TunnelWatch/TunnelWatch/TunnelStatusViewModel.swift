import Combine
import Foundation
import TunnelWatchAppleSupport
import TunnelWatchCore

protocol TunnelStatusProviding: Sendable {
    func fetchSnapshot() async throws -> TunnelStatusSnapshot
}

struct LiveTunnelStatusProvider: TunnelStatusProviding {
    let fetcher: TunnelStatusFetcher

    init(fetcher: TunnelStatusFetcher = TunnelStatusFetcher()) {
        self.fetcher = fetcher
    }

    func fetchSnapshot() async throws -> TunnelStatusSnapshot {
        try await fetcher.fetchSnapshot()
    }
}

@MainActor
final class TunnelStatusViewModel: ObservableObject {
    @Published private(set) var snapshot: TunnelStatusSnapshot
    @Published private(set) var isRefreshing: Bool = false

    private let provider: TunnelStatusProviding

    convenience init() {
        self.init(provider: LiveTunnelStatusProvider())
    }

    init(provider: TunnelStatusProviding) {
        self.provider = provider
        self.snapshot = TunnelStatusSnapshot(
            tunnelName: "Rotherhithe Tunnel",
            state: .unknown,
            severityDescription: "Loading…",
            updatedAt: Date()
        )
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            snapshot = try await provider.fetchSnapshot()
        } catch {
            snapshot = TunnelStatusSnapshot(
                tunnelName: snapshot.tunnelName,
                state: .unknown,
                severityDescription: String(describing: error),
                updatedAt: Date()
            )
        }
    }
}
