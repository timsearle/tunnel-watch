import XCTest
@testable import TunnelWatchCore

final class TunnelWatchCoreTests: XCTestCase {
    func testClassifyClosed() throws {
        let json = #"""
        [
          {
            "id": "rotherhithe-tunnel",
            "displayName": "Rotherhithe Tunnel",
            "statusSeverity": "Closure",
            "statusSeverityDescription": "Road Closed"
          }
        ]
        """#

        let statuses = try JSONDecoder().decode([TfLClient.RoadStatus].self, from: Data(json.utf8))
        XCTAssertEqual(TunnelStatusService.classify(statuses[0]), .closed)
    }

    func testClassifyOpen() throws {
        let json = #"""
        [
          {
            "id": "rotherhithe-tunnel",
            "displayName": "Rotherhithe Tunnel",
            "statusSeverity": "Good",
            "statusSeverityDescription": "No Exceptional Delays"
          }
        ]
        """#

        let statuses = try JSONDecoder().decode([TfLClient.RoadStatus].self, from: Data(json.utf8))
        XCTAssertEqual(TunnelStatusService.classify(statuses[0]), .open)
    }

    func testDisruptionDetectsClosedFromStreetClosure() throws {
        let json = #"""
        [
          {
            "id": "TIMS-123",
            "severity": "Severe",
            "status": "Active",
            "location": "[A101] ROTHERHITHE TUNNEL",
            "comments": "Rotherhithe Tunnel closed",
            "hasClosures": true,
            "streets": [
              { "name": "[A101] ROTHERHITHE TUNNEL", "closure": "Closed", "directions": "Both directions" }
            ]
          }
        ]
        """#

        let disruptions = try JSONDecoder().decode([TfLClient.RoadDisruption].self, from: Data(json.utf8))
        XCTAssertTrue(TunnelStatusService.isClosed(disruptions[0]))
    }

    func testDisruptionDetectsOpenWhenNoClosures() throws {
        let json = #"""
        [
          {
            "id": "TIMS-456",
            "severity": "Moderate",
            "status": "Active",
            "location": "[A101] ROTHERHITHE TUNNEL",
            "comments": "The Tunnel may be subject to short, intermittent closures",
            "hasClosures": false,
            "streets": [
              { "name": "[A101] ROTHERHITHE TUNNEL", "closure": "Open", "directions": "Both directions" }
            ]
          }
        ]
        """#

        let disruptions = try JSONDecoder().decode([TfLClient.RoadDisruption].self, from: Data(json.utf8))
        XCTAssertFalse(TunnelStatusService.isClosed(disruptions[0]))
    }
}
