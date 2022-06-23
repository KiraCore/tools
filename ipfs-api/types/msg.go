package types

import "time"

// TODO: Parse responses from each call
type TestResponse struct {
	Message string `json:"message"`
}

type PinResponse struct {
	Duplicate bool   `json:"isDuplicate,omitempty"`
	IpfsHash  string `json:"ipfshash"`
	Timestamp string `json:"timestamp"`
	PinSize   int64  `json:"pinsize"`
}

type UnpinResponse struct {
	Success bool      `json:"success"`
	Hash    string    `json:"hash"`
	Time    time.Time `json:"time"`
}

type PinataMetadata struct {
	Name      string            `json:"name"`      // By default name of the file/directory
	KeyValues map[string]string `json:"keyvalues"` // Some additional data
}

type PinataOptions struct {
	WrapWithDirectory bool    `json:"wrapWithDirectory"` // Adds availability to address dir name instead of hash
	CidVersion        int8    `json:"cidVersion"`        // 0 or 1 Returns CID version of a choice
	Regions           Regions `json:"regions,omitempty"`
}
type Regions struct {
	RegionId  string `json:"regionId,omitempty"`
	CurrentRC int16  `json:"currentReplicationCount,omitempty"`
	DesiredRC int16  `json:"desiredReplicationCount,omitempty"`
}

type Rows struct {
	Id        string         `json:"id,omitempty"`
	CID       string         `json:"ipfs_pin_hash,omitempty"`
	UserId    string         `json:"user_id,omitempty"`
	Size      int64          `json:"size,omitempty"`
	Date      time.Time      `json:"date_pinned,omitempty"`
	DateUnpin time.Time      `json:"date_unpinned,omitempty"`
	Metadata  PinataMetadata `json:"metadata,omitempty"`
	Regions   []Regions      `json:"regions,omitempty"`
}

type PinnedResponse struct {
	Count int16  `json:"count,omitempty"`
	Rows  []Rows `json:"rows,omitempty"`
}

var Opts PinataOptions
