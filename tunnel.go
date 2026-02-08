package main

import "strings"

// TunnelState represents the current state of a tunnel.
type TunnelState string

const (
	TunnelStateOpen    TunnelState = "open"
	TunnelStateClosed  TunnelState = "closed"
	TunnelStateUnknown TunnelState = "unknown"
)

// TunnelStatus is the resolved status of a tunnel.
// JSON field order is alphabetical to match the Swift Codable sortedKeys output.
type TunnelStatus struct {
	DisruptionIDs       []string    `json:"disruptionIds"`
	Severity            string      `json:"severity"`
	SeverityDescription string      `json:"severityDescription"`
	State               TunnelState `json:"state"`
	TunnelName          string      `json:"tunnelName"`
}

// TunnelStatusService resolves the current status of a tunnel from TfL disruptions.
type TunnelStatusService struct {
	Client *TfLClient
}

// NewTunnelStatusService creates a new service.
func NewTunnelStatusService(client *TfLClient) *TunnelStatusService {
	return &TunnelStatusService{Client: client}
}

// FetchTunnelStatus queries TfL and resolves the tunnel's open/closed state.
func (s *TunnelStatusService) FetchTunnelStatus(tunnelName string) (*TunnelStatus, error) {
	disruptions, err := s.Client.FetchRoadDisruptions()
	if err != nil {
		return nil, err
	}

	var matches []RoadDisruption
	for _, d := range disruptions {
		if Matches(d, tunnelName) {
			matches = append(matches, d)
		}
	}

	if len(matches) == 0 {
		return &TunnelStatus{
			TunnelName:          tunnelName,
			State:               TunnelStateOpen,
			Severity:            "None",
			SeverityDescription: "No active disruptions",
			DisruptionIDs:       []string{},
		}, nil
	}

	var closedMatch *RoadDisruption
	for i := range matches {
		if IsClosed(matches[i]) {
			closedMatch = &matches[i]
			break
		}
	}

	primary := &matches[0]
	state := TunnelStateOpen
	if closedMatch != nil {
		primary = closedMatch
		state = TunnelStateClosed
	}

	severity := "Unknown"
	if primary.Severity != nil {
		severity = *primary.Severity
	}

	description := "Active disruption"
	if primary.Comments != nil && *primary.Comments != "" {
		description = *primary.Comments
	} else if primary.Location != nil && *primary.Location != "" {
		description = *primary.Location
	}

	ids := make([]string, len(matches))
	for i, m := range matches {
		ids[i] = m.ID
	}

	return &TunnelStatus{
		TunnelName:          tunnelName,
		State:               state,
		Severity:            severity,
		SeverityDescription: description,
		DisruptionIDs:       ids,
	}, nil
}

// Matches returns true if the disruption mentions the query (case-insensitive substring).
func Matches(d RoadDisruption, query string) bool {
	q := strings.TrimSpace(query)
	if q == "" {
		return false
	}

	var parts []string
	if d.Location != nil {
		parts = append(parts, *d.Location)
	}
	if d.Comments != nil {
		parts = append(parts, *d.Comments)
	}
	haystack := strings.ToLower(strings.Join(parts, " "))
	return strings.Contains(haystack, strings.ToLower(q))
}

// IsClosed returns true if the disruption indicates a closure.
func IsClosed(d RoadDisruption) bool {
	if d.HasClosures != nil && *d.HasClosures {
		return true
	}
	for _, s := range d.Streets {
		if s.Closure != nil && strings.ToLower(*s.Closure) == "closed" {
			return true
		}
	}
	return false
}
