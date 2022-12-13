package main

import (
	"github.com/kiracore/tools/bip39saifu/cmd"
)

const Bip39GenVersion = "v0.2.19"

func main() {
	//EB = (mnemonic_words_count / 3) * 32                                 //entropy bits
	//ME = (11 * mnemonic_words_count) - ((mnemonic_words_count / 3) * 32) //missing entropy bits

	cmd.Execute()

}
