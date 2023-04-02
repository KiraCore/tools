// Refactoring, not used
package pinatav2

import (
	"errors"
	"io/fs"
	"net/http"
	"strings"
	"time"
)

type UnpinResponse struct {
	Success bool      `json:"success"`
	Hash    string    `json:"hash"`
	Time    time.Time `json:"time"`
}

type TestResponse struct {
	Message string `json:"message"`
}
type Regions struct {
	RegionId  string `json:"regionId,omitempty"`
	CurrentRC int16  `json:"currentReplicationCount,omitempty"`
	DesiredRC int16  `json:"desiredReplicationCount,omitempty"`
}

type Rows struct {
	Id        string             `json:"id,omitempty"`
	CID       string             `json:"ipfs_pin_hash,omitempty"`
	UserId    string             `json:"user_id,omitempty"`
	Size      int64              `json:"size,omitempty"`
	Date      time.Time          `json:"date_pinned,omitempty"`
	DateUnpin time.Time          `json:"date_unpinned,omitempty"`
	Metadata  PinataMetadataJSON `json:"metadata,omitempty"`
	Regions   []Regions          `json:"regions,omitempty"`
}

type PinnedResponse struct {
	Count int32  `json:"count"`
	Rows  []Rows `json:"rows"`
}

type PinResponseJSONProd struct {
	Duplicate bool   `json:"duplicate,omitempty"`
	IpfsHash  string `json:"hash"`
	Timestamp string `json:"timestamp"`
	PinSize   int64  `json:"size"`
}
type PinResponseJSON struct {
	Duplicate bool   `json:"isduplicate,omitempty"`
	IpfsHash  string `json:"ipfshash"`
	Timestamp string `json:"timestamp"`
	PinSize   int64  `json:"pinsize"`
}
type PinResponse struct {
	duplicate bool
	ipfsHash  string
	timestamp string
	pinSize   int64
}

// PinataPutMetadataJSON is a structure that holds the data required to update the metadata of an IPFS hash in Pinata.
type PinataPutMetadataJSON struct {
	IpfsHash  string            `json:"ipfsPinHash"`
	Name      string            `json:"name"`                // By default name of the file/directory
	KeyValues map[string]string `json:"keyvalues,omitempty"` // Some additional data

}
type PinataMetadataJSON struct {
	Name      string            `json:"name"`                // By default name of the file/directory
	KeyValues map[string]string `json:"keyvalues,omitempty"` // Some additional data
}

type PinataMetadata struct {
	name      string
	keyValues map[string]string
}

type RegionsJSON struct {
	RegionId  string `json:"regionid,omitempty"`
	CurrentRC int16  `json:"currentreplicationcount,omitempty"`
	DesiredRC int16  `json:"desiredreplicationcount,omitempty"`
}

// type Regions struct {
// 	regionId  string
// 	currentRC int16
// 	desiredRC int16
// }

type Url struct {
	url string
}
type Query struct {
	Hash string `url:"metadata[name],omitempty"`
	Meta string `url:"metadata[name],omitempty"`
}

type PinataOptionsJSON struct {
	WrapWithDirectory bool    `json:"wrapWithDirectory"` // Adds availability to address dir name instead of hash
	CidVersion        int8    `json:"cidVersion"`        // 0 or 1 Returns CID version of a choice
	Regions           Regions `json:"regions,omitempty"`
}

type PinataOptions struct {
	wrapWithDirectory bool // Adds availability to address dir name instead of hash
	cidVersion        int8 // 0 or 1 Returns CID version of a choice
	regions           Regions
}

type ExtendedFileInfo struct {
	info         fs.FileInfo
	path         string
	absoultePath string
}
type Walker struct {
	bulk []ExtendedFileInfo
}

type KeysJSON struct {
	Api_key    string `json:"api_key,omitempty"`
	Api_secret string `json:"api_secret,omitempty"`
	Jwt        string `json:"jwt,omitempty"`
}
type Keys struct {
	set        bool
	api_key    string
	api_secret string
	jwt        string
}

type Header struct {
	keys   Keys
	header http.Header
}

type Request struct {
	header Header
	dump   http.Request
}

type PinataApi struct {
	client   http.Client
	request  Request
	walker   Walker
	opts     PinataOptions
	meta     PinataMetadata
	data     string
	resp     []byte
	dump     bool
	respCode int
}

func StrToMeta(meta string) (map[string]string, error) {
	var n = make(map[string]string)
	s := strings.Split(meta, ",")
	l := len(s)
	if l != 0 && l%2 == 0 {
		for i := 0; i < l; i = i + 2 {
			n[strings.TrimSpace(s[i])] = strings.TrimSpace(s[i+1])
		}

	} else {
		return make(map[string]string), errors.New("number of key/value pairs should be equal")
	}
	return n, nil
}
