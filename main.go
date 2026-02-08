package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var version = "0.1.0"

var (
	tunnelName string
	jsonOutput bool
	quiet      bool
	baseURL    string
	appID      string
	appKey     string
)

func main() {
	rootCmd := newRootCmd()
	if err := rootCmd.Execute(); err != nil {
		os.Exit(2)
	}
}

func newRootCmd() *cobra.Command {
	root := &cobra.Command{
		Use:     "tunnel-watch",
		Short:   "Report whether the Rotherhithe Tunnel is open or closed (TfL).",
		Version: version,
		RunE:    runStatus,
	}

	root.PersistentFlags().StringVar(&tunnelName, "tunnel-name", "Rotherhithe Tunnel",
		"Tunnel name to match in TfL disruptions (case-insensitive substring match)")
	root.PersistentFlags().BoolVar(&jsonOutput, "json", false,
		"Output JSON to stdout")
	root.PersistentFlags().BoolVar(&quiet, "quiet", false,
		"Print only OPEN/CLOSED/UNKNOWN (stdout)")
	root.PersistentFlags().StringVar(&baseURL, "base-url", "https://api.tfl.gov.uk",
		"TfL API base URL")
	root.PersistentFlags().StringVar(&appID, "app-id", envOrDefault("TFL_APP_ID", ""),
		"TfL app id (defaults to env TFL_APP_ID)")
	root.PersistentFlags().StringVar(&appKey, "app-key", envOrDefault("TFL_APP_KEY", ""),
		"TfL app key (defaults to env TFL_APP_KEY)")

	status := &cobra.Command{
		Use:   "status",
		Short: "Check tunnel status via TfL road disruptions.",
		RunE:  runStatus,
	}

	root.AddCommand(status)
	return root
}

func envOrDefault(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return fallback
}

func runStatus(cmd *cobra.Command, _ []string) error {
	client := NewTfLClient(baseURL, appID, appKey)
	service := NewTunnelStatusService(client)

	result, err := service.FetchTunnelStatus(tunnelName)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(2)
	}

	if jsonOutput {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		if err := enc.Encode(result); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(2)
		}
	} else if quiet {
		fmt.Println(upper(string(result.State)))
	} else {
		fmt.Printf("%s: %s — %s\n", result.TunnelName, upper(string(result.State)), result.SeverityDescription)
	}

	switch result.State {
	case TunnelStateOpen:
		os.Exit(0)
	case TunnelStateClosed:
		os.Exit(1)
	case TunnelStateUnknown:
		os.Exit(3)
	default:
		fmt.Fprintf(os.Stderr, "Error: unexpected tunnel state: %s\n", result.State)
		os.Exit(2)
	}
	return nil
}

func upper(s string) string {
	result := make([]byte, len(s))
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c >= 'a' && c <= 'z' {
			c -= 'a' - 'A'
		}
		result[i] = c
	}
	return string(result)
}
