package main

import (
	"bytes"
	"os"
	"strings"
	"testing"
)

// func TestAccAdr(t *testing.T) {
// 	t.Parallel()
// 	os.Args = []string{
// 		"./validator-key-gen",
// 		"-mnemonic",
// 		"over where supreme taste warrior morning perfect memory glove stereo taste trip sheriff fringe weather finger segment under arrange gain warrior olympic urge vacant",
// 		"-accadr",
// 	}
// 	out = bytes.NewBuffer(nil)
// 	want := "kira103luqf09g5juctmvrmgnw5gmn2mhpelqhcsy84"
// 	main()
// 	if actual := out.(*bytes.Buffer).String(); strings.TrimSpace(actual) != want {
// 		t.Errorf("expected %s, but got %s", want, actual)
// 	}
// }

func TestValAdr(t *testing.T) {
	t.Parallel()
	os.Args = []string{
		"./validator-key-gen",
		"-mnemonic",
		"over where supreme taste warrior morning perfect memory glove stereo taste trip sheriff fringe weather finger segment under arrange gain warrior olympic urge vacant",
		"-valadr",
	}
	out = bytes.NewBuffer(nil)
	want := "kiravaloper103luqf09g5juctmvrmgnw5gmn2mhpelqy7v8le"
	main()
	if actual := out.(*bytes.Buffer).String(); strings.TrimSpace(actual) != want {
		t.Errorf("expected %s, but got %s", want, actual)
	}
}

// func TestConsAdr(t *testing.T) {
// 	t.Parallel()
// 	os.Args = []string{
// 		"./validator-key-gen",
// 		"-mnemonic",
// 		"over where supreme taste warrior morning perfect memory glove stereo taste trip sheriff fringe weather finger segment under arrange gain warrior olympic urge vacant",
// 		"-consadr",
// 	}
// 	out = bytes.NewBuffer(nil)
// 	want := "kiravalcons103luqf09g5juctmvrmgnw5gmn2mhpelqsdlmnc"
// 	main()
// 	if actual := out.(*bytes.Buffer).String(); strings.TrimSpace(actual) != want {
// 		t.Errorf("expected %s, but got %s", want, actual)
// 	}
// }
