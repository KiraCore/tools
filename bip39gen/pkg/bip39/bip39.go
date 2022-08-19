package bip39

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"hash"
	"log"
	"strconv"
	"strings"
)

const BITS = 8

type Info struct {
	randEnt   []string
	userEnt   []string
	rawEnt    []string
	dec       []string
	words     []string
	mw        string // mnemonic words
	eb        string // entropy bits
	cb        string // checksum bits
	ceHex     string // computer entropy hex
	heHex     string // human entropy hex
	reHex     string // resulting entropy hex
	reHashHex string // resulting entropy hash
	rcBin     string // resulting checksum (*printed in red*)
}

func (i *Info) Parse(m *Mnemonic) {
	var chkBits int
	var padding []byte
	chkBits = (len(m.rawEntropy) * 8) / 32
	i.cb = strconv.Itoa(chkBits)
	i.mw = strconv.Itoa(len(m.words))
	i.eb = strconv.Itoa(len(m.rawEntropy) * 8)
	i.ceHex = hex.EncodeToString(m.randEntropy)
	i.heHex = hex.EncodeToString(m.userEntropy)
	i.reHex = hex.EncodeToString(m.rawEntropy)
	i.reHashHex = hex.EncodeToString(m.hash)
	i.rcBin = BitSliceToString(m.checksumBits)

	padding = make([]byte, chkBits)

	for w := 0; w < len(m.words); w++ {
		i.words = append(i.words, m.words[w])
		i.dec = append(i.dec, strconv.Itoa(GetWordIndex(m.words[w])))
	}

	i.randEnt = BitSliceToStringSliceColored(append(ByteSliceToBitSlice(m.randEntropy), m.checksumBits...), 11, chkBits)
	switch len(m.userEntropy) > 0 {
	case true:
		i.userEnt = BitSliceToStringSlice(append(ByteSliceToBitSlice(m.userEntropy), padding...), 11)
	case false:
		arr := make([]byte, len(m.rawEntropy))
		i.userEnt = BitSliceToStringSliceColored(append(ByteSliceToBitSlice(arr), padding...), 11, chkBits)
	}

	i.rawEnt = BitSliceToStringSliceColored(append(ByteSliceToBitSlice(m.rawEntropy), m.checksumBits...), 11, chkBits)

}

func (i *Info) Print() {
	PrintLine(92, "=")
	fmt.Printf("            Mnemonic words: %v\n", i.mw)
	fmt.Printf("              Entropy Bits: %v\n", i.eb)
	fmt.Printf("             Checksum Bits: %v\n", i.cb)
	fmt.Printf("    Computer Entropy (hex): %v\n", i.ceHex)
	fmt.Printf("       Human Entropy (hex): %v\n", i.heHex)
	fmt.Printf("   Resulting Entropy (hex): %v\n", i.reHex)
	fmt.Printf("Resulting Entropy (SHA256): %v\n", i.reHashHex)
	fmt.Printf("  Resulting Checksum (bin): %v\n", colors.Print(i.rcBin, 1))
	PrintLine(92, "=")
	fmt.Println("NR.\t  COMPUTER\t HUMAN\t\tBIN\t   DEC\t BIP39 WORD\t")
	for n, v := range i.words {
		fmt.Printf("%v.\t%11v%v%v%v%v%v%v\t%v%v\t\n",
			n+1,
			i.randEnt[n],
			" ⊕ ",
			i.userEnt[n],
			" = ",
			i.rawEnt[n],
			" -> ",
			i.dec[n],
			" -> ",
			v,
		)
	}
	PrintLine(92, "=")
	fmt.Println("Mnemonic words: ")
	fmt.Println(strings.Join(i.words, " "))
	fmt.Println()

}

func GetWordIndex(word string) int {
	idx := ReverseWordMap[word]
	return idx
}

// Returns SHA256 hash of given byte slice
func GenHashFromByteSlice(bytes []byte) []byte {
	var hasher hash.Hash
	var hash []byte

	hasher = sha256.New()
	_, _ = hasher.Write(bytes)
	hash = hasher.Sum(nil)

	return hash
}

// Apply XOR on two given slices. Returns resulting slice
func XOROnSlices(array1 []byte, array2 []byte) []byte {
	var bytes int = len(array1)
	var xorArray []byte = make([]byte, bytes)

	for i := 0; i < bytes; i++ {
		xorArray[i] = array1[i] ^ array2[i]
	}
	return xorArray
}

// Converts bit string to byte slice
func BitStringToByte(bitString string) []byte {
	var src []byte = []byte(bitString)
	var dst []byte = make([]byte, len(src)/8)
	var bitMask byte = 1
	bitCounter := 0
	for b := 0; b < len(bitString)/8; b++ {
		for bit := 0; bit < 8; bit++ {
			dst[b] |= (src[bitCounter] & bitMask) << (7 - bit)
			bitCounter++
		}
	}

	return dst
}
func HexStringToByte(hexString string) []byte {
	var dst []byte
	var err error
	dst, err = hex.DecodeString(hexString)
	if err != nil {
		log.Fatalln("failed to decode hex string")
	}
	return dst
}

