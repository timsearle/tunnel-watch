//
//  TunnelWatchTests.swift
//  TunnelWatchTests
//
//  Created by Tim Searle on 01/01/2026.
//

import Foundation
import Testing
import TunnelWatchAppleSupport
import TunnelWatchCore

@testable import TunnelWatch

private struct StubProvider: TunnelStatusProviding {
    let result: Result<TunnelStatusSnapshot, Error>

    func fetchSnapshot() async throws -> TunnelStatusSnapshot {
        try result.get()
    }
}

private struct TestError: Error, CustomStringConvertible {
    let description: String
}

struct TunnelWatchTests {
    @Test
    func viewModel_refresh_success_updatesSnapshot() async {
        let snapshot = TunnelStatusSnapshot(
            tunnelName: "Rotherhithe Tunnel",
            state: .open,
            severityDescription: "No active disruptions",
            updatedAt: Date(timeIntervalSince1970: 123)
        )

        let provider = StubProvider(result: .success(snapshot))
        let model = await MainActor.run { TunnelStatusViewModel(provider: provider) }

        await model.refresh()

        let (current, refreshing) = await MainActor.run { (model.snapshot, model.isRefreshing) }
        #expect(current == snapshot)
        #expect(refreshing == false)
    }

    @Test
    func viewModel_refresh_failure_setsUnknown() async {
        let provider = StubProvider(result: .failure(TestError(description: "boom")))
        let model = await MainActor.run { TunnelStatusViewModel(provider: provider) }

        await model.refresh()

        let current = await MainActor.run { model.snapshot }
        #expect(current.state == .unknown)
        #expect(current.severityDescription.contains("boom"))
    }

    @Test
    func appInfoPlist_declaresCarPlayScene() throws {
        let xcodeDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let infoURL = xcodeDir.appendingPathComponent("Config/Info.plist")
        let dict = try loadPlist(at: infoURL)

        let manifest = dict["UIApplicationSceneManifest"] as? [String: Any]
        #expect(manifest != nil)

        let configs = (manifest?["UISceneConfigurations"] as? [String: Any])
        let carplay = configs?["CPTemplateApplicationSceneSessionRoleApplication"] as? [[String: Any]]

        #expect(carplay?.isEmpty == false)
        #expect(carplay?.first?["UISceneClassName"] as? String == "CPTemplateApplicationScene")
    }

    @Test
    func widgetInfoPlist_declaresWidgetExtensionPoint() throws {
        let xcodeDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let infoURL = xcodeDir.appendingPathComponent("Config/TunnelWatchWidget-Info.plist")
        let dict = try loadPlist(at: infoURL)

        let ext = dict["NSExtension"] as? [String: Any]
        #expect(ext?["NSExtensionPointIdentifier"] as? String == "com.apple.widgetkit-extension")
    }
}

private func loadPlist(at url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    let obj = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    guard let dict = obj as? [String: Any] else {
        throw CocoaError(.fileReadCorruptFile)
    }
    return dict
}
