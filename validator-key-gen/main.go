package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"strings"

	"github.com/cosmos/cosmos-sdk/crypto/hd"
	"github.com/cosmos/go-bip39"
	"github.com/tendermint/tendermint/crypto/ed25519"
	"github.com/tendermint/tendermint/p2p"
	"github.com/tendermint/tendermint/privval"
)

const (
	PrivValidatorKeyGenVersion = "v0.3.16"
	charset                    = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
	separator                  = "1"
)

var generator = []int{0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3}

// errors
var (
	NoAdrErr    error = errors.New("address can't be empty")
	NoSepErr    error = errors.New("separator not found. Default value '1'")
	WrongSetErr error = errors.New("data doesn't match bech39 charset. the address is corrupted")
)

func BreakDownAddress(addr string) (prefix string, data string) {
	var (
		sepIndex int
	)
	for i, r := range addr {
		if string(r) == separator {
			sepIndex = i
			break
		}
	}

	if sepIndex == 0 {
		panic(NoSepErr)
	}

	data = strings.Join(strings.Split(addr, "")[sepIndex+1:], "")
	prefix = strings.Join(strings.Split(addr, "")[:sepIndex], "")
	return prefix, data

}
func ValidateAddress(address string) bool {
	_, d := BreakDownAddress(address)
	r, _ := regexp.Compile(fmt.Sprintf("([%s]+)", charset))
	for _, v := range d {
		if !r.MatchString(string(v)) {
			return false
		}
	}
	return true
}

func polymod(values []int) int {
	chk := 1
	for _, v := range values {
		top := chk >> 25
		chk = (chk&0x1ffffff)<<5 ^ v
		for i := 0; i < 5; i++ {
			if (top>>uint(i))&1 == 1 {
				chk ^= generator[i]
			}
		}
	}
	return chk
}

func verifyChecksum(hrp string, data []int) bool {
	return polymod(append(hrpExpand(hrp), data...)) == 1
}

func hrpExpand(hrp string) []int {
	ret := []int{}
	for _, c := range hrp {
		ret = append(ret, int(c>>5))
	}
	ret = append(ret, 0)
	for _, c := range hrp {
		ret = append(ret, int(c&31))
	}
	return ret
}

func Encode(hrp string, data []int) (string, error) {
	if (len(hrp) + len(data) + 7) > 90 {
		return "", fmt.Errorf("too long : hrp length=%d, data length=%d", len(hrp), len(data))
	}
	if len(hrp) < 1 {
		return "", fmt.Errorf("invalid hrp : hrp=%v", hrp)
	}
	for p, c := range hrp {
		if c < 33 || c > 126 {
			return "", fmt.Errorf("invalid character human-readable part : hrp[%d]=%d", p, c)
		}
	}
	if strings.ToUpper(hrp) != hrp && strings.ToLower(hrp) != hrp {
		return "", fmt.Errorf("mix case : hrp=%v", hrp)
	}
	lower := strings.ToLower(hrp) == hrp
	hrp = strings.ToLower(hrp)
	combined := append(data, createChecksum(hrp, data)...)
	var ret bytes.Buffer
	ret.WriteString(hrp)
	ret.WriteString("1")
	for idx, p := range combined {
		if p < 0 || p >= len(charset) {
			return "", fmt.Errorf("invalid data : data[%d]=%d", idx, p)
		}
		ret.WriteByte(charset[p])
	}
	if lower {
		return ret.String(), nil
	}
	return strings.ToUpper(ret.String()), nil
}

func Decode(bechString string) (string, []int, error) {
	if len(bechString) > 90 {
		return "", nil, fmt.Errorf("too long : len=%d", len(bechString))
	}
	if strings.ToLower(bechString) != bechString && strings.ToUpper(bechString) != bechString {
		return "", nil, fmt.Errorf("mixed case")
	}
	bechString = strings.ToLower(bechString)
	pos := strings.LastIndex(bechString, "1")
	if pos < 1 || pos+7 > len(bechString) {
		return "", nil, fmt.Errorf("separator '1' at invalid position : pos=%d , len=%d", pos, len(bechString))
	}
	hrp := bechString[0:pos]
	for p, c := range hrp {
		if c < 33 || c > 126 {
			return "", nil, fmt.Errorf("invalid character human-readable part : bechString[%d]=%d", p, c)
		}
	}
	data := []int{}
	for p := pos + 1; p < len(bechString); p++ {
		d := strings.Index(charset, fmt.Sprintf("%c", bechString[p]))
		if d == -1 {
			return "", nil, fmt.Errorf("invalid character data part : bechString[%d]=%d", p, bechString[p])
		}
		data = append(data, d)
	}
	if !verifyChecksum(hrp, data) {
		return "", nil, fmt.Errorf("invalid checksum")
	}
	return hrp, data[:len(data)-6], nil
}

