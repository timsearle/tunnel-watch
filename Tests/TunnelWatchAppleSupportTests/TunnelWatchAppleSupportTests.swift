import XCTest
@testable import TunnelWatchAppleSupport
import TunnelWatchCore

final class TunnelWatchAppleSupportTests: XCTestCase {
    func testSnapshotMapping() throws {
        let status = TunnelStatus(
            tunnelName: "Rotherhithe Tunnel",
            state: .open,
            severity: "None",
            severityDescription: "No active disruptions",
            disruptionIds: []
        )

        let d = Date(timeIntervalSince1970: 123)
        let snap = TunnelStatusFetcher.snapshot(from: status, updatedAt: d)

        XCTAssertEqual(snap.tunnelName, "Rotherhithe Tunnel")
        XCTAssertEqual(snap.state, .open)
        XCTAssertEqual(snap.severityDescription, "No active disruptions")
        XCTAssertEqual(snap.updatedAt, d)
    }
}
