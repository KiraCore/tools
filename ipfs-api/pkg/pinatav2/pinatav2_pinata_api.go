package pinatav2

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"os"

	"net/http"
	"net/http/httputil"
	"net/textproto"
	"time"

	cid "github.com/ipfs/go-cid"
	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	tp "github.com/kiracore/tools/ipfs-api/types"
	"golang.org/x/net/http2"
)

// Setting new client for an Api
func ValidateCid(hash string) bool {
	_, err := cid.Decode(hash)
	if err != nil {
		return false
	}
	return true
}

func (p *PinataApi) newClient() {

	// Client params to be adjusted ...
	tr := &http.Transport{
		MaxIdleConnsPerHost:   100,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		ExpectContinueTimeout: 5 * time.Second,
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}
	http2.ConfigureTransport(tr)
	p.client = http.Client{
		Timeout:   100 * time.Second,
		Transport: tr,
	}

}

// Adding keys to request header
func (p *PinataApi) SetKeys(keys Keys) {
	p.request.header.keys = keys
	p.newClient()
	p.SetOptsDefault()
}

// Sending GET request to check authorization
func (p *PinataApi) Test() error {
	req, err := p.request.Get(tp.BASE_URL + tp.TESTAUTH)
	if err != nil {
		log.Debug("Ipfs-api: test: invalid request: %v", err)
		return err
	}

	resp, err := p.client.Do(req)
	if err != nil {
		log.Debug("Ipfs-api: test: invalid response: %v", err)
		return err
	}
	defer resp.Body.Close()

	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	p.SaveResp(b)
	p.SetRespCode(resp.StatusCode)

	return nil
}

// Unpin removes the content from the Pinata API by its IPFS hash or metadata name.
// This function returns an error if the unpinning operation fails.
//
// hash: A string containing either the IPFS hash or the metadata name of the content.
//
// Returns an error if any operation fails.
func (p *PinataApi) Unpin(hash string) error {
	log.Debug("Call Unpin ...")
	log.Debug("Received arg:", hash)
	// Initialize a Url instance.
	url := Url{}

	// Set the URL for unpinning by IPFS hash.
	url.Set(tp.BASE_URL + tp.UNPIN + "/" + hash)
	log.Debug("Formed URL: ", url.Get())

	// Create a new DELETE request using the PinataApi request object.
	req, err := p.request.Del(url.Get())
	if err != nil {
		return err
	}

	// Send the request and get the response.
	resp, err := p.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Read the response body.
	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	// Save the response body and status code to the PinataApi instance.
	log.Debug("Response string([]byte): ", b)
	p.SaveResp(b)
	log.Debug("Response stat code: ", resp.StatusCode)
	p.SetRespCode(resp.StatusCode)

	return nil
}

// Pinned retrieves the pinned content by hash or metadata name from the Pinata API.
// This function returns an error if the request to the Pinata API fails.
//
// hash: A string containing either the IPFS hash or the metadata name of the content.
//
// Returns an error if any operation fails.
func (p *PinataApi) Pinned(hash string) error {
	log.Debug("Call pinned ...")
	// Initialize a Url instance.
	url := Url{}

	// Check if the provided hash is a valid CID.
	if ValidateCid(hash) {
		// Set the URL to search by IPFS hash.
		url.Set(tp.BASE_URL + tp.PINNEDDATA + "/?status=pinned&hashContains=" + hash)
		log.Debug("ValidateCId return true. Url: ", url.Get())
	} else {
		// Set the URL to search by metadata name.
		url.Set(tp.BASE_URL + tp.PINNEDDATA + "/?status=pinned&metadata[name]=" + hash)
		log.Debug("Url formed to get meta: ", url.Get())
	}

	// Create a new request using the PinataApi request object.
	req, err := p.request.Get(url.Get())
	if err != nil {
		return err
	}

	// Send the request and get the response.
	resp, err := p.client.Do(req)
	if err != nil {
		log.Debug("Ipfs-api: test: invalid response: %v", err)
		return err
	}
	defer resp.Body.Close()

	// Read the response body.
	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	// Save the response body and status code to the PinataApi instance.
	log.Debug("Response string([]byte): ", string(b))
	p.SaveResp(b)
	log.Debug("Response stat code: ", resp.StatusCode)
	p.SetRespCode(resp.StatusCode)

	return nil
}

