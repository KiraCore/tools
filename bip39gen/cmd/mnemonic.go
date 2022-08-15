package cmd

import (
	"errors"
	"fmt"
	"regexp"

	"github.com/kiracore/tools/bip39saifu/pkg/bip39"
	"github.com/spf13/cobra"
)

var (
	//errWrongLength         error = errors.New("length should be devisable by 32")
	errBinaryViolation     error = errors.New("input should contain1s and 0s")
	errHexViolation        error = errors.New("input should comply with hexadecimal format")
	errWordLengthViolation error = errors.New("there should be 0 < words <= 768, and devisable by 3")
)

func validateLengthFlagInput(length int) error {
	if length <= 0 || length%3 != 0 || length > 768 {
		return errWordLengthViolation
	}
	return nil
}

func validateEntropyFlagInput(str string) error {
	if len(str) > 0 {
		match, _ := regexp.MatchString("[01]+", str)
		if !match {
			return errBinaryViolation
		}
	}

	return nil
}

func validateHexEntropyFlagInput(str string) error {
	if len(str) > 0 {
		match, _ := regexp.MatchString("(?:0[xX])?[0-9a-fA-F]+", str)
		if !match {
			return errHexViolation
		}
	}

	return nil
}

func cmdMnemonic(cmd *cobra.Command, args []string) error {
	if err := validateLengthFlagInput(words); err != nil {
		return err
	}

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
		if (words*32)/8 != len(userEntropy) {
			fmt.Printf("\x1b[48;5;226mWARNING!\x1b[00m Human provided entropy has insufficient length, expected %v bits, your mnemonic is NOT secure!\n", (words/3)*32)
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
