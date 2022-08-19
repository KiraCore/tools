package pinatav3

import "net/http"

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
