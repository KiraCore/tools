package cli

import (
	"errors"
	"fmt"

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
	hash := args[0]
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
	pin := pnt.PinataApi{}

	pin.SetKeys(keys)
	pin.SetData(hash)

	pin.Pinned(hash)

	// Unmarshal the response into a PinnedResponse struct.
	pinned, err := pin.OutputPinnedJsonObj()
	if err != nil {
		return err
	}

	// Check the count of pinned content with the given metadata name.
	switch pinned.Count {
	case 0:
		return fmt.Errorf(`not found. data with name %s doesn't exist`, hash)
	case 1:
		// Set the URL for unpinning by IPFS hash.
		unpin := pnt.PinataApi{}
		unpin.SetKeys(keys)

		if err := unpin.Unpin(pinned.Rows[0].CID); err != nil {
			log.Error("unable to unpin: %v", err)
			return err
		}
		err = unpin.OutputUnpinJson()
		if err != nil {
			log.Error("failed to print results")
			return err
		}

	default:
		return errors.New("more than one result returned")
	}

	return nil
}
