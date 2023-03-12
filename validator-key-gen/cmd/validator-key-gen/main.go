package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

	"github.com/cosmos/cosmos-sdk/crypto/hd"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/go-bip39"
	"github.com/tendermint/tendermint/crypto/ed25519"
	"github.com/tendermint/tendermint/p2p"
	"github.com/tendermint/tendermint/privval"
)

var (

	// Bech32MainPrefix defines the main SDK Bech32 prefix of an account's address
	Bech32MainPrefix = "kira"

	// FullPath is the parts of the BIP44 HD path that are fixed by
	// what we used during the ATOM fundraiser.
	FullPath = "m/44'/118'/0'/0/0"

	// PrefixAccount is the prefix for account keys
	PrefixAccount = "acc"
	// PrefixValidator is the prefix for validator keys
	PrefixValidator = "val"
	// PrefixConsensus is the prefix for consensus keys
	PrefixConsensus = "cons"
	// PrefixPublic is the prefix for public keys
	PrefixPublic = "pub"
	// PrefixOperator is the prefix for operator keys
	PrefixOperator = "oper"
	// Bech32PrefixAccAddr defines the Bech32 prefix of an account's address
	Bech32PrefixAccAddr = Bech32MainPrefix
	// Bech32PrefixAccPub defines the Bech32 prefix of an account's public key
	Bech32PrefixAccPub = Bech32MainPrefix + PrefixPublic
	// Bech32PrefixValAddr defines the Bech32 prefix of a validator's operator address
	Bech32PrefixValAddr = Bech32MainPrefix + PrefixValidator + PrefixOperator
	// Bech32PrefixValPub defines the Bech32 prefix of a validator's operator public key
	Bech32PrefixValPub = Bech32MainPrefix + PrefixValidator + PrefixOperator + PrefixPublic
	// Bech32PrefixConsAddr defines the Bech32 prefix of a consensus node address
	Bech32PrefixConsAddr = Bech32MainPrefix + PrefixValidator + PrefixConsensus
	// Bech32PrefixConsPub defines the Bech32 prefix of a consensus node public key
	Bech32PrefixConsPub = Bech32MainPrefix + PrefixValidator + PrefixConsensus + PrefixPublic
)

const PrivValidatorKeyGenVersion = "v0.3.20"

func parseBIP44Path(path string) (int, int, int, error) {
	// Split path into its components
	parts := strings.Split(path, "/")
	if len(parts) != 5 {
		return 0, 0, 0, fmt.Errorf("Invalid BIP44 path")
	}

	// Check that the first part is "m"
	if parts[0] != "m" {
		return 0, 0, 0, fmt.Errorf("Invalid BIP44 path")
	}

	// Parse account, chain, and address indexes
	accountIndex, err := strconv.Atoi(strings.TrimSuffix(parts[2], "'"))
	if err != nil {
		return 0, 0, 0, fmt.Errorf("Invalid BIP44 path")
	}
	chainIndex, err := strconv.Atoi(parts[3])
	if err != nil {
		return 0, 0, 0, fmt.Errorf("Invalid BIP44 path")
	}
	addressIndex, err := strconv.Atoi(parts[4])
	if err != nil {
		return 0, 0, 0, fmt.Errorf("Invalid BIP44 path")
	}

	return accountIndex, chainIndex, addressIndex, nil
}

// function to check if paths exist and not empty
func checkPath(path []string) (ok bool, err error) {
	// Check if there are any paths provided
	empty_path := 0
	for _, p := range path {
		if p == "" {
			empty_path++
		}
	}
	if empty_path > 0 && empty_path <= 2 {
		return false, fmt.Errorf("please provide all flags: --valkey, --nodekey, --keyid")

	}

	// Check if paths are exist
	if empty_path == 0 {
		for _, p := range path {
			if _, err := os.Stat(p); os.IsNotExist(err) {
				return false, fmt.Errorf("path %s doesn't exist!", p)

			}
		}
	}

	if empty_path == 3 {
		return false, nil
	}
	return true, nil
}