func ByteSliceToBitSlice(byteSlice []byte) []byte {
	var res []byte
	var b byte
	for _, v := range byteSlice {
		for bit := 7; bit >= 0; bit-- {
			b = v & (1 << bit) >> bit
			res = append(res, b)
		}

	}
	return res
}
func ByteSliceToString(byteSlice []byte) string {
	var str string
	for _, v := range ByteSliceToBitSlice(byteSlice) {
		str = str + strconv.Itoa(int(v))
	}
	return str
}
func BitSliceToString(bitSlice []byte) string {
	var str string
	for _, v := range bitSlice {
		str = str + strconv.Itoa(int(v))
	}
	return str

}
func BitSliceToStringSliceColored(bitSlice []byte, bitSize int, bit int) []string {
	var str []string
	for b := 0; b < len(bitSlice)/bitSize; b++ {
		var s string
		for i := b * bitSize; i < (b+1)*bitSize; i++ {
			switch i >= len(bitSlice)-bit {
			case true:
				s = s + "\x1b[48;5;1m" + strconv.Itoa(int(bitSlice[i])) + "\x1b[00m"

			default:
				s = s + strconv.Itoa(int(bitSlice[i]))
			}

		}
		str = append(str, s)
	}

	return str
}
func BitSliceToStringSlice(bitSlice []byte, bitSize int) []string {
	var str []string
	for b := 0; b < len(bitSlice)/bitSize; b++ {
		var s string
		for i := b * bitSize; i < (b+1)*bitSize; i++ {
			s = s + strconv.Itoa(int(bitSlice[i]))
		}
		str = append(str, s)
	}

	return str
}

type Mnemonic struct {
	words           map[int]string
	userEntropy     []byte
	rawEntropy      []byte
	randEntropy     []byte
	hash            []byte
	checksumBits    []byte
	combinedEntropy []byte
	hex             bool
}

func (m *Mnemonic) SetStringType(hex *bool) *Mnemonic {
	m.hex = *hex
	return m
}
func (m *Mnemonic) GetStringType() bool {
	return m.hex
}

func (m *Mnemonic) SetUserEntropy(entropy *string) *Mnemonic {
	switch m.GetStringType() {
	case true:
		m.userEntropy = HexStringToByte(*entropy)
		m.randEntropy = make([]byte, (len(m.userEntropy)))
		_, _ = rand.Read(m.randEntropy)
		m.rawEntropy = XOROnSlices(m.userEntropy, m.randEntropy)
	case false:
		m.userEntropy = BitStringToByte(*entropy)
		m.randEntropy = make([]byte, (len(m.userEntropy)))
		_, _ = rand.Read(m.randEntropy)
		m.rawEntropy = XOROnSlices(m.userEntropy, m.randEntropy)
	}

	return m
}
func (m *Mnemonic) SetRawEntropy(entropy *string) *Mnemonic {
	switch m.GetStringType() {
	case true:
		if len(*entropy) < 8 && len(*entropy) > 2112 {
			log.Fatalln("entropy can't be less than 8 hex chars or more than 2112 hex chars")
		}
		switch len(*entropy)%32 != 0 {

		case true:
			ent := string([]byte(*entropy)[:len(*entropy)-len(*entropy)%16])
			if len(ent)%8 != 0 {
				log.Fatalln("entropy should be devisable by 32")
			}
			m.rawEntropy = HexStringToByte(ent)
		case false:
			m.rawEntropy = HexStringToByte(*entropy)
		}

	case false:
		if len(*entropy) < 32 && len(*entropy) > 8448 {
			log.Fatalln("entropy can't be less than 32 bit or more than 8448 bit")
		}
		switch len(*entropy)%32 != 0 {
		case true:
			ent := string([]byte(*entropy)[:len(*entropy)-len(*entropy)%32])
			if len(ent)%32 != 0 {
				log.Fatalln("entropy should be devisable by 32")
			}
			m.rawEntropy = BitStringToByte(ent)
		case false:
			m.rawEntropy = BitStringToByte(*entropy)
		}

	}
	m.randEntropy = make([]byte, len(m.rawEntropy))
	m.userEntropy = make([]byte, len(m.rawEntropy))

	return m
}

func (m *Mnemonic) SetRandomEntropy(words int) *Mnemonic {
	m.randEntropy = make([]byte, ((words/3)*32)/8)
	_, _ = rand.Read(m.randEntropy)
	m.rawEntropy = m.randEntropy
	m.userEntropy = make([]byte, len(m.randEntropy))

	return m
}

func (m *Mnemonic) SetByteEntropy(ent []byte) *Mnemonic {
	m.rawEntropy = ent
	return m
}
func (m *Mnemonic) Generate() Mnemonic {

	m.hash = GenHashFromByteSlice(m.rawEntropy)
	var entropyAndChecksumBits []byte

	m.checksumBits = ByteSliceToBitSlice(m.hash)[:(len(m.rawEntropy)*8)/32]

	entropyAndChecksumBits = append(entropyAndChecksumBits, ByteSliceToBitSlice(m.rawEntropy)...)
	entropyAndChecksumBits = append(entropyAndChecksumBits, m.checksumBits...)

	m.combinedEntropy = entropyAndChecksumBits
	// Generate

	var wordMapInt map[int]int16 = make(map[int]int16, len(m.rawEntropy))

	wordList := make(map[int]string, len(m.rawEntropy))
	for i := 0; i < len(entropyAndChecksumBits)/11; i++ {
		leftShift := 10
		for n := i * 11; n < (i+1)*11; n++ {
			wordMapInt[i] |= int16(entropyAndChecksumBits[n]) << leftShift
			leftShift--
		}
	}
	for i, v := range wordMapInt {
		wordList[i] = WordList[v]
	}

	m.words = wordList

	return *m

}
func (m *Mnemonic) Print(v bool) {

	switch v {
	case false:
		fmt.Println(m.String())
	case true:
		var info Info
		info.Parse(m)
		info.Print()

	}
}
func (m *Mnemonic) String() string {
	stringList := []string{}
	for i := 0; i < len(m.words); i++ {

		stringList = append(stringList, m.words[i])
	}
	str := strings.Join(stringList, " ")
	return str
}