func (p *PinataApi) Pin(path string) error {
	// Return response as a struct. Clone output logic to
	// response struct
	if _, err := os.Stat(path); os.IsNotExist(err) {
		log.Error("pin: provided path doesn't exist")
		return err
	}
	err := p.walker.Walk(path)
	if err != nil {
		return err
	}
	c, r, err := p.createBody()
	if err != nil {
		return err
	}
	req, err := p.request.Post(tp.BASE_URL+tp.PINFILE, &r)
	if err != nil {
		return err
	}

	req.Header.Add("Content-Type", c)
	if p.dump {
		rd, err := httputil.DumpRequest(req, true)
		if err != nil {
			return err
		}
		f, err := os.Create("./dump.log")
		if err != nil {
			return err
		}
		f.Write(rd)
		f.Close()
	}

	resp, err := p.client.Do(req)
	if err != nil {
		log.Debug("Ipfs-api: pin: invalid response: %v", err)
		return err
	}
	defer resp.Body.Close()

	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	p.SaveResp(b)
	p.SetRespCode(resp.StatusCode)
	return nil
}

func (p *PinataApi) createBody() (string, io.Reader, error) {

	pr, pw := io.Pipe()
	bw := multipart.NewWriter(pw)

	go func() {

		bw.WriteField(tp.PINATAOPTS, p.GetOpts())

		if p.CheckMeta() {
			log.Debug("meta available: will set %v", p.GetMeta())
			bw.WriteField(tp.PINATAMETA, p.GetMeta())
		}

		for _, p := range p.walker.bulk {
			f, err := os.Open(p.Abs())
			if err != nil {
				log.Error("failed to open %v", p.Abs())
				os.Exit(1) // return error
			}
			h := make(textproto.MIMEHeader)
			h.Set("Content-Disposition",
				fmt.Sprintf(`form-data; name="file"; filename="%s"`, p.Path()))
			h.Set("Content-Type", "application/octet-stream")

			c, err := bw.CreatePart(h)
			if err != nil {
				log.Error("failed to create part")
				os.Exit(1)
			}
			d, err := io.Copy(c, f)
			if err != nil {
				log.Error("failed to copy content")
				os.Exit(1)
			} else {
				log.Debug("uploaded file %v: bytes : %v", p.Path(), d)
			}
			f.Close()

		}

		bw.Close()
		pw.Close()

	}()
	return bw.FormDataContentType(), pr, nil

}

func (p *PinataApi) SetOpts(c int8, b bool) error {
	if c >= 0 && c < 2 {
		p.opts.cidVersion = c
	} else {
		return errors.New("CID version should be 0 or 1")
	}

	p.opts.wrapWithDirectory = b

	return nil
}

func (p *PinataApi) SetOptsDefault() {
	p.SetOpts(1, false)
}

func (p *PinataApi) GetOpts() string {
	o := PinataOptionsJSON{WrapWithDirectory: p.opts.wrapWithDirectory, CidVersion: p.opts.cidVersion}
	j, err := json.Marshal(o)
	if err != nil {
		log.Error("failed to get options")
	}
	return string(j)
}

func (p *PinataApi) GetMeta() string {
	m := PinataMetadataJSON{Name: p.meta.name, KeyValues: p.meta.keyValues}
	j, err := json.Marshal(m)
	if err != nil {
		log.Error("failed to get options")
	}
	return string(j)
}

