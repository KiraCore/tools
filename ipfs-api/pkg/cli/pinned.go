package cli

import (
	"github.com/kiracore/tools/ipfs-api/pkg/pinatav1"
	"github.com/spf13/cobra"
)

var pinnedCommand = &cobra.Command{
	Use:   "pinned <CID-v0/v1/file-path/file-name/folder-name>",
	Short: "File/Folder check allowing to test if the file/folder is already pinned on IPFS or not",
	Long:  "File/Folder check allowing to test if the file/folder is already pinned on IPFS or not",
	RunE:  pinned,
}

func pinned(cmd *cobra.Command, args []string) error {
	keys, _ := grabKey(key)
	pinatav1.Pinned(args, keys)
	return nil
}
