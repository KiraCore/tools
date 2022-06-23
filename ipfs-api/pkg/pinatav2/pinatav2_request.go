package pinatav2

import (
	"io"
	"net/http"
)

func (r *Request) Get(url string) (*http.Request, error) {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return req, err
	}
	r.header.header = req.Header
	r.header.Init() //initialize header(adding keys)
	return req, nil
}

func (r *Request) Del(url string) (*http.Request, error) {
	req, err := http.NewRequest(http.MethodDelete, url, nil)
	if err != nil {
		return req, err
	}
	r.header.header = req.Header
	r.header.Init() //initialize header(adding keys)
	return req, nil
}
func (r *Request) Post(url string, reader *io.Reader) (*http.Request, error) {
	req, err := http.NewRequest(http.MethodPost, url, *reader)
	if err != nil {
		return req, err
	}
	r.header.header = req.Header
	r.header.Init() //initialize header(adding keys)
	return req, nil
}
