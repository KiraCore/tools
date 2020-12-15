package main

import (
	"flag"

	"github.com/cosmos/go-bip39"
	"github.com/tendermint/tendermint/libs/tempfile"
	"github.com/tendermint/tendermint/privval"

	"github.com/tendermint/tendermint/crypto/ed25519"
	tmjson "github.com/tendermint/tendermint/libs/json"
)

func save(pvKey privval.FilePVKey) {
}

func main() {
	mnemonic := flag.String("mnemonic", "swap exercise equip shoot mad inside floor wheel loan visual stereo build frozen always bulb naive subway foster marine erosion shuffle flee action there", "a string")
	path := flag.String("output", "./", "a string")
	flag.Parse()

	privKey := ed25519.GenPrivKeyFromSecret(bip39.NewSeed(*mnemonic, ""))
	filepvkey := privval.FilePVKey{
		Address: privKey.PubKey().Address(),
		PubKey:  privKey.PubKey(),
		PrivKey: privKey,
	}

	jsonBytes, err := tmjson.MarshalIndent(filepvkey, "", "  ")
	if err != nil {
		panic(err)
	}

	err = tempfile.WriteFileAtomic(*path+"/priv_validator_key.json", jsonBytes, 0600)
	if err != nil {
		panic(err)
	}
}
