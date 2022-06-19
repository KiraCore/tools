package cli

import (
	"fmt"

	tp "github.com/kiracore/tools/ipfs-api/types"
	"github.com/spf13/cobra"
)

var versionCommand = &cobra.Command{
	Use:   "version",
	Short: "Get IPFS API version",
	Long:  "Get IPFS API version",
	RunE:  cmdVersion,
}

func cmdVersion(cmd *cobra.Command, args []string) error {
	fmt.Println(tp.IpfsApiVersion)

	return nil
}
