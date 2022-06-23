// Package to handle cli commands
package cli

import (
	"os"

	"github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	"github.com/spf13/cobra"
)

var (
	key       string // Path to pinata keys
	gateway   string // Pinata gateway to use
	meta      string
	path      string
	c         int8 // CID version integer representation
	verbosity int8
)

var rootCmd = &cobra.Command{
	Use:   "ipfs-api [sub]",
	Short: "IPFS API",
}

//Main function to create cli
func Start() {
	//Turn off completion
	rootCmd.CompletionOptions.DisableDescriptions = true
	rootCmd.CompletionOptions.DisableDefaultCmd = true

	///Adding flags
	rootCmd.PersistentFlags().Int8VarP(&verbosity, "verbose", "v", 0, "Verbosity of the output from 0..5 ")
	rootCmd.PersistentPreRunE = func(cmd *cobra.Command, args []string) error {
		if err := ipfslog.SetDebugLvl(verbosity); err != nil {
			os.Exit(1)
		}
		return nil
	}
	pinCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")
	pinCommand.Flags().Int8VarP(&c, "cid", "c", 1, "CID version. 0 - CIDv0, 1 - CIDv1")
	pinnedCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")
	unpinCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")

	testCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")

	//Assembling commands

	rootCmd.AddCommand(pinnedCommand)
	rootCmd.AddCommand(pinCommand)
	rootCmd.AddCommand(versionCommand)
	rootCmd.AddCommand(unpinCommand)

	rootCmd.AddCommand(testCommand)
	cobra.CheckErr(rootCmd.Execute())

	// setting verbosity level

}
