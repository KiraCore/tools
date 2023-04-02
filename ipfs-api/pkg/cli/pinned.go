package cli

import (
	"errors"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav2"

	"github.com/spf13/cobra"
)

var pinnedCommand = &cobra.Command{
	Use:   "pinned <CID-v0/v1/file-path/file-name/folder-name>",
	Short: "File/Folder check allowing to test if the file/folder is already pinned on IPFS or not",
	Long:  "File/Folder check allowing to test if the file/folder is already pinned on IPFS or not",
	Args:  cobra.MaximumNArgs(1),
	RunE:  pinned,
}

// pinned retrieves pinned content by its IPFS hash or metadata name using the Pinata API.
// This function returns an error if the pinned content cannot be retrieved or if the output operation fails.
//
// cmd: The command instance received by the function.
// args: A slice of string arguments provided to the command.
//
// Returns an error if any operation fails.
func pinned(cmd *cobra.Command, args []string) error {
	// Check if the arguments are empty.
	if len(args) == 0 {
		log.Error("pinned: empty arg")
		return errors.New("args can't be empty")
	}

	// Grab the API key.
	keys, err := pnt.GrabKey(key)
	if err != nil {
		return err
	}

	// Initialize a PinataApi instance and set the API keys.
	p := pnt.PinataApi{}
	p.SetKeys(keys)

	// Retrieve the pinned content by IPFS hash or metadata name.
	if err := p.Pinned(args[0]); err != nil {
		log.Error("Can't pin this")
		return err
	}

	// Output the pinned content as JSON.
	err = p.OutputPinnedJson()
	if err != nil {
		return err
	}

	return nil
}
