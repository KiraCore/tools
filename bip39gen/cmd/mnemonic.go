package cmd

import (
	"errors"
	"fmt"
	"regexp"
    "crypto/sha256"
	"crypto/sha512"
	"golang.org/x/crypto/chacha20poly1305"
  
	"github.com/kiracore/tools/bip39gen/pkg/bip39"
	"github.com/spf13/cobra"
)

var (
	errEntropyLength    error = errors.New(fmt.Sprintf("human provided entropy has insufficient length, expected %v bits but got only %v, your mnemonic is NOT secure. You can specify a cipher flag to extrapolate your input.", (words/3)*32, len(userEntropy)))
	errBinary     		error = errors.New("input should contain 1s and 0s")
	errHex        		error = errors.New("input should comply with hexadecimal format")
	errWordLength 		error = errors.New("there should be 0 < words <= 768, and devisable by 3")
)

func validateLengthFlagInput(length int) error {
	if length <= 0 || length%3 != 0 || length > 768 {
		return errWordLength
	}
	return nil
}

func validateEntropyFlagInput(str string) error {
	if len(str) > 0 {
		match, _ := regexp.MatchString("[01]+", str)
		if !match {
			return errBinary
		}
	}
	return nil
}

func validateHexEntropyFlagInput(str string) error {
	if len(str) > 0 {
		match, _ := regexp.MatchString("(?:0[xX])?[0-9a-fA-F]+", str)
		if !match {
			return errHex
		}
	}

	return nil
}

func cmdMnemonic(cmd *cobra.Command, args []string) error {
	if err := validateLengthFlagInput(words); err != nil {
		return err
	}
	
	fmt.Printf("User entropy: '%s'\n", userEntropy)

	input := []string{userEntropy, rawEntropy}

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
		}

	}
	if len(userEntropy) > 0 {
		fmt.Println("here")
		if (words/3)*32 != len(userEntropy) && len(cipher) == 0{
			if hex {
				fmt.Println("Words: ",(words/3)*32)
				fmt.Println("len(userEntropy): ",len(userEntropy))
			}
			
			err := errEntropyLength
			return err
		} 
		if (words/3)*32 != len(userEntropy) && len(cipher) > 0{
			switch cipher{
			case "sha256":
				hex = true
				sum := sha256.Sum256([]byte(userEntropy))
				userEntropy = fmt.Sprintf("%x",sum)

			case "sha512":
				hex = true
				sum := sha512.Sum512([]byte(userEntropy))
				userEntropy = fmt.Sprintf("%x",sum)

			case "chacha20":
				hex = true
				sum := sha256.Sum256([]byte(userEntropy))

				userEntropy=string(sum[:])

				userEntropy=fmt.Sprintf("%x", userEntropy)

				aead, _ := chacha20poly1305.NewX(sum[:])

				mnemonic := NewMnemonic()
				msg:=mnemonic.String()
				
				nonce := make([]byte, chacha20poly1305.NonceSizeX)
				ciphertext := aead.Seal(nil, nonce, []byte(msg), nil)

				fmt.Printf("Cipher stream: %x\n", ciphertext)

				mnemonic.Print(verbose)
				return nil
				
			case "padding":
				fmt.Print("dummy")
			}

		} 

	}

	mnemonic := NewMnemonic()

	mnemonic.Print(verbose)
	return nil
}

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
