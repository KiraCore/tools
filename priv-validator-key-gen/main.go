package main

import (
	"flag"
	"io/ioutil"

	"github.com/cosmos/go-bip39"
	"github.com/tendermint/tendermint/privval"

	"github.com/cosmos/cosmos-sdk/crypto/hd"
	"github.com/tendermint/tendermint/crypto/ed25519"
	tmjson "github.com/tendermint/tendermint/libs/json"
)

func main() {
	mnemonic := flag.String("mnemonic", "swap exercise equip shoot mad inside floor wheel loan visual stereo build frozen always bulb naive subway foster marine erosion shuffle flee action there", "a string")
	path := flag.String("output", "./priv_validator_key.json", "a string")
	flag.Parse()

	master, ch := hd.ComputeMastersFromSeed(bip39.NewSeed(*mnemonic, ""))
	priv, err := hd.DerivePrivateKeyForPath(master, ch, "44'/118'/0'/0/0")

	privKey := ed25519.GenPrivKeyFromSecret(priv)
	filepvkey := privval.FilePVKey{
		Address: privKey.PubKey().Address(),
		PubKey:  privKey.PubKey(),
		PrivKey: privKey,
	}

	jsonBytes, err := tmjson.MarshalIndent(filepvkey, "", "  ")
	if err != nil {
		panic(err)
	}

	err = ioutil.WriteFile(*path, jsonBytes, 0644)
	if err != nil {
		panic(err)
	}
}
