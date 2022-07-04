package cli

import (
	"errors"
	"os"

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

func pinCmd(cmd *cobra.Command, args []string) error {
	if overwrite && force {
		log.Error("pinCmd: conflict: only one flag can be set")
		return errors.New("conflict: only one flag can be set")
	}

	keys, err := pnt.GrabKey(key)
	if err != nil {
		log.Error("grabKey: failed to get keys: %v", err)
		return err
	}
	p := pnt.PinataApi{}
	p.SetKeys(keys)

	switch len(args) {
	case 1:
		if force {
			log.Error("pinCmd: can't force if metadata is not provided")
			return errors.New("can't force if metadata is not provided")
		}
		if len(meta) > 0 {
			m, err := pnt.StrToMeta(meta)
			if err != nil {
				return err
			}
			p.SetMetaData(m)
		}

		err := p.Pin(args[0])
		if err != nil {
			log.Error("pin failed %v", err)
			return err
		}
		if err := p.OutputPinJson(); err != nil {
			log.Error("failed to print results: %v", err)
			os.Exit(1)
		}

	case 2:
		switch force {
		case false:
			switch overwrite {
			case false:
				if err := p.SetMetaName(args[1]); err != nil {
					log.Error("failed to add metadata %v", err)
					return err
				}
				if len(meta) > 0 {
					m, err := pnt.StrToMeta(meta)
					if err != nil {
						return err
					}
					p.SetMetaData(m)
				}
				err := p.Pin(args[0])
				if err != nil {
					log.Error("pin failed %v", err)
					return err
				}
				if err := p.OutputPinJson(); err != nil {
					log.Error("failed to print results: %v", err)
					os.Exit(1)
				}
			case true:
				if err := p.SetMetaName(args[1]); err != nil {
					p.Unpin(args[1])
				}
				if err := p.SetMetaName(args[1]); err != nil {
					log.Error("failed to add metadata %v", err)
					return err
				}
				if len(meta) > 0 {
					m, err := pnt.StrToMeta(meta)
					if err != nil {
						return err
					}
					p.SetMetaData(m)
				}

				err := p.Pin(args[0])
				if err != nil {
					log.Error("pin failed %v", err)
					return err
				}

			}
		case true:
			if len(meta) > 0 {
				m, err := pnt.StrToMeta(meta)
				if err != nil {
					return err
				}
				p.SetMetaData(m)
			}
			err := p.Pin(args[0])
			if err != nil {
				log.Error("pin failed %v", err)
				return err
			}
			o, err := p.OutputPinJsonObj()
			if err != nil {
				return err
			}
			if o.Duplicate {
				err := p.SetMeta(o.IpfsHash, args[1])
				if err != nil {
					return err
				}
			}

		}

	}
	return nil
}
