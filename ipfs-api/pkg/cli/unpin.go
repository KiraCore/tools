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

// unpin is a function that handles the unpin command with the provided arguments.
// This function unpin content from IPFS using the Pinata API.
//
// cmd: The cobra command instance.
// args: The arguments passed to the unpin command.
//
// Returns an error if the unpin operation fails or the arguments are empty.
func unpin(cmd *cobra.Command, args []string) error {
	// Check if the arguments are empty.
	if len(args) == 0 {
		log.Error("unpin: empty arg")
		return errors.New("args can't be empty")
	}

	// Get the keys and initialize the PinataApi instance.
	keys, err := pnt.GrabKey(key)
	if err != nil {
		log.Error("failed to process keys")
		return err
	}

	// Set up the PinataApi instance with the obtained keys and the provided argument.
	p := pnt.PinataApi{}
	p.SetKeys(keys)
	p.SetData(args[0])

	// Unpin the content using the Pinata API.
	if err := p.Unpin(args[0]); err != nil {
		log.Error("unable to unpin: %v", err)
		return err
	}

	// Output the result of the unpin operation.
	err = p.OutputUnpinJson()
	if err != nil {
		log.Error("failed to print results")
		return err
	}

	return nil
}
