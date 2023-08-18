package main

import (
	"flag"
	"fmt"
	"os"

	mnemonicsgenerator "github.com/KiraCore/tools/validator-key-gen/MnemonicsGenerator"
	valkeygen "github.com/KiraCore/tools/validator-key-gen/ValKeyGen"
)

const PrivValidatorKeyGenVersion = "v0.3.47"

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
			mnemonicsgenerator.MasterKeysGen([]byte(mnemonic), defaultPrefix, defaultPath, masterkeys)
		} else {
			valkeygen.ValKeyGen(mnemonic, defaultPrefix, defaultPath, valkey, nodekey, keyid, acadr, valadr, consadr)

		}

	}

}
