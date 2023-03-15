package main

import (
	"flag"
	"fmt"
	"io"
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

const PrivValidatorKeyGenVersion = "v0.3.21"

type Prefix struct {
	fullPath             *hd.BIP44Params
	bech32MainPrefix     string
	prefixAccount        string
	prefixValidator      string
	prefixConsensus      string
	prefixPublic         string
	prefixOperator       string
	bech32PrefixAccAddr  string
	bech32PrefixAccPub   string
	bech32PrefixValAddr  string
	bech32PrefixValPub   string
	bech32PrefixConsAddr string
	bech32PrefixConsPub  string
}

func (p *Prefix) New(bech32MainPrefix string, fullPath string) error {
	var err error

	p.bech32MainPrefix = bech32MainPrefix
	p.fullPath, err = hd.NewParamsFromPath(fullPath)
	if err != nil {
		return err
	}

	// PrefixAccount is the prefix for account keys
	p.prefixAccount = "acc"
	// PrefixValidator is the prefix for validator keys
	p.prefixValidator = "val"
	// PrefixConsensus is the prefix for consensus keys
	p.prefixConsensus = "cons"
	// PrefixPublic is the prefix for public keys
	p.prefixPublic = "pub"
	// PrefixOperator is the prefix for operator keys
	p.prefixOperator = "oper"
	// Bech32PrefixAccAddr defines the Bech32 prefix of an account's address
	p.bech32PrefixAccAddr = p.bech32MainPrefix
	// Bech32PrefixAccPub defines the Bech32 prefix of an account's public key
	p.bech32PrefixAccPub = p.bech32MainPrefix + p.prefixPublic
	// Bech32PrefixValAddr defines the Bech32 prefix of a validator's operator address
	p.bech32PrefixValAddr = p.bech32MainPrefix + p.prefixValidator + p.prefixOperator
	// Bech32PrefixValPub defines the Bech32 prefix of a validator's operator public key
	p.bech32PrefixValPub = p.bech32MainPrefix + p.prefixValidator + p.prefixOperator + p.prefixPublic
	// Bech32PrefixConsAddr defines the Bech32 prefix of a consensus node address
	p.bech32PrefixConsAddr = p.bech32MainPrefix + p.prefixValidator + p.prefixConsensus
	// Bech32PrefixConsPub defines the Bech32 prefix of a consensus node public key
	p.bech32PrefixConsPub = p.bech32MainPrefix + p.prefixValidator + p.prefixConsensus + p.prefixPublic
	return nil
}

// TODO
// * add output plain, json

func (p *Prefix) GetBech32PrefixAccAddr() string {
	return p.bech32PrefixAccAddr
}

func (p *Prefix) GetBech32PrefixAccPub() string {
	return p.bech32PrefixAccPub
}
func (p *Prefix) GetBech32PrefixValAddr() string {
	return p.bech32PrefixValAddr
}
func (p *Prefix) GetBech32PrefixValPub() string {
	return p.bech32PrefixValPub
}
func (p *Prefix) GetBech32PrefixConsAddr() string {
	return p.bech32PrefixConsAddr
}
func (p *Prefix) GetBech32PrefixConsPub() string {
	return p.bech32PrefixConsPub
}

func (p *Prefix) ParsePath(path string) (uint32, uint32, uint32, error) {
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

	return uint32(accountIndex), uint32(chainIndex), uint32(addressIndex), nil
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

	// Condition: require 3 paths to be provided
	// if empty_path > 0 && empty_path <= 2 {
	// 	return false, fmt.Errorf("please provide all flags: --valkey, --nodekey, --keyid")

	// }

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

var out io.Writer = os.Stdout

func ValKeyGen(mnemonic, defaultPrefix, defaultPath, valkey, nodekey, keyid string, acadr, valadr, consadr bool) {
	prefix := Prefix{}
	// Setting up prefix with default or provided values
	err := prefix.New(defaultPrefix, defaultPath)
	if err != nil {
		panic(fmt.Errorf("malformed prefix %v", err))
	}

	// mnemonic should be provided
	if err := checkMnemonic(mnemonic); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	seed := bip39.NewSeed(mnemonic, "")
	master, ch := hd.ComputeMastersFromSeed(seed)
	priv, err := hd.DerivePrivateKeyForPath(master, ch, prefix.fullPath.String())
	if err != nil {
		panic(err)
	}
	privKey := ed25519.GenPrivKeyFromSecret(priv)
	pubKey := privKey.PubKey()

	config := sdk.GetConfig()

	config.SetBech32PrefixForAccount(prefix.GetBech32PrefixAccAddr(), prefix.GetBech32PrefixAccPub())
	config.SetBech32PrefixForValidator(prefix.GetBech32PrefixValAddr(), prefix.GetBech32PrefixValPub())
	config.SetBech32PrefixForConsensusNode(prefix.GetBech32PrefixConsAddr(), prefix.GetBech32PrefixConsPub())
	config.SetPurpose(prefix.fullPath.Purpose)
	config.SetCoinType(prefix.fullPath.CoinType)
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

			if len(valkey) != 0 {
				filepvkey.Save()

			}
			if len(nodekey) != 0 {
				err = filenodekey.SaveAs(nodekey)
				if err != nil {
					panic(err)
				}
			}
			if len(keyid) != 0 {
				err = ioutil.WriteFile(keyid, []byte(filenodekey.ID()), 0644)
				if err != nil {
					panic(err)
				}
			}

		} else {
			if acadr {
				fmt.Fprintln(out, sdk.AccAddress(pubKey.Address().Bytes()).String())
			}
			if valadr {
				fmt.Fprintln(out, sdk.ValAddress(pubKey.Address()).String())
			}
			if consadr {
				fmt.Fprintln(out, sdk.ConsAddress(pubKey.Address().Bytes()).String())
			}

		}
	}

}
func main() {

	var (
		// Mnemonic
		mnemonic string

		// Prefix block
		defaultPrefix string
		defaultPath   string

		// Output path block
		valkey  string
		nodekey string
		keyid   string

		// Printout options block
		acadr   bool
		valadr  bool
		consadr bool
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

	fs.StringVar(&defaultPrefix, "prefix", "kira", "set prefix")
	//Set derive path
	fs.StringVar(&defaultPath, "path", "44'/118'/0'/0/0", "set derive path")

	fs.Usage = func() {
		fmt.Printf("Usage: %s --mnemonic=\"over where ...\" [OPTIONS]\n\n", fs.Name())
		fmt.Println("Options:")
		fs.PrintDefaults()

	}

	fs.Parse(os.Args[1:])

	if !fs.Parsed() {
		fmt.Fprintln(os.Stderr, fmt.Errorf("flags were not parsed!"))
	}

	ValKeyGen(mnemonic, defaultPrefix, defaultPath, valkey, nodekey, keyid, acadr, valadr, consadr)

	// Wrap this logic to some function!

}
