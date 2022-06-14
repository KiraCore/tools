// Package to handle cli commands
package cli

import (
	"bufio"
	"os"
	"strings"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	tp "github.com/kiracore/tools/ipfs-api/types"
	"github.com/spf13/cobra"
)

var (
	keyPath string
	gateway string
)

var rootCmd = &cobra.Command{
	Use:   "ipfs-api [sub]",
	Short: "IPFS API",
}

// Parsing given path for pinata keys
// Valid file example:
// API Key: <key>
// API Secret: <secret>
// JWT: <jwt>
func grabKey(keyPath string) (tp.Keys, error) {
	// checking if path to keys is valid
	if _, err := os.Stat(keyPath); os.IsNotExist(err) {
		log.Error("pin: provided path doesn't exist")
		return tp.Keys{}, err
	}

	file, err := os.Open(keyPath)
	if err != nil {
		log.Error("grabkey: unable to get key")
		return tp.Keys{}, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	var res []string

	for scanner.Scan() {
		newString := strings.Split(scanner.Text(), ":")
		if len(newString) != 1 {
			res = append(res, strings.TrimSpace(newString[1]))
		} else {
			log.Error("grabkey: failed to parse keys from file. invalid format\nexpected:\nAPI Key: value\nAPI Secret: value\nJWT: value")
			return tp.Keys{}, err
		}

	}

	key := tp.Keys{Api_key: res[0], Api_secret: res[1], JWT: res[2]}
	if scanner.Err() != nil {
		log.Error("err")
		return tp.Keys{}, err
	}

	return key, nil
}

//Main function to create cli
func Start() {
	//Turn off completion
	rootCmd.CompletionOptions.DisableDescriptions = true
	rootCmd.CompletionOptions.DisableDefaultCmd = true

	///Adding flags
	pinCommand.PersistentFlags().StringVarP(&keyPath, "key", "k", "", "path to your key")
	pinnedCommand.PersistentFlags().StringVarP(&keyPath, "key", "k", "", "path to your key")
	unpinCommand.PersistentFlags().StringVarP(&keyPath, "key", "k", "", "path to your key")
	downloadCommand.PersistentFlags().StringVarP(&gateway, "gateway", "g", "https://gateway.pinata.cloud", "IPFS gateway")
	downloadCommand.PersistentFlags().StringVarP(&keyPath, "key", "k", "", "path to your key")
	testCommand.PersistentFlags().StringVarP(&keyPath, "key", "k", "", "path to yoour key")

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
}
