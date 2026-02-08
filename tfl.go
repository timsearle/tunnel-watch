package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

// RoadDisruption represents a single TfL road disruption.
type RoadDisruption struct {
	ID          string   `json:"id"`
	Severity    *string  `json:"severity"`
	Status      *string  `json:"status"`
	Category    *string  `json:"category"`
	SubCategory *string  `json:"subCategory"`
	Location    *string  `json:"location"`
	Comments    *string  `json:"comments"`
	HasClosures *bool    `json:"hasClosures"`
	Streets     []Street `json:"streets"`
}

// Street represents a street within a disruption.
type Street struct {
	Name       *string `json:"name"`
	Closure    *string `json:"closure"`
	Directions *string `json:"directions"`
}

// TfLClient communicates with the TfL Road API.
type TfLClient struct {
	BaseURL    string
	AppID      string
	AppKey     string
	HTTPClient *http.Client
}

// NewTfLClient creates a client for the TfL API.
func NewTfLClient(baseURL, appID, appKey string) *TfLClient {
	return &TfLClient{
		BaseURL: baseURL,
		AppID:   appID,
		AppKey:  appKey,
		HTTPClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// FetchRoadDisruptions retrieves all current road disruptions.
func (c *TfLClient) FetchRoadDisruptions() ([]RoadDisruption, error) {
	u, err := url.Parse(c.BaseURL + "/Road/all/Disruption")
	if err != nil {
		return nil, fmt.Errorf("invalid base URL: %w", err)
	}

	q := u.Query()
	if c.AppID != "" {
		q.Set("app_id", c.AppID)
	}
	if c.AppKey != "" {
		q.Set("app_key", c.AppKey)
	}
	u.RawQuery = q.Encode()

	req, err := http.NewRequest("GET", u.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("creating request: %w", err)
	}
	req.Header.Set("User-Agent", "tunnel-watch/"+version)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("TfL API request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("reading response: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return nil, fmt.Errorf("TfL API returned HTTP %d: %s", resp.StatusCode, string(body))
	}

	var disruptions []RoadDisruption
	if err := json.Unmarshal(body, &disruptions); err != nil {
		return nil, fmt.Errorf("decoding response: %w", err)
	}
	return disruptions, nil
}
