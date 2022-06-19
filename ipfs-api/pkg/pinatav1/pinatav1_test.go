package pinatav1_test

import (
	"fmt"
	"strings"
	"testing"

	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav1"
)

func TestCidV1Func(t *testing.T) {
	s := "Hello, World!"
	c := "bafybeig77vqcdozl2wyk6z3cscaj5q5fggi53aoh64fewkdiri3cdauyn4"
	b := []byte(s)

	cid, err := pnt.GetCidV1(b)

	if err != nil {
		t.Errorf("gietcidv1 func failed")
	}
	r := strings.Compare(c, cid.String())

	fmt.Println(r)
	switch r {
	case 0:
		t.Logf("cidv1 correct")

	case 1:
		t.Errorf("cidv1 incorrect")

	case -1:
		t.Errorf("cidv1 incorrect")
	}

}
