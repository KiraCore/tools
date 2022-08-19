package cmd

import (
	"github.com/spf13/cobra"
)

var words int
var verbose bool

var userEntropy string
var rawEntropy string

var ImpUsrEnt *string = &userEntropy

var hex bool

var rootCmd = &cobra.Command{
	Use:   "bip39gen [sub]",
	Short: "Bip39 Mnemonic Generator",
}

var mnemonicCommand = &cobra.Command{
	Use:   "mnemonic [command]",
	Short: "mnemonic",
	Long:  "Generate mnemonic words",
	RunE:  cmdMnemonic,
}

var versionCommand = &cobra.Command{
	Use:   "version",
	Short: "version",
	Long:  "Check the current version.",
	RunE:  cmdVersion,
}

func init() {
	//Turn off completion
	rootCmd.CompletionOptions.DisableDescriptions = true
	rootCmd.CompletionOptions.DisableDefaultCmd = true

	//Adding flags
	mnemonicCommand.Flags().IntVarP(&words, "length", "l", 24, "number of mnemonic words")

	mnemonicCommand.Flags().StringVarP(&userEntropy, "entropy", "e", "", "provide entropy for mixing and generating new mnemonic sentences")
	mnemonicCommand.Flags().StringVarP(&rawEntropy, "raw-entropy", "r", "", "provide entropy to regenerate mnemonic sentences from")

	mnemonicCommand.Flags().Changed("entropy")
	mnemonicCommand.Flags().Changed("raw-entropy")

	mnemonicCommand.Flags().BoolVar(&hex, "hex", false, "set hexadecimal string format for input")

	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose level of output")

	rootCmd.AddCommand(mnemonicCommand)
	rootCmd.AddCommand(versionCommand)

}

func Execute() error {

	return rootCmd.Execute()
}
