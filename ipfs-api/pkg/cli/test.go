package cli

import (
	"os"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav2"
	"github.com/spf13/cobra"
)

var testCommand = &cobra.Command{
	Use:   "test",
	Short: "Testing connection to pinata.cloud",
	Long:  "Testing connection and given key",
	RunE:  test,
}

func test(cmd *cobra.Command, args []string) error {
	keys, err := pnt.GrabKey(key)
	if err != nil {
		log.Error("grabKey: failed to get keys: %v", err)
		os.Exit(1)
	}
	if !keys.Check() {
		log.Error("Keys not provided")
		os.Exit(1)
	}

	p := pnt.PinataApi{}
	p.SetKeys(keys)
	er := p.Test()
	if er != nil {
		os.Exit(1)
	}

	return nil

}