func createChecksum(hrp string, data []int) []int {
	values := append(append(hrpExpand(hrp), data...), []int{0, 0, 0, 0, 0, 0}...)
	mod := polymod(values) ^ 1
	ret := make([]int, 6)
	for p := 0; p < len(ret); p++ {
		ret[p] = (mod >> uint(5*(5-p))) & 31
	}
	return ret
}

func main() {

	mnemonic := flag.String("mnemonic", "", "a string")
	valkey := flag.String("valkey", "", "a string")
	nodekey := flag.String("nodekey", "", "a string")
	keyid := flag.String("keyid", "", "a string")

	// Derive path from string
	derive := flag.String("derive", "", "a string")
	path := flag.String("path", "", "a string")
	prefix := flag.String("prefix", "", "a string") 

	// Decode/verify kira address
	validate := flag.Bool("validate", false, "a bool")
	decode := flag.Bool("decode", false, "a bool")
	encode := flag.Bool("encode", false, "a bool")
	address := flag.String("address", "", "an address in bech32 format, string")

	// {m / purpose' / coin_type' / account' / change / address_index}
	const (
		purpose  = 0x8000002C // Constant. Set to 44
		coinType = 0x80000402 // Registred coin type from https://github.com/satoshilabs/slips/blob/master/slip-0044.md
	)

	var version bool
	flag.BoolVar(&version, "version", false, "prints current version and exits")

	flag.Parse()

	if version {
		fmt.Print(PrivValidatorKeyGenVersion)
		return
	}
	//w, err := hd.NewParamsFromPath(*path)
	//if err != nil {
	//	fmt.Errorf("path is not correct or can't be parsed")
	//}
	// Default value for path flag

	if *validate {
		if *address != "" {
			_, _, err := Decode(*address)
			if err != nil {
				panic(err)
			}
			fmt.Println("Address is valid ", *address)
		} else {
			os.Exit(1)
		}

		os.Exit(0)
	}

	if *decode {
		if *address != "" {
			p, d, err := Decode(*address)
			if err != nil {
				panic(err)
			}
			fmt.Println(p, d)
			os.Exit(0)
		} else {
			os.Exit(1)
		}

	}

	if *encode {
		if *address != "" {
			if *prefix != "" {
				_, d, err := Decode(*address)
				if err != nil {
					panic(err)
				}
				newAdr, err := Encode(*prefix, d)
				fmt.Println("Envaluated address: ", newAdr)
				os.Exit(0)

			} else {
				os.Exit(1)
			}

		} else {
			os.Exit(1)
		}

	}
	if len(*path) == 0 {
		*path = "44'/118'/0'/0/0"
	}

	// Default value for derive flag
	if len(*derive) == 0 {
		*derive = "bip44"
	}

	// Default value for prefix flag
	if len(*prefix) == 0 {
		*prefix = "kira"
	}

	if len(*mnemonic) == 0 {
		fmt.Println("mnemonic not set!")
		return
	}

	master, ch := hd.ComputeMastersFromSeed(bip39.NewSeed(*mnemonic, ""))
	priv, err := hd.DerivePrivateKeyForPath(master, ch, *path)
	fmt.Printf("master key: %s%x\n", *prefix, master)
	if err != nil {
		panic(err)
	}

	privKey := ed25519.GenPrivKeyFromSecret(priv)
	filepvkey := privval.NewFilePV(privKey, *valkey, "").Key
	filenodekey := p2p.NodeKey{
		PrivKey: privKey,
	}

	if len(*valkey) != 0 {
		filepvkey.Save()
	}
	if len(*nodekey) != 0 {
		err = filenodekey.SaveAs(*nodekey)
		if err != nil {
			panic(err)
		}
	}
	if len(*keyid) != 0 {
		err = ioutil.WriteFile(*keyid, []byte(filenodekey.ID()), 0644)
		if err != nil {
			panic(err)
		}
	}
}
