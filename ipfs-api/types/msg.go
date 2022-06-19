package types

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

type PinataMetadata struct {
	Name      string            `json:"name"`      // By default name of the file/directory
	KeyValues map[string]string `json:"keyvalues"` // Some additional data
}

type PinataOptions struct {
	WrapWithDirectory bool `json:"wrapWithDirectory"` // Adds availability to address dir name instead of hash
	CidVersion        int8 `json:"cidVersion"`        // 0 or 1 Returns CID version of a choice

}

var Opts PinataOptions
