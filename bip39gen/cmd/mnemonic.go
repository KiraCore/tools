package cmd

import (
	"crypto/sha256"
	"crypto/sha512"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/kiracore/tools/bip39gen/pkg/bip39"
	"github.com/spf13/cobra"
)

var (
	errBinary     error = errors.New("input should contain 1s and 0s")
	errHex        error = errors.New("input should comply with hexadecimal format")
	errWordLength error = errors.New("there should be 0 < words <= 768, and devisable by 3")
	colors              = bip39.NewColors()
)

// validateLengthFlagInput checks if the provided length is valid.
func validateLengthFlagInput(length int) error {
	if length <= 0 || length%3 != 0 || length > 768 {
		return errWordLength
	}
	return nil
}
func validateLengthEntropyInput(str string) error {
	if len(str) == 0 {
		return nil
	}

	if (words/3)*32 != len(str) {
		err := errors.New(fmt.Sprintf("human provided entropy has insufficient length, expected %v bits but supplied only %v of entropy, your mnemonic is NOT secure. You can specify a cipher flag to extrapolate your input.", (words/3)*32, len(str)))
		return err
	}
	return nil

}

// validateEntropyFlagInput checks if the provided entropy string is valid.
func validateEntropyFlagInput(str string) error {
	if len(str) == 0 {
		return nil
	}

	match, _ := regexp.MatchString("^[0-1]+$", str)
	if !match {
		return errBinary
	}

	return nil
}

// validateHexEntropyFlagInput checks if the provided hex entropy string is valid.
func validateHexEntropyFlagInput(str string) error {
	if len(str) > 0 {
		match, _ := regexp.MatchString("(?:0[xX])?[0-9a-fA-F]+", str)
		if !match {
			return errHex
		}
	}

	return nil
}

// Check if string contain hex or binary prefix and return string without it
func checkInputPrefix(str string) (string, error) {
	if len(str) > 2 {
		switch str[0:2] {
		case "0x":
			if err := validateHexEntropyFlagInput(str[2:]); err != nil {
				return "", err
			}
			return strings.TrimSpace(str[2:]), nil
		case "0b":
			if err := validateEntropyFlagInput(str[2:]); err != nil {
				return "", err
			}
			return strings.TrimSpace(str[2:]), nil
		}
	}
	return str, nil
}
func processSHA256() error {
	hex = true
	if words != 24 {
		fmt.Println(colors.Print("Warning. With sha256 you can generate 24 words", 3))
		words = 24
	}
	sum := sha256.Sum256([]byte(userEntropy))

	userEntropy = string(sum[:])
	userEntropy = fmt.Sprintf("%x", userEntropy)

	if err := validateHexEntropyFlagInput(userEntropy); err != nil {
		return err
	}
	return nil
}

func processSHA512() error {
	hex = true
	if words != 48 {
		fmt.Println(colors.Print("Warning. With sha512 you can generate 48 words", 3))
		words = 48
	}
	sum := sha512.Sum512([]byte(userEntropy))

	// Flip bytes to string hex
	userEntropy = string(sum[:])
	userEntropy = fmt.Sprintf("%x", userEntropy)

	if err := validateHexEntropyFlagInput(userEntropy); err != nil {
		return err
	}
	return nil
}

// Deprecated
// func processChaCha20() error {
// 	hex = true
// 	if words != 24 {
// 		fmt.Println(colors.Print("Warning. With sha256 you can generate 24 words", 3))
// 		words = 24
// 	}

// 	// Generate a 256-bit key from the user-entered phrase using SHA-256
// 	key := sha256.Sum256([]byte(userEntropy))

// 	// Generate random nonce
// 	nonce := make([]byte, chacha20.NonceSize)
// 	if _, err := rand.Read(nonce); err != nil {
// 		panic(err)
// 	}

// 	// Generate random plaintext (32 bytes) to be encrypted using ChaCha20
// 	plaintext := make([]byte, 32)
// 	if _, err := rand.Read(plaintext); err != nil {
// 		panic(err)
// 	}

// 	// Encrypt plaintext using ChaCha20
// 	cipher, err := chacha20.NewUnauthenticatedCipher(key[:], nonce)
// 	if err != nil {
// 		panic(err)
// 	}
// 	ciphertext := make([]byte, len(plaintext))
// 	cipher.XORKeyStream(ciphertext, plaintext)

// 	// Use the first 256 bits of the ciphertext as entropy for BIP39
// 	entropy := ciphertext[:32]

// 	userEntropy = fmt.Sprintf("%x", entropy)
// 	fmt.Fprintf(os.Stdout, "Key: %x\n", key)
// 	fmt.Fprintf(os.Stdout, "Nonce(HEX): %x\n", nonce)
// 	fmt.Fprintf(os.Stdout, "Ciphertex(HEX): %x\n", ciphertext)
// 	mnemonic, err := bip39c.NewMnemonic(entropy)
// 	fmt.Fprintf(os.Stdout, "Mnemonic: %v\n", mnemonic)
// 	return nil
// }

func processPadding() error {
	hex = false
	if err := validateEntropyFlagInput(rawEntropy); err != nil {
		return err
	}
	bits := (words / 3) * 32
	bitsEnt := len(rawEntropy)
	for i := bitsEnt; i <= bits; i++ {
		rawEntropy += "0"
	}
	return nil
}

// cmdMnemonicPreRun validates the provided flags and sets the required variables.
func cmdMnemonicPreRun(cmd *cobra.Command, args []string) error {

	userEntropy, err := checkInputPrefix(userEntropy)
	if err != nil {
		return err
	}
	rawEntropy, err := checkInputPrefix(rawEntropy)
	if err != nil {
		return err
	}

	input := []string{userEntropy, rawEntropy}

	if err := validateLengthFlagInput(words); err != nil {
		return err
	}

	if (len(userEntropy) > 0 || len(rawEntropy) > 0) && len(cipher) == 0 {

		for _, i := range input {
			switch hex {
			case true:
				if err := validateHexEntropyFlagInput(i); err != nil {
					return err
				}

			case false:
				if err := validateEntropyFlagInput(i); err != nil {
					return err
				}
				err := validateLengthEntropyInput(i)
				if err != nil {
					return err
				}

			}

		}

	}
	if (len(userEntropy) > 0 || len(rawEntropy) > 0) && len(cipher) != 0 {
		switch cipher {
		case "sha256":
			if err := processSHA256(); err != nil {
				return err
			}
		case "sha512":
			if err := processSHA512(); err != nil {
				return err
			}

			// Deprecated
			// case "chacha20":
			// 	if err := processChaCha20(); err != nil {
			// 		return err
			// 	}

		case "padding":
			if err := processPadding(); err != nil {
				return err
			}
		}
	}

	return nil
}

// cmdMnemonic generates a new mnemonic and prints it.
func cmdMnemonic(cmd *cobra.Command, args []string) error {

	mnemonic := NewMnemonic()
	mnemonic.Print(verbose)

	return nil

}

// NewMnemonic creates a new mnemonic based on the provided flags.
func NewMnemonic() bip39.Mnemonic {
	var m bip39.Mnemonic = bip39.Mnemonic{}

	if userEntropy != "" {
		return m.SetStringType(&hex).SetUserEntropy(&userEntropy).Generate()
	}
	if rawEntropy != "" {
		return m.SetStringType(&hex).SetRawEntropy(&rawEntropy).Generate()
	}
	return m.SetStringType(&hex).SetRandomEntropy(words).Generate()
}
