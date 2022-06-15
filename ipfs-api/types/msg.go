package types

// TODO: Parse responses from each call
type TestResponse struct {
	Message string `json:"message"`
}

type PinResponse struct {
	IpfsHash  string `json:"ipfshash"`
	PinSize   int64  `json:"pinsize"`
	Timestamp string `json:"timestamp"`
	Duplicate bool   `json:"isDuplicate,omitempty"`
}

type PinataMetadata struct {
	Name      string                      `json:"name"`      // By default name of the file/directory
	KeyValues map[interface{}]interface{} `json:"keyvalues"` // Some additional data
}

type Region struct {
	ID                      string `json:"id"`
	DesiredReplicationCount int    `json:"desiredReplicationCount"`
}

type CustomPinPolicy struct {
	Regions []Region `json:"regions"`
}
type PinataOptions struct {
	CidVersion        int             `json:"cidVersion"`        // 0 or 1 Returns CID version of a choice
	WrapWithDirectory bool            `json:"wrapWithDirectory"` // Adds availability to address dir name instead of hash
	CustomPinPolicy   CustomPinPolicy `json:"customPinPolicy"`   // Allows to choose region and qty of nodes used to pin the data
}
