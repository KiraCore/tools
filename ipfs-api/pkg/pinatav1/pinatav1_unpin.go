package pinatav1

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	tp "github.com/kiracore/tools/ipfs-api/types"
)

// Deleting data from pinata.cloud by hash (CID)
func Unpin(args []string, keys tp.Keys) error {
	c := NewClient()

	req, err := http.NewRequest(http.MethodDelete, tp.BASE_URL+tp.UNPIN+"/"+args[0], nil)
	if err != nil {
		log.Error("unpin: failed to assemble request ")
		os.Exit(1)
		return err
	}

	addKeysToHeader(req, keys)

	resp, err := c.Do(req)

	if err != nil {
		log.Error("unpin: didn't get any response", err)
		os.Exit(1)
		return err
	}
	defer resp.Body.Close()
	r := tp.UnpinResponse{}
	if resp.StatusCode == http.StatusOK {
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("unpin: can't read the request body", err)
			os.Exit(1)
			return err
		}
		log.Info("deleted. CID: %v. Server response: %v", args[0], string(bytes))
		r.Success = true
		r.Hash = args[0]
		r.Time = time.Now()
		j, err := json.Marshal(r)
		if err != nil {
			log.Error("unpin: failed to marshal")
			os.Exit(1)
		}

		fmt.Println(string(j))

	} else {
		log.Error("unpin: file/folder can't be unpinned. doesn't exist or deleted.")
		r.Success = false
		r.Hash = args[0]
		r.Time = time.Now()
		j, err := json.Marshal(r)
		if err != nil {
			log.Error("unpin: failed to marshal")
			os.Exit(1)
		}

		fmt.Println(string(j))
		os.Exit(1)
		return err
	}
	return nil
}
