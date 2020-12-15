package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/cosmos/go-bip39"
	"github.com/tendermint/tendermint/libs/tempfile"
	"github.com/tendermint/tendermint/privval"

	"github.com/tendermint/tendermint/crypto/ed25519"
	tmjson "github.com/tendermint/tendermint/libs/json"
)

func save(pvKey privval.FilePVKey) {
}

func main() {
	// mnemonic := "swap exercise equip shoot mad inside floor wheel loan visual stereo build frozen always bulb naive subway foster marine erosion shuffle flee action there"

	reader := bufio.NewReader(os.Stdin)
	fmt.Print("Enter Mnemonic: ")
	mnemonic, _ := reader.ReadString('\n')
	mnemonic = strings.Trim(mnemonic, " \n")
	fmt.Print("Enter path to save priv_validator_key.json: ")
	path, _ := reader.ReadString('\n')
	path = strings.Trim(path, " \n")
	if len(path) == 0 {
		path = "."
	}

	privKey := ed25519.GenPrivKeyFromSecret(bip39.NewSeed(mnemonic, ""))
	filepvkey := privval.FilePVKey{
		Address: privKey.PubKey().Address(),
		PubKey:  privKey.PubKey(),
		PrivKey: privKey,
	}

	jsonBytes, err := tmjson.MarshalIndent(filepvkey, "", "  ")
	if err != nil {
		panic(err)
	}

	err = tempfile.WriteFileAtomic(path+"/priv_validator_key.json", jsonBytes, 0600)
	if err != nil {
		panic(err)
	}
}
