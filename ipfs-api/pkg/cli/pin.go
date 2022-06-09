package cli

import (
	"log"

	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav1"
	"github.com/spf13/cobra"
)

var pinCommand = &cobra.Command{
	Use:   "pin <file/folder-path> <file/folder-name> --key=<file-path/string>",
	Short: "File/folder upload and pin",
	Long:  "File/folder upload and pin",
	RunE:  pinCmd,
}

func pinCmd(cmd *cobra.Command, args []string) error {
	keys, _ := grabKey(keyPath)
	if err := pnt.Pin(args, keys); err != nil {
		log.Fatalln("\033[31m", err)
	}
	return nil
}
