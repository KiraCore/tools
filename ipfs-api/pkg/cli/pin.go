package cli

import (
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

// func pinCmd(cmd *cobra.Command, args []string) error {
// 	if c != 1 && c != 0 {
// 		log.Fatalln("CID version value should be 0 or 1")
// 	}
// 	keys, _ := grabKey(key)
// 	tp.Opts = tp.PinataOptions{CidVersion: c, WrapWithDirectory: wd}
// 	if err := pnt.Pin(args, keys); err != nil {
// 		log.Fatalln("\033[31m", err)
// 		os.Exit(1)
// 	}
// 	return nil
// }
// func checkName(cmd *cobra.Command, args []string) error {
// 	keys, _ := grabKey(key)
// 	pnt.GetHashByName(args, keys)
// 	return nil
// }
func pinCmd(cmd *cobra.Command, args []string) error {
	keys, err := pnt.GrabKey(key)
	if err != nil {
		log.Error("grabKey: failed to get keys: %v", err)
		return err
	}
	p := pnt.PinataApi{}
	p.SetKeys(keys)

	switch len(args) {
	case 1:
		{
			err := p.Pin(args[0])
			if err != nil {
				log.Error("pin failed %v", err)
			}
		}
	case 2:
		{
			p.SetMetaName(args[1])
			err := p.Pin(args[0])
			if err != nil {
				log.Error("pin failed %v", err)
			}
		}
	}
	if err := p.OutputPinJson(); err != nil {
		log.Error("failed to print results: %v", err)
		os.Exit(1)
	}

	return nil
}
