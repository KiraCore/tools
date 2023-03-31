// Third refactor. Return types from Pin call.
// Restructure PinataApi type.
// Requests refactor
package pinatav3

import (
	"io"
	"net/http/httputil"
	"os"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
)

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
