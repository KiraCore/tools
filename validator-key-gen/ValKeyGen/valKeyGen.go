package valkeygen

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/cosmos/cosmos-sdk/crypto/hd"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/go-bip39"
	"github.com/tendermint/tendermint/crypto/ed25519"
	"github.com/tendermint/tendermint/p2p"
	"github.com/tendermint/tendermint/privval"
)

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
func CheckPath(path []string) (ok bool, err error) {
	// Check if there are any paths provided
	empty_path := 0
	for _, p := range path {
		if p == "" {
			empty_path++
		}
	}

	// Check if paths are exist
	if empty_path == 0 {
		for _, p := range path {
			dir := filepath.Dir(p)
			// Check if the directory exists
			_, err := os.Stat(dir)
			switch os.IsNotExist(err) {
			case true:
				return false, err
			}

		}
	}

	if empty_path == 3 {
		return false, nil
	}
	return true, nil
}

func CheckMnemonic(mnemonic string) error {
	if len(mnemonic) == 0 {
		return fmt.Errorf("mnemonic can't be empty")
	}
	words := strings.Split(mnemonic, " ")
	if len(words) != 12 && len(words) != 24 {
		return fmt.Errorf("mnemonic should be 12 or 24 words")
	}

	if isValid := bip39.IsMnemonicValid(mnemonic); !isValid {
		return fmt.Errorf("mnemonic is invalid")
	}
	return nil
}

var out io.Writer = os.Stdout

func ValKeyGen(mnemonic, defaultPrefix, defaultPath, valkey, nodekey, keyid string, acadr, valadr, consadr bool) error {
	prefix := Prefix{}

	// Setting up prefix with default or provided values
	err := prefix.New(defaultPrefix, defaultPath)
	if err != nil {
		// panic(fmt.Errorf("malformed prefix %v", err))
		return fmt.Errorf("malformed prefix %v", err)
	}

	// Check if mnemonic is provided and valid
	if err := CheckMnemonic(mnemonic); err != nil {
		// fmt.Fprintln(os.Stderr, err)
		// os.Exit(1)
		return err
	}

	// Generate HD(Hierarchical Deterministic) path from string
	hdPath, err := hd.NewParamsFromPath(defaultPath)
	if err != nil {
		// panic(err)
		return err
	}

	// Generate tendermint MASTER private key from mnemonic
	tmPrivKey := ed25519.GenPrivKeyFromSecret([]byte(mnemonic))

	// Generate tenderming private key from MASTER key
	//tmPrivKey := ed25519.GenPrivKeyFromSecret(tmMasterPrivKey.Bytes())

	// Derive MASTER key from mnemonic and HD path
	masterPrivKey, err := hd.Secp256k1.Derive()(mnemonic, "", hdPath.String())

	// Generate private key from MASTER key
	privKey := hd.Secp256k1.Generate()(masterPrivKey)
	pubKey := privKey.PubKey()

	config := sdk.GetConfig()
	config.SetBech32PrefixForAccount(prefix.GetBech32PrefixAccAddr(), prefix.GetBech32PrefixAccPub())
	config.SetBech32PrefixForValidator(prefix.GetBech32PrefixValAddr(), prefix.GetBech32PrefixValPub())
	config.SetBech32PrefixForConsensusNode(prefix.GetBech32PrefixConsAddr(), prefix.GetBech32PrefixConsPub())
	config.SetPurpose(prefix.fullPath.Purpose)
	config.SetCoinType(prefix.fullPath.CoinType)
	// config.Seal()
	if ok, err := CheckPath([]string{valkey, nodekey, keyid}); err != nil {
		// fmt.Fprintln(os.Stderr, err)
		// os.Exit(1)
		return err
	} else {
		if ok {
			filepvkey := privval.NewFilePV(tmPrivKey, valkey, "").Key
			filenodekey := p2p.NodeKey{
				PrivKey: tmPrivKey,
			}

			if len(valkey) != 0 {
				filepvkey.Save()

			}
			if len(nodekey) != 0 {
				err = filenodekey.SaveAs(nodekey)
				if err != nil {
					// panic(err)
					return err
				}
			}
			if len(keyid) != 0 {
				err = ioutil.WriteFile(keyid, []byte(filenodekey.ID()), 0644)
				if err != nil {
					// panic(err)
					return err
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
	return nil
}
