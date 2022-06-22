package cli

import (
	"log"
	"os"

	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav1"
	tp "github.com/kiracore/tools/ipfs-api/types"
	"github.com/spf13/cobra"
)

var pinCommand = &cobra.Command{
	Use:     "pin <file/folder-path> <file/folder-name> --key=<file-path/string>",
	Short:   "File/folder upload and pin",
	Long:    "File/folder upload and pin",
	PreRunE: checkName,
	RunE:    pinCmd,
}

func pinCmd(cmd *cobra.Command, args []string) error {
	if c != 1 && c != 0 {
		log.Fatalln("CID version value should be 0 or 1")
	}
	keys, _ := grabKey(key)
	tp.Opts = tp.PinataOptions{CidVersion: c, WrapWithDirectory: wd}
	if err := pnt.Pin(args, keys); err != nil {
		log.Fatalln("\033[31m", err)
		os.Exit(1)
	}
	return nil
}
func checkName(cmd *cobra.Command, args []string) error {
	keys, _ := grabKey(key)
	pnt.GetHashByName(args, keys)
	return nil
}