// SetMeta updates the metadata associated with an IPFS hash in Pinata.
//
// h: The IPFS hash of the content to update the metadata for.
// n: The new name to be associated with the IPFS hash.
//
// Returns an error if the update operation fails.
func (p *PinataApi) SetMeta(h string, n string) error {
	r := PinataPutMetadataJSON{
		IpfsHash:  h,
		Name:      n,
		KeyValues: p.meta.keyValues,
	}
	var buf bytes.Buffer

	err := json.NewEncoder(&buf).Encode(r)
	if err != nil {
		log.Error("SetMeta: %s", err)
		return err
	}

	req, err := p.request.Put(tp.BASE_URL+tp.METADATA_URL, &buf)
	if err != nil {
		return err
	}
	req.Header.Add("Content-Type", "application/json")

	rd, err := httputil.DumpRequest(req, true)
	if err != nil {
		return err
	}
	f, err := os.Create("./dump.log")
	if err != nil {
		return err
	}
	f.Write(rd)
	f.Close()

	if resp, err := p.client.Do(req); err != nil {
		return err
	} else {
		r, _ := io.ReadAll(resp.Body)
		fmt.Println(string(r))
	}

	return nil

}
func (p *PinataApi) SetMetaData(m map[string]string) {
	p.meta.keyValues = m
}
func (p *PinataApi) SetMetaName(n string) error {
	if len(n) != 0 && len(n) <= 245 {
		err := p.Pinned(n)
		if err != nil {
			return err
		}
		s := PinnedResponse{}
		if err := json.Unmarshal(p.resp, &s); err != nil {
			return err
		}
		if s.Count != 0 {
			log.Error("SetMetaName: name exist")
			return errors.New("name already exist")
		}
		log.Debug("setting meta name to %s", n)
		p.meta.name = n
		return nil
	} else {
		return errors.New("provided name should be from 1 to 250 chars long")
	}

}
func (p *PinataApi) CheckMeta() bool {
	if len(p.meta.name) > 1 || len(p.meta.keyValues) > 1 {
		return true
	} else {
		return false
	}
}

func (p *PinataApi) Dump() {
	p.dump = true
}

func (p *PinataApi) SetRespCode(code int) {
	p.respCode = code
}
func (p *PinataApi) SaveResp(resp []byte) {
	p.resp = resp
}
func (p *PinataApi) OutputPinJsonObj() (PinResponseJSON, error) {
	s := PinResponseJSON{}
	if err := json.Unmarshal(p.resp, &s); err != nil {
		log.Error("failed to unmarshal in json")
		return PinResponseJSON{}, err
	}
	return s, nil

}

func (p *PinataApi) OutputPinnedJsonObj() (PinnedResponse, error) {
	s := PinnedResponse{}
	if err := json.Unmarshal(p.resp, &s); err != nil {
		log.Error("failed to unmarshal in json")
		return PinnedResponse{}, err
	}
	return s, nil
}

func (p *PinataApi) OutputPinJson() error {
	s := PinResponseJSON{}
	if err := json.Unmarshal(p.resp, &s); err != nil {
		log.Error("failed to unmarshal in json")
		return err
	}
	s2 := PinResponseJSONProd(s)
	j, err := json.Marshal(s2)
	if err != nil {
		log.Error("failed to marshal")
		return err
	}
	fmt.Println(string(j))
	return nil
}
func (p *PinataApi) OutputPinnedJson() error {
	if p.respCode != http.StatusOK {
		return errors.New("something failed")
	}
	s := PinnedResponse{}
	if err := json.Unmarshal(p.resp, &s); err != nil {
		return err
	}
	j, err := json.Marshal(s)
	if err != nil {
		return err
	}
	fmt.Println(string(j))
	return nil
}

func (p *PinataApi) OutputTestJson() error {
	if p.respCode != http.StatusOK {
		return errors.New("something failed")
	}
	s := TestResponse{}
	if err := json.Unmarshal(p.resp, &s); err != nil {
		return err
	}
	j, err := json.Marshal(s)
	if err != nil {
		return err
	}
	fmt.Println(string(j))
	return nil
}
func (p *PinataApi) OutputUnpinJson() error {
	if p.respCode != http.StatusOK {
		return fmt.Errorf("server returned: %v", p.respCode)
	} else {
		s := UnpinResponse{Success: true, Hash: p.data, Time: time.Now()}
		j, err := json.Marshal(s)
		if err != nil {
			log.Error("failed to marshal")
			return err
		}
		fmt.Println(string(j))
	}

	return nil
}

func (u *Url) Set(url string) {
	u.url = url
}

func (u *Url) Get() string {
	return u.url
}

func (p *PinataApi) SetData(data string) {
	p.data = data
}
