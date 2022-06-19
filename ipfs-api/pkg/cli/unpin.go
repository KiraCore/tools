package cli

import (
	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav1"
	"github.com/spf13/cobra"
)

var unpinCommand = &cobra.Command{
	Use:   "delete <CID-v0/v1/file-name/folder-root> --key=<file-path/string>",
	Short: "File/folder unpin & delete",
	Long:  "File/folder unpin & delete",
	RunE:  unpin,
}

func unpin(cmd *cobra.Command, args []string) error {
	keys, _ := grabKey(key)
	if err := pnt.Unpin(args, keys); err != nil {
		return err
	}
	return nil

}
