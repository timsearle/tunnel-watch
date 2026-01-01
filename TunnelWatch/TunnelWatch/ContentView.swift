//
//  ContentView.swift
//  TunnelWatch
//
//  Created by Tim Searle on 01/01/2026.
//

import SwiftUI
import TunnelWatchAppleSupport
import TunnelWatchCore

struct ContentView: View {
    @StateObject private var model = TunnelStatusViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.06, green: 0.08, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                TunnelStatusCard(snapshot: model.snapshot, isRefreshing: model.isRefreshing)

                Button {
                    Task { await model.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.18))

                Text("Updated \(model.snapshot.updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(20)
        }
        .task {
            await model.refresh()
        }
    }
}

private struct TunnelStatusCard: View {
    let snapshot: TunnelStatusSnapshot
    let isRefreshing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(snapshot.tunnelName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                if isRefreshing {
                    ProgressView()
                        .tint(.white.opacity(0.85))
                }
            }

            Text(snapshot.state.rawValue.uppercased())
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(stateColor)

            Text(snapshot.severityDescription)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.35), radius: 28, y: 18)
        }
    }

    private var stateColor: Color {
        switch snapshot.state {
        case .open: return Color.green.opacity(0.95)
        case .closed: return Color.red.opacity(0.95)
        case .unknown: return Color.white.opacity(0.85)
        }
    }
}

#Preview {
    ContentView()
}
