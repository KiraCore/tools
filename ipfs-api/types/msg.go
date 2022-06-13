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
	Name      string                      `json:"name"`
	KeyValues map[interface{}]interface{} `json:"keyvalues"`
}
