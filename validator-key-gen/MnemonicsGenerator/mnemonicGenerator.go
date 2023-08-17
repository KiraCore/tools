package mnemonicsgenerator

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"strings"

	valkeygen "github.com/KiraCore/tools/validator-key-gen/ValKeyGen"
	"github.com/cosmos/go-bip39"
	"github.com/tendermint/tendermint/crypto/ed25519"
	"github.com/tendermint/tendermint/p2p"
)

type MasterMnemonicSet struct {
	ValidatorAddrMnemonic []byte
	ValidatorValMnemonic  []byte
	SignerAddrMnemonic    []byte
	ValidatorNodeMnemonic []byte
	ValidatorNodeId       []byte
}

// returns nodeId from mnemonic
func generateNodeIdFromMnemonic(mnemonic string) []byte {
	if err := valkeygen.CheckMnemonic(mnemonic); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	tmPrivKey := ed25519.GenPrivKeyFromSecret([]byte(mnemonic))
	filenodekey := p2p.NodeKey{
		PrivKey: tmPrivKey,
	}
	nodeId := []byte(filenodekey.ID())
	return nodeId
}

func createMnemonicsFile(path string, mnemonicData []byte) error {
	file, err := os.Create(path)
	if err != nil {
		fmt.Printf("Error creating %s file: %s", path, err)
		return err
	}
	defer file.Close()
	_, err = file.WriteString(string(mnemonicData))
	if err != nil {
		fmt.Printf("Error creating %s file: %s", path, err)
		return err
	}
	return nil
}

// acceps name and typeOfMnemonic as salt and mnemonic, for example MnemonicGenerator --name="validator" --type="addr"  - validator address
func generateFromMasterMnemonic(name, typeOfMnemonic string, masterMnemonic []byte) ([]byte, error) {
	stringToHash := strings.ToLower(fmt.Sprintf("%s ; %s %s", masterMnemonic, name, typeOfMnemonic))
	stringToHash = strings.ReplaceAll(stringToHash, " ", "")

	hasher := sha256.New()
	hasher.Write([]byte(stringToHash))
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

// # Generates set of mnemonics from master mnemonic, accepts masterMnemonic string as byte
//
// Default function call MasterKeysGen([]byte("mnemonic string"), "", "", "./path")
//
// go run .\main.go --mnemonic "want vanish frown filter resemble purchase trial baby equal never cinnamon claim wrap cash snake cable head tray few daring shine clip loyal series" --masterkeys .\test\ --master
//
// # FOR PACKAGE USSAGE
//
// defaultPrefix: "kira"
//
// defaultPath: "44'/118'/0'/0/0"
func MasterKeysGen(masterMnemonic []byte, defaultPrefix, defaultPath, masterkeys string) (mnemonicSet MasterMnemonicSet, err error) {
	err = valkeygen.CheckMnemonic(string(masterMnemonic))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return mnemonicSet, err
	}

	ok, err := valkeygen.CheckPath([]string{masterkeys})
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		fmt.Println(ok, masterkeys)
		return mnemonicSet, err
	}

	if ok {
		// VALIDATOR_NODE_MNEMONIC
		mnemonicSet.ValidatorNodeMnemonic, err = generateFromMasterMnemonic("validator", "node", masterMnemonic)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return mnemonicSet, err
		}

		// VALIDATOR_NODE_ID
		mnemonicSet.ValidatorNodeId = generateNodeIdFromMnemonic(string(mnemonicSet.ValidatorNodeMnemonic))

		//VALIDATOR_ADDR_MNEMONIC
		mnemonicSet.ValidatorAddrMnemonic, err = generateFromMasterMnemonic("validator", "addr", masterMnemonic)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return mnemonicSet, err
		}

		//VALIDATOR_VAL_MNEMONIC
		mnemonicSet.ValidatorValMnemonic, err = generateFromMasterMnemonic("validator", "val", masterMnemonic)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return mnemonicSet, err
		}

		//SIGNER_ADDR_MNEMONIC
		mnemonicSet.SignerAddrMnemonic, err = generateFromMasterMnemonic("signer", "addr", masterMnemonic)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return mnemonicSet, err
		}

		if masterkeys != "" {
			// validator_node_key.json validator_node_id.key" files
			valkeygen.ValKeyGen(string(mnemonicSet.ValidatorNodeMnemonic), defaultPrefix, defaultPath, "",
				fmt.Sprintf("%s/validator_node_key.json", masterkeys),
				fmt.Sprintf("%s/validator_node_id.key", masterkeys),
				false, false, false)

			// priv_validator_key.json files
			valkeygen.ValKeyGen(string(mnemonicSet.ValidatorValMnemonic), defaultPrefix, defaultPath, fmt.Sprintf("%s/priv_validator_key.json", masterkeys), "", "", false, false, false)

			// mnemonics.env file
			dataToWrite := []byte(fmt.Sprintf("MASTER_MNEMONIC=%s\nVALIDATOR_ADDR_MNEMONIC=%s\nVALIDATOR_NODE_MNEMONIC=%s\nVALIDATOR_NODE_ID=%s\nVALIDATOR_VAL_MNEMONIC=%s\nSIGNER_ADDR_MNEMONIC=%s\n ", masterMnemonic, mnemonicSet.ValidatorAddrMnemonic, mnemonicSet.ValidatorNodeMnemonic, mnemonicSet.ValidatorNodeId, mnemonicSet.ValidatorValMnemonic, mnemonicSet.SignerAddrMnemonic))

			err = createMnemonicsFile(fmt.Sprintf("%s/mnemonics.env", masterkeys), dataToWrite)
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				return mnemonicSet, err
			}
			dataToWrite = []byte{}

		}

	}
	return mnemonicSet, nil
}
