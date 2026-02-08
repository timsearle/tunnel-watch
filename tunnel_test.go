package main

import (
	"encoding/json"
	"testing"
)

func TestDisruptionDetectsClosedFromStreetClosure(t *testing.T) {
	raw := `[
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
	]`

	var disruptions []RoadDisruption
	if err := json.Unmarshal([]byte(raw), &disruptions); err != nil {
		t.Fatal(err)
	}

	if !IsClosed(disruptions[0]) {
		t.Error("expected disruption to be detected as closed")
	}
}

func TestDisruptionDetectsOpenWhenNoClosures(t *testing.T) {
	raw := `[
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
	]`

	var disruptions []RoadDisruption
	if err := json.Unmarshal([]byte(raw), &disruptions); err != nil {
		t.Fatal(err)
	}

	if IsClosed(disruptions[0]) {
		t.Error("expected disruption to NOT be detected as closed")
	}
}

func TestMatchesIgnoresCaseAndWhitespace(t *testing.T) {
	loc := "[A101] ROTHERHITHE TUNNEL"
	comments := "Maintenance works"
	d := RoadDisruption{
		ID:       "D1",
		Location: &loc,
		Comments: &comments,
	}

	if !Matches(d, "  rotherhithe tunnel  ") {
		t.Error("expected match with leading/trailing whitespace and different case")
	}

	if Matches(d, "") {
		t.Error("expected no match for empty query")
	}
}

func TestIsClosedFromHasClosuresFlag(t *testing.T) {
	closed := true
	d := RoadDisruption{
		ID:          "D1",
		HasClosures: &closed,
	}

	if !IsClosed(d) {
		t.Error("expected closed when hasClosures is true")
	}
}

func TestIsClosedFromStreetClosureField(t *testing.T) {
	closure := "Closed"
	d := RoadDisruption{
		ID: "D1",
		Streets: []Street{
			{Closure: &closure},
		},
	}

	if !IsClosed(d) {
		t.Error("expected closed when street closure is 'Closed'")
	}
}

func TestIsNotClosedWhenNoIndicators(t *testing.T) {
	notClosed := false
	openClosure := "Open"
	d := RoadDisruption{
		ID:          "D1",
		HasClosures: &notClosed,
		Streets: []Street{
			{Closure: &openClosure},
		},
	}

	if IsClosed(d) {
		t.Error("expected not closed")
	}
}

func TestTunnelStatusJSONFieldOrder(t *testing.T) {
	status := TunnelStatus{
		TunnelName:          "Rotherhithe Tunnel",
		State:               TunnelStateOpen,
		Severity:            "None",
		SeverityDescription: "No active disruptions",
		DisruptionIDs:       []string{},
	}

	data, err := json.Marshal(status)
	if err != nil {
		t.Fatal(err)
	}

	// Verify it round-trips correctly
	var decoded TunnelStatus
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatal(err)
	}

	if decoded.TunnelName != "Rotherhithe Tunnel" {
		t.Errorf("unexpected tunnelName: %s", decoded.TunnelName)
	}
	if decoded.State != TunnelStateOpen {
		t.Errorf("unexpected state: %s", decoded.State)
	}
}
