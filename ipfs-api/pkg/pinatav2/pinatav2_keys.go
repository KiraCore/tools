package pinatav2

import (
	"bufio"
	"encoding/json"
	"io/fs"
	"os"
	"strings"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
)

// Secured keys struct. Can't be changed anywhere.
// Should only be passed as a copy.
type Keys struct {
	api_key    string
	api_secret string
	jwt        string
}

// Structure for parsing keys provided in json
// Should only be passed as a copy.
type KeysJSON struct {
	Api_key    string `json:"api_key,omitempty"`
	Api_secret string `json:"api_secret,omitempty"`
	Jwt        string `json:"jwt,omitempty"`
}

func (k Keys) Add(key string, secret string, jwt string) Keys {
	return Keys{api_key: key, api_secret: secret, jwt: jwt}
}

func keyFromFile(path string, fi fs.FileInfo) (Keys, error) {
	var keysJson KeysJSON
	var keys Keys

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

		json.Unmarshal(b, &keysJson)

		log.Info("keyFromFile: read %v bytes", rb)

		return keys.Add(keysJson.Api_key, keysJson.Api_secret, keysJson.Jwt), nil

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

		return keys.Add(res[0], res[1], res[2]), nil

	}
}

// Gets keys from string provided by user
func keyFromString(key string) (Keys, error) {
	var keys Keys

	k1 := strings.Split(key, " ")
	k2 := strings.Split(key, ",")

	if len(k1) > 2 || len(k2) > 2 {
		log.Error("keyFromString: format incorrect. expect: | key secret | key,secret | key, secret |")
		os.Exit(1)
	}

	if len(k2) > 1 {

		return keys.Add(strings.TrimSpace(k2[0]), strings.TrimSpace(k2[1]), ""), nil

	} else if len(k1) > 1 {

		return keys.Add(strings.TrimSpace(k1[0]), strings.TrimSpace(k1[1]), ""), nil
	} else {

		return keys.Add("", "", strings.TrimSpace(key)), nil
	}

}

// grabKey chooses source to parse and provide keys
func grabKey(key string) (Keys, error) {
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
