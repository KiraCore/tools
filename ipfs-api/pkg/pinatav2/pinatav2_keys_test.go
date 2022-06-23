package pinatav2

import (
	"testing"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
)

// txt files to test
const (
	t1 = "../testing/keys/test_keys_ksj.txt"
	t2 = "../testing/keys/test_keys_ks.txt"
	t3 = "../testing/keys/test_keys_j.txt"

	s1 = "LHEqALswTtxLgNrsFQG5, uyceqYWeMqo6NMTxG7JJwk24DBM1vsHQULawh0N7ur716ErKWkFEcJMr1yN0VamJ"
	s2 = "LHEqALswTtxLgNrsFQG5 uyceqYWeMqo6NMTxG7JJwk24DBM1vsHQULawh0N7ur716ErKWkFEcJMr1yN0VamJ"
	s3 = "fRKFqdX21j0wrckpt489NRfsR6sgxXIWY8eO5Awjp5J8oqlTyV7yeG6xF57GmMtM6izUOaoy73HW7XBwdpvSOKA897RpiStTS0k52CYPqKpolHbBr471QxQVq8r3q9C9u207caD9astZtTgCN2tFcFM5d1cCBZ5lIlvcPboUpandnISVFpIKGsJkh1FkLOmQh0M9QAMTan3z4TcqzSPpdbBYdrS5t4ymfKZUQgvzylciEND5ImUwv8XgyOp0XVJTV6vS0CZzAAHaOSMMBNy4NmbWMbUf8Fuocs4qkX0w79m6RqbUOvPq9AeGIIoNh3NnPl8jtZSqCIen8ptJhD3vDZvMCDvLlYjOXUxGHWZ6yqgOaRIrAm5llxlekT9UFKTT6vmr9OivYcAW4wXwolv96gKYMSYCMN5bZ8GfgDcj3ScfUclvGhyQ4Dzmlo2uqX8gyFT7Iq78j7eMCSIyFW9nAwuY13DJLIELUrVw3lptHBo7aVqapmi7DstcsywsVl3y08aiQ3qU8fHvajEj1JuyJLNJaExSlpOvwN2PPuvbHgdNiNbPtiw9JT9n16ls8KadIOjQN280W0q2UpV9s9p5b3SlExaauk3WCbrHL5Uy2gnb3t8bIzA7"

	se = ""
)

func TestKeysFromTxtKSJ(t *testing.T) {
	k, err := GrabKey(t1)
	if err != nil {
		log.Error("TestKeysFromTxtKSJ: %v, key: %v", err, k)
	}
}

func TestKeysFromTxtKS(t *testing.T) {
	k, err := GrabKey(t2)
	if err != nil {
		log.Error("TestKeysFromTxtKS: %v, key: %v", err, k)
	}
}

func TestKeysFromTxtJ(t *testing.T) {
	k, err := GrabKey(t3)
	if err != nil {
		log.Error("TestKeysFromTxtJ: %v, key: %v", err, k)
	}
}

func TestKeysFromStrKSW(t *testing.T) {
	k, err := GrabKey(s1)
	if err != nil {
		log.Error("TestKeysFromStrKSW: %v, key: %v", err, k)
	}
}

func TestKeysFromStrKSC(t *testing.T) {
	k, err := GrabKey(s2)
	if err != nil {
		log.Error("TestKeysFromStrKSC: %v, key: %v", err, k)
	}
}

func TestKeysFromStrJ(t *testing.T) {
	k, err := GrabKey(s3)
	if err != nil {
		log.Error("TestKeysFromStrJ: %v, key: %v", err, k)
	}
}

func TestKeysFromEmptyStr(t *testing.T) {
	k, err := GrabKey(se)
	if err == nil {
		log.Error("TestKeysFromEmtyStr: %v, key: %v", err, k)
	}
}
