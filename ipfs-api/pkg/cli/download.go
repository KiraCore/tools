package cli

import (
	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav1"
	"github.com/spf13/cobra"
)

var downloadCommand = &cobra.Command{
	Use:   "download <CID-v0/v1> <file-path> --gateway=<url>",
	Short: "File/Folder download",
	Long:  "File/Folder download",
	RunE:  cmdDownload,
}

func cmdDownload(cmd *cobra.Command, args []string) error {
	keys, _ := grabKey(key)
	pnt.Download(args, keys, gateway)

	return nil
}
