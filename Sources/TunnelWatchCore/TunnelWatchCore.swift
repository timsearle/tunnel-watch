import Foundation

public enum TunnelState: String, Codable, Sendable {
    case open
    case closed
    case unknown
}

public struct TunnelStatus: Codable, Sendable {
    public let tunnelName: String
    public let state: TunnelState
    public let severity: String
    public let severityDescription: String
    public let disruptionIds: [String]

    public init(
        tunnelName: String,
        state: TunnelState,
        severity: String,
        severityDescription: String,
        disruptionIds: [String]
    ) {
        self.tunnelName = tunnelName
        self.state = state
        self.severity = severity
        self.severityDescription = severityDescription
        self.disruptionIds = disruptionIds
    }
}

public struct TfLClient: Sendable {
    public struct RoadStatus: Codable, Sendable {
        public let id: String
        public let displayName: String
        public let statusSeverity: String
        public let statusSeverityDescription: String
    }

    public struct RoadDisruption: Codable, Sendable {
        public struct Street: Codable, Sendable {
            public let name: String?
            public let closure: String?
            public let directions: String?
        }

        public let id: String
        public let severity: String?
        public let status: String?
        public let category: String?
        public let subCategory: String?
        public let location: String?
        public let comments: String?
        public let hasClosures: Bool?
        public let streets: [Street]?
    }

    public let baseURL: URL
    public let appId: String?
    public let appKey: String?

    public init(baseURL: URL = URL(string: "https://api.tfl.gov.uk")!, appId: String? = nil, appKey: String? = nil) {
        self.baseURL = baseURL
        self.appId = appId
        self.appKey = appKey
    }

    public func fetchRoadStatuses(ids: [String]) async throws -> [RoadStatus] {
        guard !ids.isEmpty else { return [] }

        var components = URLComponents(
            url: baseURL.appending(path: "Road/\(ids.joined(separator: ","))"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = authQueryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        return try await fetch(url: url, as: [RoadStatus].self)
    }

    public func fetchRoadDisruptions() async throws -> [RoadDisruption] {
        var components = URLComponents(
            url: baseURL.appending(path: "Road/all/Disruption"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = authQueryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        return try await fetch(url: url, as: [RoadDisruption].self)
    }

    private var authQueryItems: [URLQueryItem]? {
        var queryItems: [URLQueryItem] = []
        if let appId, !appId.isEmpty {
            queryItems.append(URLQueryItem(name: "app_id", value: appId))
        }
        if let appKey, !appKey.isEmpty {
            queryItems.append(URLQueryItem(name: "app_key", value: appKey))
        }
        return queryItems.isEmpty ? nil : queryItems
    }

    private func fetch<T: Decodable>(url: URL, as: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            throw TfLError.httpStatus(http.statusCode, body: String(data: data, encoding: .utf8))
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    public enum TfLError: Swift.Error, CustomStringConvertible {
        case httpStatus(Int, body: String?)

        public var description: String {
            switch self {
            case .httpStatus(let code, let body):
                if let body, !body.isEmpty {
                    return "TfL API returned HTTP \(code): \(body)"
                }
                return "TfL API returned HTTP \(code)"
            }
        }
    }
}

public struct TunnelStatusService: Sendable {
    public let client: TfLClient

    public init(client: TfLClient = TfLClient()) {
        self.client = client
    }

    public func fetchTunnelStatus(tunnelName: String = "Rotherhithe Tunnel") async throws -> TunnelStatus {
        let disruptions = try await client.fetchRoadDisruptions()
        let matches = disruptions.filter { TunnelStatusService.matches($0, query: tunnelName) }

        guard !matches.isEmpty else {
            return TunnelStatus(
                tunnelName: tunnelName,
                state: .open,
                severity: "None",
                severityDescription: "No active disruptions",
                disruptionIds: []
            )
        }

        let closedMatch = matches.first { TunnelStatusService.isClosed($0) }
        let primary = closedMatch ?? matches[0]

        return TunnelStatus(
            tunnelName: tunnelName,
            state: closedMatch == nil ? .open : .closed,
            severity: primary.severity ?? "Unknown",
            severityDescription: primary.comments ?? primary.location ?? "Active disruption",
            disruptionIds: matches.map { $0.id }
        )
    }

    public static func matches(_ disruption: TfLClient.RoadDisruption, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return false }

        let haystack = [disruption.location, disruption.comments]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        return haystack.contains(q.lowercased())
    }

    public static func isClosed(_ disruption: TfLClient.RoadDisruption) -> Bool {
        if disruption.hasClosures == true { return true }
        if (disruption.streets ?? []).contains(where: { ($0.closure ?? "").lowercased() == "closed" }) { return true }
        return false
    }

    public static func classify(_ status: TfLClient.RoadStatus) -> TunnelState {
        let sev = status.statusSeverity.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let desc = status.statusSeverityDescription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if sev.contains("closed") || sev.contains("closure") || desc.contains("closed") {
            return .closed
        }

        if sev.isEmpty && desc.isEmpty {
            return .unknown
        }

        return .open
    }
}
