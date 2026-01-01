import CarPlay
import Foundation
import TunnelWatchAppleSupport
import TunnelWatchCore

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private let fetcher = TunnelStatusFetcher()
    private var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        let placeholder = TunnelStatusSnapshot(
            tunnelName: "Rotherhithe Tunnel",
            state: .unknown,
            severityDescription: "Loading…",
            updatedAt: Date()
        )

        let template = makeTemplate(snapshot: placeholder)
        Task { try? await interfaceController.setRootTemplate(template, animated: false) }

        Task { await refresh(animated: true) }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    @MainActor
    private func refresh(animated: Bool) async {
        guard let interfaceController else { return }

        let snapshot: TunnelStatusSnapshot
        do {
            snapshot = try await fetcher.fetchSnapshot()
        } catch {
            snapshot = TunnelStatusSnapshot(
                tunnelName: "Rotherhithe Tunnel",
                state: .unknown,
                severityDescription: String(describing: error),
                updatedAt: Date()
            )
        }

        try? await interfaceController.setRootTemplate(makeTemplate(snapshot: snapshot), animated: animated)
    }

    private func makeTemplate(snapshot: TunnelStatusSnapshot) -> CPListTemplate {
        let template = TunnelWatchCarPlay.makeStatusTemplate(snapshot: snapshot)

        template.trailingNavigationBarButtons = [
            CPBarButton(type: .text) { [weak self] _ in
                Task { await self?.refresh(animated: true) }
            }
        ]
        template.trailingNavigationBarButtons.first?.title = "Refresh"

        return template
    }
}
