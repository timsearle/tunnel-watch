import Foundation
import TunnelWatchCore

public struct TunnelStatusSnapshot: Codable, Sendable, Equatable {
    public let tunnelName: String
    public let state: TunnelState
    public let severityDescription: String
    public let updatedAt: Date

    public init(tunnelName: String, state: TunnelState, severityDescription: String, updatedAt: Date) {
        self.tunnelName = tunnelName
        self.state = state
        self.severityDescription = severityDescription
        self.updatedAt = updatedAt
    }
}

public struct TunnelStatusFetcher: Sendable {
    public let service: TunnelStatusService
    public let now: @Sendable () -> Date

    public init(service: TunnelStatusService = TunnelStatusService(), now: @escaping @Sendable () -> Date = Date.init) {
        self.service = service
        self.now = now
    }

    public func fetchSnapshot(tunnelName: String = "Rotherhithe Tunnel") async throws -> TunnelStatusSnapshot {
        let status = try await service.fetchTunnelStatus(tunnelName: tunnelName)
        return TunnelStatusSnapshot(
            tunnelName: status.tunnelName,
            state: status.state,
            severityDescription: status.severityDescription,
            updatedAt: now()
        )
    }

    public static func snapshot(from status: TunnelStatus, updatedAt: Date) -> TunnelStatusSnapshot {
        TunnelStatusSnapshot(
            tunnelName: status.tunnelName,
            state: status.state,
            severityDescription: status.severityDescription,
            updatedAt: updatedAt
        )
    }
}

#if canImport(SwiftUI)
import SwiftUI

public struct TunnelStatusSimpleView: View {
    public let snapshot: TunnelStatusSnapshot

    public init(snapshot: TunnelStatusSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snapshot.tunnelName)
                .font(.headline)

            Text(snapshot.state.rawValue.uppercased())
                .font(.title)
                .fontWeight(.bold)

            Text(snapshot.severityDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(snapshot.updatedAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
#endif

#if canImport(CarPlay)
import CarPlay

public enum TunnelWatchCarPlay {
    public static func makeStatusTemplate(snapshot: TunnelStatusSnapshot) -> CPListTemplate {
        let item = CPListItem(
            text: snapshot.tunnelName,
            detailText: "\(snapshot.state.rawValue.uppercased()) — \(snapshot.severityDescription)"
        )

        let section = CPListSection(items: [item])
        let template = CPListTemplate(title: "Tunnel", sections: [section])
        return template
    }
}
#endif

#if canImport(WidgetKit)
import WidgetKit

public struct TunnelWatchWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: TunnelStatusSnapshot

    public init(date: Date, snapshot: TunnelStatusSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

public struct TunnelWatchWidgetProvider {
    public let fetcher: TunnelStatusFetcher

    public init(fetcher: TunnelStatusFetcher = TunnelStatusFetcher()) {
        self.fetcher = fetcher
    }

    public func entry(tunnelName: String = "Rotherhithe Tunnel") async -> TunnelWatchWidgetEntry {
        do {
            let snap = try await fetcher.fetchSnapshot(tunnelName: tunnelName)
            return TunnelWatchWidgetEntry(date: snap.updatedAt, snapshot: snap)
        } catch {
            let snap = TunnelStatusSnapshot(
                tunnelName: tunnelName,
                state: .unknown,
                severityDescription: String(describing: error),
                updatedAt: Date()
            )
            return TunnelWatchWidgetEntry(date: snap.updatedAt, snapshot: snap)
        }
    }
}
#endif
