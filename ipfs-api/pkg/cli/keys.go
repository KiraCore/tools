package cli

import (
	"bufio"
	"encoding/json"
	"io/fs"
	"os"
	"strings"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	tp "github.com/kiracore/tools/ipfs-api/types"
)

func keyFromFile(path string, fi fs.FileInfo) (tp.Keys, error) {
	var keys tp.Keys

	f, err := os.Open(path)
	if err != nil {
		log.Error("keyFromFile: can't open file")
		os.Exit(1)
	}

	if strings.Split(fi.Name(), ".")[1] == "json" {
		b := make([]byte, fi.Size())
		rb, err := f.Read(b)
		if err != nil {
			log.Error("keyFromFile: can't read from file")
			os.Exit(1)
		}

		json.Unmarshal(b, &keys)

		log.Info("keyFromFile: read %v bytes", rb)
		return keys, nil

	} else {
		scanner := bufio.NewScanner(f)
		var res []string

		for scanner.Scan() {
			newString := strings.Split(scanner.Text(), ":")
			if len(newString) != 1 {
				res = append(res, strings.TrimSpace(newString[1]))
			} else {
				log.Error("keyFromFile: failed to parse keys from file. invalid format\nexpected:\nAPI Key: value\nAPI Secret: value\nJWT: value")
				return keys, err
			}
		}
		keys := tp.Keys{Api_key: res[0], Api_secret: res[1], JWT: res[2]}
		return keys, nil

	}
}

func keyFromString(key string) (tp.Keys, error) {

	k1 := strings.Split(key, " ")
	k2 := strings.Split(key, ",")

	if len(k1) > 2 || len(k2) > 2 {
		log.Error("keyFromString: format incorrect. expect: | key secret | key,secret | key, secret |")
		os.Exit(1)
	}

	if len(k2) > 1 {

		return tp.Keys{Api_key: strings.TrimSpace(k2[0]), Api_secret: strings.TrimSpace(k2[1])}, nil

	} else if len(k1) > 1 {

		return tp.Keys{Api_key: strings.TrimSpace(k1[0]), Api_secret: strings.TrimSpace(k1[1])}, nil
	} else {

		return tp.Keys{JWT: strings.TrimSpace(key)}, nil
	}

}

func grabKey(key string) (tp.Keys, error) {
	if key == "" {
		log.Error("grabKey: key can't be empty")
		os.Exit(1)
	}
	if fi, err := os.Stat(key); err == nil {

		return keyFromFile(key, fi)
	} else {

		return keyFromString(key)

	}

}
