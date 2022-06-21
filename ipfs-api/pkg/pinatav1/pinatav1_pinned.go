package pinatav1

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httputil"
	"os"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	tp "github.com/kiracore/tools/ipfs-api/types"
)

//Checking data if it is pinned on pinata.cloud
func Pinned(args []string, keys tp.Keys) {
	c := NewClient()

	req, err := http.NewRequest("GET", "https://api.pinata.cloud/data/pinList", nil)
	if err != nil {
		os.Exit(1)
		return
	}
	// req.Header.Add("pinata_api_key", keys.Api_key)
	// req.Header.Add("pinata_secret_api_key", keys.Api_secret)
	addKeysToHeader(req, keys)

	param := req.URL.Query()
	param.Add("hashContains", args[0])
	req.URL.RawQuery = param.Encode()

	resp, err := c.Do(req)
	if err != nil {
		log.Error("didn't get any response", err)
		os.Exit(1)
	}
	defer resp.Body.Close()
	requestDump, err := httputil.DumpRequest(req, true)
	if err != nil {
		log.Error("pin: failed to dump request log")
	} else {
		log.Debug(string(requestDump))
	}

	log.Debug(string(requestDump))

	r := tp.PinnedResponse{}
	if resp.StatusCode == http.StatusOK {
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("can't read the request body", err)
			os.Exit(1)
		}

		er := json.Unmarshal(bytes, &r)
		if er != nil {
			log.Error("pinned: failed to unmarshal json: %v", er)
			os.Exit(1)

		}

		log.Info("pinned: address exists: %v", args[0])
		j, err := json.Marshal(r)
		if err != nil {
			log.Error("pinned: failed to marshal json: %v", err)
		}
		//fmt.Println(string(bytes))
		//fmt.Println()
		fmt.Println(string(j))

	} else {

		log.Error("file with CID %v doesn't exist", args[0])
		bytes, _ := io.ReadAll(resp.Body)

		fmt.Println(string(bytes))
		os.Exit(1)
	}

}
