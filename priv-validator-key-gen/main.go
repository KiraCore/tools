package main

import (
	"flag"
	"fmt"
	"io/ioutil"

	"github.com/cosmos/cosmos-sdk/crypto/hd"
	"github.com/cosmos/go-bip39"
	"github.com/tendermint/tendermint/crypto/ed25519"
	"github.com/tendermint/tendermint/p2p"
	"github.com/tendermint/tendermint/privval"
)

func main() {
	mnemonic := flag.String("mnemonic", "", "a string")
	valkey := flag.String("valkey", "", "a string")
	nodekey := flag.String("nodekey", "", "a string")
	keyid := flag.String("keyid", "", "a string")
	flag.Parse()

	if len(*mnemonic) == 0 {
		fmt.Println("mnemonic not set!")
		return
	}
	if len(*valkey) == 0 {
		fmt.Println("valkey not set!")
		return
	}
	if len(*nodekey) == 0 {
		fmt.Println("nodekey not set!")
		return
	}
	if len(*keyid) == 0 {
		fmt.Println("keyid not set!")
		return
	}

	master, ch := hd.ComputeMastersFromSeed(bip39.NewSeed(*mnemonic, ""))
	priv, err := hd.DerivePrivateKeyForPath(master, ch, "44'/118'/0'/0/0")
	if err != nil {
		panic(err)
	}

	privKey := ed25519.GenPrivKeyFromSecret(priv)
	filepvkey := privval.NewFilePV(privKey, *valkey, "").Key
	filepvkey.Save()

	filenodekey := p2p.NodeKey{
		PrivKey: privKey,
	}

	err = filenodekey.SaveAs(*nodekey)
	if err != nil {
		panic(err)
	}

	err = ioutil.WriteFile(*keyid, []byte(filenodekey.ID()), 0644)
	if err != nil {
		panic(err)
	}
}
