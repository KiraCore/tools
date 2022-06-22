// Refactoring, not used
package pinatav2

import (
	"io/fs"
	"net/http"
)

type PinResponseJSON struct {
	Duplicate bool   `json:"isduplicate,omitempty"`
	IpfsHash  string `json:"hash"`
	Timestamp string `json:"timestamp"`
	PinSize   int64  `json:"pinsize"`
}
type PinResponse struct {
	duplicate bool   `json:"isDuplicate,omitempty"`
	ipfsHash  string `json:"ipfshash"`
	timestamp string `json:"timestamp"`
	pinSize   int64  `json:"pinsize"`
}

type PinataMetadataJSON struct {
	Name      string            `json:"name"`      // By default name of the file/directory
	KeyValues map[string]string `json:"keyvalues"` // Some additional data
}

type PinataMetadata struct {
	name      string            `json:"name"`
	keyValues map[string]string `json:"keyvalues"`
}

type RegionsJSON struct {
	RegionId  string `json:"regionId,omitempty"`
	CurrentRC int16  `json:"currentReplicationCount,omitempty"`
	DesiredRC int16  `json:"desiredReplicationCount,omitempty"`
}

type Regions struct {
	regionId  string `json:"regionId,omitempty"`
	currentRC int16  `json:"currentReplicationCount,omitempty"`
	desiredRC int16  `json:"desiredReplicationCount,omitempty"`
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
	resp     []byte
	dump     bool
	respCode int
}
