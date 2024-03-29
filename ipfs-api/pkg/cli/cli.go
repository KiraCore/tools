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
	verbosity bool
	force     bool
	overwrite bool
)

var rootCmd = &cobra.Command{
	Use:   "ipfs-api [sub]",
	Short: "IPFS API",
}

// Main function to create cli
func Start() {
	//Turn off completion
	rootCmd.CompletionOptions.DisableDescriptions = true
	rootCmd.CompletionOptions.DisableDefaultCmd = true

	///Adding flags
	rootCmd.PersistentFlags().BoolVarP(&verbosity, "verbose", "v", false, "Verbosity level: if true log output or false - jsons and errors. ")
	rootCmd.PersistentPreRunE = func(cmd *cobra.Command, args []string) error {
		if err := ipfslog.SetDebugLvl(verbosity); err != nil {
			os.Exit(1)
		}
		return nil
	}

	pinCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")
	pinCommand.Flags().Int8VarP(&c, "cid", "c", 1, "CID version. 0 - CIDv0, 1 - CIDv1")
	pinCommand.PersistentFlags().BoolVarP(&force, "force", "f", false, "force to change name if file/folder already exist (default false)")
	pinCommand.PersistentFlags().BoolVarP(&overwrite, "overwrite", "o", false, "will delete and pin again given file/folder (default false)")
	pinCommand.PersistentFlags().StringVarP(&meta, "metadata", "m", "", "additional metadata, coma-separated. Example: -m=key,value,key,value")

	dagCommand.PersistentFlags().BoolVarP(&export, "export", "e", false, "export CID to stdout")
	dagCommand.PersistentFlags().Int8VarP(&verCAR, "version", "c", 2, "set CAR version. default v2")
	dagCommand.PersistentFlags().StringVarP(&out, "out", "o", "./file.car", "path to save car file. default .")

	pinnedCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")
	unpinCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")

	testCommand.PersistentFlags().StringVarP(&key, "key", "k", "", "path to your key")

	//Assembling commands

	rootCmd.AddCommand(pinnedCommand)
	rootCmd.AddCommand(pinCommand)
	rootCmd.AddCommand(versionCommand)
	rootCmd.AddCommand(unpinCommand)
	rootCmd.AddCommand(dagCommand)

	rootCmd.AddCommand(testCommand)
	cobra.CheckErr(rootCmd.Execute())

	// setting verbosity level

}