func checkMnemonic(mnemonic string) error {
	if len(mnemonic) == 0 {
		return fmt.Errorf("mnemonic can't be empty")
	}
	words := strings.Split(mnemonic, " ")
	if len(words) != 12 && len(words) != 24 {
		return fmt.Errorf("mnemonic should be 12 or 24 words")
	}

	if isValid := bip39.IsMnemonicValid(mnemonic); !isValid {
		return fmt.Errorf("mnemonic is invalid!")
	}
	return nil
}

func main() {

	var (
		mnemonic string
		valkey   string
		nodekey  string
		keyid    string
		derive   string
		acadr    bool
		valadr   bool
		consadr  bool
	)

	fs := flag.NewFlagSet("validator-key-gen", flag.ExitOnError)

	fs.StringVar(&mnemonic, "mnemonic", "", "Valid BIP39 mnemonic(required)")

	// Path to place files. Path should exist.

	fs.StringVar(&valkey, "valkey", "", "path, where validator key json file will be placed")
	fs.StringVar(&nodekey, "nodekey", "", "path, where node key json file will be placed")
	fs.StringVar(&keyid, "keyid", "", "path, where NodeID file will be placed")

	// Ouput config
	fs.BoolVar(&acadr, "accadr", false, "boolean, if true - output account address")
	fs.BoolVar(&valadr, "valadr", false, "boolean, if true - output validator address")
	fs.BoolVar(&consadr, "consadr", false, "boolean, if true - output consensus address")

	//Set prefix
	fs.Func("prefix", "set prefix", func(s string) error { Bech32MainPrefix, Bech32PrefixAccAddr = s, s; return nil })
	//Set derive path
	fs.StringVar(&derive, "derive", FullPath, "set derive path")

	fs.Usage = func() {
		fmt.Printf("Usage: %s --mnemonic=\"over where ...\" [OPTIONS]\n\n", fs.Name())
		fmt.Println("Options:")
		fs.PrintDefaults()

	}

	fs.Parse(os.Args[1:])

	if !fs.Parsed() {
		fmt.Fprintln(os.Stderr, fmt.Errorf("flags were not parsed!"))
	}

	//mnemonic should be provided
	if err := checkMnemonic(mnemonic); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	seed := bip39.NewSeed(mnemonic, "")
	master, ch := hd.ComputeMastersFromSeed(seed)
	priv, err := hd.DerivePrivateKeyForPath(master, ch, FullPath)
	if err != nil {
		panic(err)
	}
	privKey := ed25519.GenPrivKeyFromSecret(priv)
	pubKey := privKey.PubKey()

	accountIndex, chainIndex, _, err := parseBIP44Path(derive)
	config := sdk.GetConfig()
	config.SetBech32PrefixForAccount(Bech32PrefixAccAddr, Bech32PrefixAccPub)
	config.SetBech32PrefixForValidator(Bech32PrefixValAddr, Bech32PrefixValPub)
	config.SetBech32PrefixForConsensusNode(Bech32PrefixConsAddr, Bech32PrefixConsPub)
	config.SetPurpose(uint32(accountIndex))
	config.SetCoinType(uint32(chainIndex))
	config.Seal()

	if ok, err := checkPath([]string{valkey, nodekey, keyid}); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	} else {
		if ok {
			filepvkey := privval.NewFilePV(privKey, valkey, "").Key
			filenodekey := p2p.NodeKey{
				PrivKey: privKey,
			}
			filepvkey.Save()
			err = filenodekey.SaveAs(nodekey)
			if err != nil {
				panic(err)
			}
			err = ioutil.WriteFile(keyid, []byte(filenodekey.ID()), 0644)
			if err != nil {
				panic(err)
			}
		} else {
			if acadr {
				fmt.Println(sdk.AccAddress(pubKey.Address().Bytes()).String())
			}
			if valadr {
				fmt.Println(sdk.ValAddress(pubKey.Address()).String())
			}
			if consadr {
				fmt.Println(sdk.ConsAddress(pubKey.Address().Bytes()).String())
			}

		}
	}

}
