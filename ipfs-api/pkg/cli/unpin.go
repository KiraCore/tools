package cli

import (
	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav2"
	"github.com/spf13/cobra"
)

var unpinCommand = &cobra.Command{
	Use:   "delete <CID-v0/v1/file-name/folder-root> --key=<file-path/string>",
	Short: "File/folder unpin & delete",
	Long:  "File/folder unpin & delete",
	Args:  cobra.MaximumNArgs(1),
	RunE:  unpin,
}

func unpin(cmd *cobra.Command, args []string) error {
	keys, _ := pnt.GrabKey(key)
	p := pnt.PinataApi{}
	p.SetKeys(keys)
	err := p.Unpin(args[0])
	if err != nil {
		return err
	}
	p.OutputUnpinJson()
	return nil

}
