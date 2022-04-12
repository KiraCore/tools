package main

import (
	"encoding/hex"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"crypto/sha256"

	"github.com/KiraCore/go-bip39"

	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

var (
	entropy string
	length  string
	verbose bool
)

type response struct {
	Code   int
	Result string
}

const codeSuccess int = 0
const codeFail int = 1
const Bip39GenVersion = "v0.0.1.1"

func makeTimestamp() int64 {
	return time.Now().UnixNano() / int64(time.Millisecond)
}

func main() {
	// bip39gen mnemonic --length=24 --entropy="<optional-user-provided-entropy>"

	var rootCmd = &cobra.Command{
		Use:   "bip39gen [sub]",
		Short: "Bip39 Mnemonic Generator",
	}

	var mnemonicCommand = &cobra.Command{
		Use:   "mnemonic [options]",
		Short: "mnemonic",
		Long:  "Generate mnemonic words",
		RunE:  cmdMnemonic,
	}

	var versionCommand = &cobra.Command{
		Use:   "version",
		Short: "version",
		Long:  "Get bip39gen version",
		RunE:  cmdVersion,
	}

	mnemonicCommand.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "<bool> print explicit output")
	mnemonicCommand.PersistentFlags().StringVarP(&length, "length", "l", "24", "<int> number of mnemonic words")
	mnemonicCommand.PersistentFlags().StringVarP(&entropy, "entropy", "e", "", "<string> user provided external randomness")

	rootCmd.AddCommand(mnemonicCommand)
	rootCmd.AddCommand(versionCommand)

	rootCmd.Execute()
}

func cmdVersion(cmd *cobra.Command, args []string) error {
	fmt.Print(Bip39GenVersion)
	return nil
}

func cmdMnemonic(cmd *cobra.Command, args []string) error {

	iLength, errLength := strconv.ParseInt(length, 10, 0)

	if verbose == true {
		fmt.Println("Mnemonic Length: " + strconv.Itoa(int(iLength)))
		fmt.Println("   User Entropy: " + entropy)
	}

	// bip39gen mnemonic --verbose=true --length=24
	if errLength != nil || (iLength%3) != 0 || iLength < 12 || iLength > 24 {
		response{
			Code:   codeFail,
			Result: "Invalid mnemonic length, must be divisible by 3, longer or equal 12 and smaller or equal 24",
		}.printResponse()

		return nil
	}

	bits := int((iLength * 32) / 3)

	if verbose == true {
		fmt.Println("   Entropy Bits: " + strconv.Itoa(int(bits)))
	}

	if (bits%32) != 0 || bits < 128 || bits > 256 {
		response{
			Code:   codeFail,
			Result: "Failed entropy generations, bits count must be divisible by 32 and within inclusive range of {128, 256}",
		}.printResponse()

		return nil
	}

	hasher := sha256.New()
	seed, _ := bip39.NewEntropy(bits)

	if verbose == true {
		fmt.Println("   Default Seed: " + hex.EncodeToString(seed))
	}

	for i := 0; i < len(seed); {
		entropy := uuid.New().String() + entropy
		hasher.Write([]byte(entropy))
		shaResult := hasher.Sum(nil)
		for i2 := 0; i2 < 32 && i < len(seed); i2++ {
			seed[i] = seed[i] ^ shaResult[i2]
			i++
		}
	}

	if verbose == true {
		fmt.Println("     Final Seed: " + hex.EncodeToString(seed))
	}

	mnemonic, _ := bip39.NewMnemonic(seed)

	if verbose == true {
		fmt.Println("Output Mnemonic: " + mnemonic)
		fmt.Println("")
	}

	var words = strings.Split(mnemonic, " ")

	if len(words) != int(iLength) {
		response{
			Code:   codeFail,
			Result: "Generation failed, incorrect number of output words, expected " + strconv.Itoa(int(iLength)) + " but got " + strconv.Itoa(len(words)),
		}.printResponse()

		return nil
	}

	response{
		Code:   codeSuccess,
		Result: mnemonic,
	}.printResponse()

	return nil
}

func (log response) printResponse() {
	fmt.Println(log.Result)
	os.Exit(log.Code)
}
