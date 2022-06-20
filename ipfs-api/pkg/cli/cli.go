// Package to handle cli commands
package cli

import (
	tp "github.com/kiracore/tools/ipfs-api/types"
	"github.com/spf13/cobra"
)

var (
	key     string // Path to pinata keys
	gateway string // Pinata gateway to use
	wd      bool   // Wrap with dictionary representation
	c       int8   // CID version integer representation
	v       int32
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
	rootCmd.PersistentFlags().Int32VarP(&v, "verbose", "v", 0, "Verbosity of the output from 0..5 ")
	pinCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")
	pinCommand.Flags().Int8VarP(&c, "cid", "c", 1, "CID version. 0 - CIDv0, 1 - CIDv1")
	pinnedCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")
	unpinCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")
	downloadCommand.PersistentFlags().StringVarP(&gateway, "gateway", "g", "https://gateway.pinata.cloud", "IPFS gateway")
	downloadCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")
	testCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")

	//Assembling commands
	rootCmd.AddCommand(cidZeroCommand)
	rootCmd.AddCommand(cidOneCommand)
	rootCmd.AddCommand(pinnedCommand)
	rootCmd.AddCommand(pinCommand)
	rootCmd.AddCommand(versionCommand)
	rootCmd.AddCommand(unpinCommand)
	rootCmd.AddCommand(downloadCommand)
	rootCmd.AddCommand(testCommand)
	cobra.CheckErr(rootCmd.Execute())

	// setting verbosity level
	tp.V = v
}
