package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

const Bip39GenVersion = "v0.3.45"

func cmdVersion(cmd *cobra.Command, args []string) error {
	fmt.Println(Bip39GenVersion)
	return nil
}
