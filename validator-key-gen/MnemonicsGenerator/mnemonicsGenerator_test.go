package mnemonicsgenerator_test

import (
	"fmt"
	"os"
	"reflect"
	"testing"

	mnemonicsgenerator "github.com/PeepoFrog/validator-key-gen/MnemonicsGenerator"
)

// Test mnemonic:
//
// MASTER_MNEMONIC=bargain erosion electric skill extend aunt unfold cricket spice sudden insane shock purpose trumpet holiday tornado fiction check pony acoustic strike side gold resemble
// VALIDATOR_ADDR_MNEMONIC=result tank riot circle cost hundred exotic soft angle bulb sunset margin virus simple bean topic next initial embody sample ordinary what pulp engage
// VALIDATOR_NODE_MNEMONIC=shed history misery describe sail sight know snake route humor soda gossip lonely torch state drama salmon jungle possible lock runway wild cross tank
// VALIDATOR_NODE_ID=935ea41280fa8754a35bd2916d935f222b559488
// VALIDATOR_VAL_MNEMONIC=stick about junk liberty same envelope boy machine zoo wide shrimp clutch oval mango diary strike round divorce toilet cross guard appear govern chief
// SIGNER_ADDR_MNEMONIC=near spirit dial february access song panda clean diesel legend clock remind name pupil drum general trap afford tuition side dune address alpha stool

// files to test:

// cat node_key.json
// {"priv_key":{"type":"tendermint/PrivKeyEd25519","value":"XI+eMf0mqqX5a07cAgxBWpLKq8AicMETxQQoLIhxBw1u8GRu0kGFZ2jPpJhwp/aEUL9dPaGZ5taNaQFA0i8cMA=="}}

// cat priv_validator_key.json && echo
// {
//   "address": "47E4C09C2BF5782B634BF393D394464BE08728A7",
//   "pub_key": {
//     "type": "tendermint/PubKeyEd25519",
//     "value": "jNh+yX/KQRAON8KnwI+fawpRcKpUFyqolEn4dAaESNI="
//   },
//   "priv_key": {
//     "type": "tendermint/PrivKeyEd25519",
//     "value": "OYqWRyEl48LdMSihUM3f2pv9LARabDZeeqmUqXejOzSM2H7Jf8pBEA43wqfAj59rClFwqlQXKqiUSfh0BoRI0g=="
//   }
// }

// cat validator_node_id.key
// 935ea41280fa8754a35bd2916d935f222b559488

const masterMnemonicForTest string = "bargain erosion electric skill extend aunt unfold cricket spice sudden insane shock purpose trumpet holiday tornado fiction check pony acoustic strike side gold resemble"

var (
	nodeKeyForTest string = `{"priv_key":{"type":"tendermint/PrivKeyEd25519","value":"XI+eMf0mqqX5a07cAgxBWpLKq8AicMETxQQoLIhxBw1u8GRu0kGFZ2jPpJhwp/aEUL9dPaGZ5taNaQFA0i8cMA=="}}`

	privValdatorKeyTest string = `{
  "address": "47E4C09C2BF5782B634BF393D394464BE08728A7",
  "pub_key": {
    "type": "tendermint/PubKeyEd25519",
    "value": "jNh+yX/KQRAON8KnwI+fawpRcKpUFyqolEn4dAaESNI="
  },
  "priv_key": {
    "type": "tendermint/PrivKeyEd25519",
    "value": "OYqWRyEl48LdMSihUM3f2pv9LARabDZeeqmUqXejOzSM2H7Jf8pBEA43wqfAj59rClFwqlQXKqiUSfh0BoRI0g=="
  }
}`

	wantedMnemonicSet mnemonicsgenerator.MasterMnemonicSet = mnemonicsgenerator.MasterMnemonicSet{
		ValidatorAddrMnemonic: []byte("result tank riot circle cost hundred exotic soft angle bulb sunset margin virus simple bean topic next initial embody sample ordinary what pulp engage"),
		ValidatorNodeMnemonic: []byte("shed history misery describe sail sight know snake route humor soda gossip lonely torch state drama salmon jungle possible lock runway wild cross tank"),
		ValidatorValMnemonic:  []byte("stick about junk liberty same envelope boy machine zoo wide shrimp clutch oval mango diary strike round divorce toilet cross guard appear govern chief"),
		SignerAddrMnemonic:    []byte("near spirit dial february access song panda clean diesel legend clock remind name pupil drum general trap afford tuition side dune address alpha stool"),
		ValidatorNodeId:       []byte("935ea41280fa8754a35bd2916d935f222b559488"),
		PrivKeyMnemonic:       []byte("trash conduct welcome seek people duty enter monkey turtle holiday husband recall iron check gorilla bottom amused clump glue culture kidney news umbrella cancel"),
	}
)

