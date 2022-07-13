package cli

import (
	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav2"
	"github.com/spf13/cobra"
)

var testCommand = &cobra.Command{
	Use:   "test",
	Short: "Testing connection to pinata.cloud",
	Long:  "Testing connection and given key",
	Args:  cobra.MaximumNArgs(0),
	RunE:  test,
}

func test(cmd *cobra.Command, args []string) error {
	keys, err := pnt.GrabKey(key)
	if err != nil {
		return err
	}

	p := pnt.PinataApi{}
	p.SetKeys(keys)
	if err := p.Test(); err != nil {
		return err
	}
	err = p.OutputTestJson()
	if err != nil {
		return err
	}

	return nil

}
