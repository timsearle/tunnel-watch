import SwiftUI
import TunnelWatchAppleSupport
import TunnelWatchCore
import WidgetKit

private struct Provider: TimelineProvider {
    private let helper = TunnelWatchWidgetProvider()

    func placeholder(in context: Context) -> TunnelWatchWidgetEntry {
        TunnelWatchWidgetEntry(
            date: Date(),
            snapshot: TunnelStatusSnapshot(
                tunnelName: "Rotherhithe Tunnel",
                state: .unknown,
                severityDescription: "Loading…",
                updatedAt: Date()
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TunnelWatchWidgetEntry) -> Void) {
        Task { completion(await helper.entry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TunnelWatchWidgetEntry>) -> Void) {
        Task {
            let entry = await helper.entry()
            let next = Calendar.current.date(byAdding: .minute, value: 5, to: entry.date) ?? entry.date.addingTimeInterval(300)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

private struct TunnelWatchWidgetView: View {
    let entry: TunnelWatchWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.06, green: 0.08, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.snapshot.tunnelName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(entry.snapshot.state.rawValue.uppercased())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(stateColor)
                    .minimumScaleFactor(0.8)

                Text(entry.snapshot.severityDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)

                Spacer(minLength: 0)

                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    }
            }
            .padding(12)
        }
        .containerBackground(.clear, for: .widget)
    }

    private var stateColor: Color {
        switch entry.snapshot.state {
        case .open: return .green.opacity(0.95)
        case .closed: return .red.opacity(0.95)
        case .unknown: return .white.opacity(0.85)
        }
    }
}

@main
struct TunnelWatchWidget: Widget {
    private let kind = "TunnelWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TunnelWatchWidgetView(entry: entry)
        }
        .configurationDisplayName("Rotherhithe Tunnel")
        .description("Shows whether the tunnel is open or closed.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
