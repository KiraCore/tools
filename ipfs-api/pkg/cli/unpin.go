package cli

import (
	"errors"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
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
	if len(args) == 0 {
		log.Error("pinned: empty arg")
		return errors.New("args can't be empty")
	}
	keys, err := pnt.GrabKey(key)
	if err != nil {
		log.Error("failed to process keys")
		return err
	}

	p := pnt.PinataApi{}
	p.SetKeys(keys)
	p.SetData(args[0])
	if err := p.Unpin(args[0]); err != nil {
		log.Error("unable to unpin: %v", err)
		return err
	}
	err = p.OutputUnpinJson()
	if err != nil {
		log.Error("failed to print results")
		return err
	}

	return nil
}
