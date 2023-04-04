package pinatav2

import (
	"testing"
)

func TestPinataApiSetOptsMax(t *testing.T) {
	p := PinataApi{}
	err := p.SetOpts(127, false)
	if err == nil {
		t.Errorf("want error")
	}

}
func TestPinataApiSetOptsMin(t *testing.T) {
	p := PinataApi{}
	err := p.SetOpts(-127, false)
	if err == nil {
		t.Errorf("want error")
	}

}
func TestPinataApiSetOptsOne(t *testing.T) {
	p := PinataApi{}
	err := p.SetOpts(1, false)
	if err != nil {
		t.Errorf("want error %v", err)
	}

}
func TestPinataApiSetOptZero(t *testing.T) {
	p := PinataApi{}
	err := p.SetOpts(0, false)
	if err != nil {
		t.Errorf("want error")
	}

}

func TestPinataApiSetMetaNameMax(t *testing.T) {
	p := PinataApi{}
	err := p.SetMetaName("gcwcorzcwupzndmvvawifxtmpvjuaiwbmnuiaqoesqajfucqwpcnrdgkyflcgdrmlquzwcszigxdqpzrttppxwyoxqrtdabllqsfwoionofffkmdtljeyiilrfrvnidmqbwitjklbcfjuutawvcabzdfsqkjmanzaxyvmribarjibidqudyawqpeharlpoaoaxrknvrvhtihsbsymabunbnbseqwnbyklygixxbuwdjzytsjubrkgrgwda")
	if err == nil {
		t.Errorf("want not nil got nil")
	}
}

func TestPinataApiSetMetaNameMin(t *testing.T) {
	p := PinataApi{}
	err := p.SetMetaName("")
	if err == nil {
		t.Errorf("want error: %v", err)
	}
}

func TestPinataApiCheckMetaEmpty(t *testing.T) {
	p := PinataApi{}
	b := p.CheckMeta()
	if b {
		t.Errorf("Should be false")
	}
}

func TestPinataApiCheckMetaFull(t *testing.T) {
	p := PinataApi{}
	p.SetMetaName("Full")
	b := p.CheckMeta()
	if !b {
		t.Errorf("Should be true")
	}
}

func TestPinataApiValidateCidNotValid(t *testing.T) {
	str := "./root/test/somefile.txt"
	b := ValidateCid(str)
	if b {
		t.Errorf("String is not valid, want false")
	}
}

func TestPinataApiValidateCidEmpty(t *testing.T) {
	str := ""
	b := ValidateCid(str)
	if b {
		t.Errorf("String is not valid, want false")
	}
}

func TestPinataApiValidateCidValidv1(t *testing.T) {
	str := "bafybeibkjmxftowv4lki46nad4arescoqc7kdzfnjkqux257i4jonk44w4"
	b := ValidateCid(str)
	if !b {
		t.Errorf("String is not valid, want false")
	}
}

func TestPinataApiValidateCidValidv0(t *testing.T) {
	str := "QmRBkKi1PnthqaBaiZnXML6fH6PNqCFdpcBxGYXoUQfp6z"
	b := ValidateCid(str)
	if !b {
		t.Errorf("String is not valid, want false")
	}
}
