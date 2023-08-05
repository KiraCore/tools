package main

import (
	"crypto/sha256"
	"encoding/hex"
	"flag"
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

const PrivValidatorKeyGenVersion = "v0.3.46"

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

func ValKeyGen(mnemonic, defaultPrefix, defaultPath, valkey, nodekey, keyid string, acadr, valadr, consadr bool) string {
	prefix := Prefix{}

	// Setting up prefix with default or provided values
	err := prefix.New(defaultPrefix, defaultPath)
	if err != nil {
		panic(fmt.Errorf("malformed prefix %v", err))
	}

	// Check if mnemonic is provided and valid
	if err := checkMnemonic(mnemonic); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	// Generate HD(Hierarchical Deterministic) path from string
	hdPath, err := hd.NewParamsFromPath(defaultPath)
	if err != nil {
		panic(err)
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
	var ret string
	if ok, err := checkPath([]string{valkey, nodekey, keyid}); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
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
					panic(err)
				}
			}
			if len(keyid) != 0 {
				err = ioutil.WriteFile(keyid, []byte(filenodekey.ID()), 0644)
				if err != nil {
					panic(err)
				}
				ret = string([]byte(filenodekey.ID()))
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
	return ret
}
func createEnvFileForGeneratedMnemonics(path string, mnemonicData []byte) error {
	file, err := os.Create(path)
	if err != nil {
		fmt.Println("Error creating .env file:", err)
		return err
	}
	defer file.Close()
	_, err = file.WriteString(string(mnemonicData))
	if err != nil {
		fmt.Println("Error writing to mnemonics.env file:", err)
		return err
	}
	return nil
}

func generateMnemonicFromAnotherMnemonic(name, t string, masterMnemonic []byte) ([]byte, error) {
	lowerCaseString := strings.ToLower(fmt.Sprintf("%s ; %s %s", masterMnemonic, name, t))
	lowerCaseString = strings.ReplaceAll(lowerCaseString, " ", "")

	hasher := sha256.New()
	hasher.Write([]byte(lowerCaseString))
	entropyHex := hex.EncodeToString(hasher.Sum(nil))

	entropy, err := hex.DecodeString(entropyHex)
	if err != nil {
		return []byte{}, fmt.Errorf("error decoding hex string: %w", err)
	}

	mnemonic, err := bip39.NewMnemonic(entropy)
	if err != nil {
		return []byte{}, fmt.Errorf("error generating mnemonic: %w", err)
	}

	return []byte(mnemonic), nil
}

func MasterKeysGen(mnemonic []byte, defaultPrefix, defaultPath, masterkeys string) {
	err := checkMnemonic(string(mnemonic))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	ok, err := checkPath([]string{masterkeys})
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if ok {

		// VALIDATOR_NODE_MNEMONIC
		validatorNodeMnemonic, err := generateMnemonicFromAnotherMnemonic("validator", "node", mnemonic)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}

		keyid := ValKeyGen(string(validatorNodeMnemonic), defaultPrefix, defaultPath, "",
			fmt.Sprintf("%s/validator_node_key.json", masterkeys),
			fmt.Sprintf("%s/validator_node_id.key", masterkeys),
			false, false, false)
		// VALIDATOR_NODE_ID
		validatorNodeId := &keyid

		//VALIDATOR_ADDR_MNEMONIC
		validatorAddrMnemonic, err := generateMnemonicFromAnotherMnemonic("validator", "addr", mnemonic)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}

		//VALIDATOR_VAL_MNEMONIC
		validatorValMnemonic, err := generateMnemonicFromAnotherMnemonic("validator", "val", mnemonic)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		ValKeyGen(string(validatorValMnemonic), defaultPrefix, defaultPath, fmt.Sprintf("%s/priv_validator_key.json", masterkeys), "", "", false, false, false)

		//SIGNER_ADDR_MNEMONIC
		signerAddrMnemonic, err := generateMnemonicFromAnotherMnemonic("signer", "addr", mnemonic)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}

		dataToWrite := []byte(fmt.Sprintf("MASTER_MNEMONIC=%s\nVALIDATOR_ADDR_MNEMONIC=%s\nVALIDATOR_NODE_MNEMONIC=%s\nVALIDATOR_NODE_ID=%s\nVALIDATOR_VAL_MNEMONIC=%s\nSIGNER_ADDR_MNEMONIC=%s\n ", mnemonic, validatorAddrMnemonic, validatorNodeMnemonic, *validatorNodeId, validatorValMnemonic, signerAddrMnemonic))
		err = createEnvFileForGeneratedMnemonics(fmt.Sprintf("%s/mnemonics.env", masterkeys), dataToWrite)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		dataToWrite = []byte{}
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
		valkey     string
		nodekey    string
		keyid      string
		masterkeys string

		// Printout options block
		acadr   bool
		valadr  bool
		consadr bool
		version bool
		master  bool
	)

	fs := flag.NewFlagSet("validator-key-gen", flag.ExitOnError)

	fs.StringVar(&mnemonic, "mnemonic", "", "Valid BIP39 mnemonic(required)")
	fs.BoolVar(&master, "master", false, "boolean , if true - generate whole mnemonic set")

	// Path to place files. Path should exist.

	fs.StringVar(&masterkeys, "masterkeys", "", "path, where master's mnemonic set and keys key files will be placed")
	fs.StringVar(&valkey, "valkey", "", "path, where validator key json file will be placed")
	fs.StringVar(&nodekey, "nodekey", "", "path, where node key json file will be placed")
	fs.StringVar(&keyid, "keyid", "", "path, where NodeID file will be placed")

	// Ouput config
	fs.BoolVar(&acadr, "accadr", false, "boolean, if true - yield account address")
	fs.BoolVar(&valadr, "valadr", false, "boolean, if true - yield validator address")
	fs.BoolVar(&consadr, "consadr", false, "boolean, if true - yield consensus address")
	fs.BoolVar(&version, "version", false, "boolean , if true - yield current version")

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
	switch version {
	case true:
		fmt.Fprintln(os.Stdout, PrivValidatorKeyGenVersion)
		os.Exit(0)
	case false:
		if master {
			MasterKeysGen([]byte(mnemonic), defaultPrefix, defaultPath, masterkeys)
		} else {
			ValKeyGen(mnemonic, defaultPrefix, defaultPath, valkey, nodekey, keyid, acadr, valadr, consadr)
		}

	}

}
