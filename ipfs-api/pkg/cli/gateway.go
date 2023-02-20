package cli

import (
	"fmt"

	"github.com/spf13/cobra"
)

const (
	source = ""
)

var gateway struct {
}

var gatewayCommand = &cobra.Command{

	// Add check hash
	// Add check gateway status
	// Add sort
	// Add ping/speed (upd, dwn)

	Use:   "gateway",
	Short: "Gateways info",
	Long:  "Fetch, check information from gateway",
	RunE:  gatewayCmd,
}

func gatewayCmd() {
	fmt.Println("Gateways here")
}
