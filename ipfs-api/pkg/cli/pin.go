package cli

import (
	"errors"

	"github.com/ipld/go-ipld-prime/datamodel"
	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav2"
	"github.com/spf13/cobra"
)

func matchAll(checks ...cobra.PositionalArgs) cobra.PositionalArgs {
	return func(cmd *cobra.Command, args []string) error {
		for _, check := range checks {
			if err := check(cmd, args); err != nil {
				return err
			}
		}
		return nil
	}
}

var pinCommand = &cobra.Command{
	Use:   "pin <file/folder-path> <file/folder-name> --key=<file-path/string>",
	Short: "File/folder upload and pin",
	Long:  "File/folder upload and pin",
	Args:  matchAll(cobra.MinimumNArgs(1), cobra.MaximumNArgs(2)),
	RunE:  pinCmd,
}

// pinCmd is a function that handles the pin command with the provided flags and arguments.
// This function handles pinning content to IPFS using the Pinata API and managing metadata.
//
// cmd: The cobra command instance.
// args: The arguments passed to the pin command.
//
// Returns an error if any operation fails.
func pinCmd(cmd *cobra.Command, args []string) error {
	// Check if both overwrite and force flags are set, which is a conflict.
	if overwrite && force {
		log.Error("pinCmd: conflict: only one flag can be set")
		return errors.New("conflict: only one flag can be set")
	}

	// Get the keys and initialize the PinataApi instance.
	keys, err := pnt.GrabKey(key)
	if err != nil {
		log.Error("grabKey: failed to get keys: %v", err)
		return err
	}
	p := pnt.PinataApi{}
	p.SetKeys(keys)

	// Set metadata if provided.
	if len(meta) > 0 {
		m, err := pnt.StrToMeta(meta)
		if err != nil {
			return err
		}
		p.SetMetaData(m)
	}

	switch len(args) {
	case 1:
		// Assign args[0] to descriptive variable names
		content := args[0]
		if force {
			log.Error("pinCmd: can't force if metadata is not provided")
			return errors.New("can't force if metadata is not provided")
		}

		// Pin the content and output the result.
		err := pinAndOutputResult(&p, content)
		if err != nil {
			return err
		}

	case 2:
		// Assign args[0] and args[1] to descriptive variable names
		content := args[0]
		name := args[1]
		// Set the name metadata.
		if err := p.SetMetaName(name); err != nil {
			log.Error("failed to add metadata %v", err)
			return err
		}

		switch {
		case force:
			// Pin the content, check for duplicates, and update metadata if necessary.
			err = pinAndForce(&p, content, name)

		case overwrite:
			// Unpin previous content, pin the new content, and update metadata.
			err = pinAndOverwrite(&p, content, name)

		default:
			// Pin the content and output the result.
			err = pinAndOutputResult(&p, content)
		}
	}

	return err
}

// pinAndOutputResult pins the content and outputs the result.
func pinAndOutputResult(p *pnt.PinataApi, content string) error {
	err := p.Pin(content)
	if err != nil {
		log.Error("pin failed %v", err)
		return err
	}
	if err := p.OutputPinJson(); err != nil {
		log.Error("failed to print results: %v", err)
		return err
	}
	return nil
}

// pinAndForce pins the content, checks for duplicates, and updates metadata if necessary.
func pinAndForce(p *pnt.PinataApi, content string, name string) error {
	err := p.Pin(content)
	if err != nil {
		log.Error("pin failed %v", err)
		return err
	}
	o, err := p.OutputPinJsonObj()
	if err != nil {
		return err
	}
	if o.Duplicate {
		err := p.SetMeta(o.IpfsHash, name)
		if err != nil {
			return err
		}
	}
	return nil
}

// pinAndOverwrite unpins previous content, pins the new content, and updates metadata.
func pinAndOverwrite(p *pnt.PinataApi, content string, name string) error {
	var cid datamodel.Link
	if err := getCID(content, &cid); err != nil {
		return err
	}
	// Unpin the previous content.
	if err := p.Unpin(cid.String()); err != nil {
		log.Error("failed to unpin previous content: %v", err)
		return err
	}

	// Pin the new content.
	err := p.Pin(content)
	if err != nil {
		log.Error("pin failed %v", err)
		return err
	}

	// Update metadata.
	o, err := p.OutputPinJsonObj()
	if err != nil {
		return err
	}
	err = p.SetMeta(o.IpfsHash, name)
	if err != nil {
		log.Error("failed to update metadata: %v", err)
		return err
	}

	return nil
}