// This test excludes PrivKeyMnemonic to check if func return the proper origin mnemonics from original tool
func TestMasterKeysGenWithOutPrivKeyMnemonic(t *testing.T) {
	got, err := mnemonicsgenerator.MasterKeysGen([]byte(masterMnemonicForTest), mnemonicsgenerator.DefaultPrefix, mnemonicsgenerator.DefaultPath, "")
	if err != nil {
		t.Errorf("MasterKeysGen(%+s)\n error = %v", masterMnemonicForTest, err)
		return
	}
	switch {
	case string(wantedMnemonicSet.ValidatorAddrMnemonic) != string(got.ValidatorAddrMnemonic):
		t.Errorf("wrong mnemonic: %v", string(got.ValidatorValMnemonic))
	case string(wantedMnemonicSet.ValidatorNodeMnemonic) != string(got.ValidatorNodeMnemonic):
		t.Errorf("wrong mnemonic: %v", string(got.ValidatorNodeMnemonic))
	case string(wantedMnemonicSet.ValidatorValMnemonic) != string(got.ValidatorValMnemonic):
		t.Errorf("wrong mnemonic: %v", string(got.ValidatorValMnemonic))
	case string(wantedMnemonicSet.SignerAddrMnemonic) != string(got.SignerAddrMnemonic):
		t.Errorf("wrong mnemonic: %v", string(got.SignerAddrMnemonic))
	case string(wantedMnemonicSet.ValidatorNodeId) != string(got.ValidatorNodeId):
		t.Errorf("wrong mnemonic: %v", string(got.ValidatorNodeId))
	}
}

func TestMasterKeysGen(t *testing.T) {
	mnemonicSetTest := []struct {
		name           string
		masterMnemonic []byte
		want           mnemonicsgenerator.MasterMnemonicSet
		wantErr        bool
	}{
		{
			name:           "working mnemonic",
			masterMnemonic: []byte(masterMnemonicForTest),
			want:           wantedMnemonicSet,
			wantErr:        false,
		},
	}
	tmpFolder := os.TempDir()
	for _, tt := range mnemonicSetTest {
		t.Run(tt.name, func(t *testing.T) {
			got, err := mnemonicsgenerator.MasterKeysGen(tt.masterMnemonic, mnemonicsgenerator.DefaultPrefix, mnemonicsgenerator.DefaultPath, tmpFolder)
			if (err != nil) != tt.wantErr {
				t.Errorf("MasterKeysGen(%+s)\n error = %v\n wantErr %v\n", string(tt.masterMnemonic), err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("ProcessData(%s) = %+v\n want %+v", string(tt.masterMnemonic), got, tt.want)
			}
		})
	}

	keyFileTest := []struct {
		name       string
		fileName   string
		wantedData string
		wantErr    bool
	}{
		{
			name:       mnemonicsgenerator.DefaultValidatorNodeKeyFileName,
			fileName:   fmt.Sprintf("%s/%s", tmpFolder, mnemonicsgenerator.DefaultValidatorNodeKeyFileName),
			wantedData: nodeKeyForTest,
			wantErr:    false,
		},
		{
			name:       mnemonicsgenerator.DefaultPrivValidatorKeyFileName,
			fileName:   fmt.Sprintf("%s/%s", tmpFolder, mnemonicsgenerator.DefaultPrivValidatorKeyFileName),
			wantedData: privValdatorKeyTest,
			wantErr:    false,
		},
	}

	for _, tt := range keyFileTest {

		out, err := os.ReadFile(tt.fileName)
		if (err != nil) != tt.wantErr {
			t.Errorf("unable to read %s file, error = %v", tt.fileName, err)
			return
		}
		if string(out) != tt.wantedData {
			t.Errorf("wrong key\nExpected: %v\nReceived: %v", []byte(tt.wantedData), out)
		}

	}
}

func TestDerivePrivKeyMnemonicFromMasterMnemonic(t *testing.T) {
	privKeyMnemonic, err := mnemonicsgenerator.DerivePrivKeyMnemonicFromMasterMnemonic([]byte(masterMnemonicForTest))
	if err != nil {
		t.Errorf("unable to derive privKey mnemonic from <%s>, error: %v", masterMnemonicForTest, err)
	}
	if string(privKeyMnemonic) != string(wantedMnemonicSet.PrivKeyMnemonic) {
		t.Errorf("derived privKey mnemonic is not equal to wanted mnemonic\nGot: %s\nWanted:%s", privKeyMnemonic, wantedMnemonicSet.PrivKeyMnemonic)
	}
}
