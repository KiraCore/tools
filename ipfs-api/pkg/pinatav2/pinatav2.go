// Refactoring, not used
package pinatav2

import (
	"io/fs"
	"net/http"
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

type PinataMetadataJSON struct {
	Name      string            `json:"name"`      // By default name of the file/directory
	KeyValues map[string]string `json:"keyvalues"` // Some additional data
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
