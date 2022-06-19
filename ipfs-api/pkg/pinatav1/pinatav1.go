package pinatav1

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"mime/multipart"
	"net/http"
	"net/http/httputil"
	"net/textproto"
	"os"
	"path/filepath"
	"sync"
	"time"

	cid "github.com/ipfs/go-cid"
	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	tp "github.com/kiracore/tools/ipfs-api/types"
	mh "github.com/multiformats/go-multihash"
	"golang.org/x/net/http2"
)

//Creating tweaked client
func NewClient() *http.Client {
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
	return &http.Client{
		Timeout:   100 * time.Second,
		Transport: tr,
	}

}

// Testing auth wih pinata server
func Test(keys tp.Keys) error {
	c := NewClient()

	req, err := http.NewRequest("GET", tp.BASE_URL+tp.TESTAUTH, nil)
	if err != nil {
		log.Error("test: something went wrong with request", err)
		return err
	}

	req.Header.Add("pinata_api_key", keys.Api_key)
	req.Header.Add("pinata_secret_api_key", keys.Api_secret)

	resp, err := c.Do(req)
	if err != nil {
		log.Error("test: didn't get any response", err)
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("test: can't read the request body", err)
			return err
		}

		// Parsing response
		r := tp.TestResponse{}
		e := json.Unmarshal(bytes, &r)
		if e != nil {
			log.Error("Test: failed to unmarshal json", e)
			return e
		}
		log.Info(r.Message)

	}
	return nil
}

// Adding pinataOptions to the request.
func setPinataOptions(bw *multipart.Writer, c int8, w bool) error {
	v, err := json.Marshal(tp.Opts)
	if err != nil {
		return err
	}
	fmt.Println(string(v))
	bw.WriteField(tp.PINATAOPTS, string(v))
	return nil

}
func setPinataMetadata(bw *multipart.Writer, fi fs.FileInfo, d map[string]string) error {

	m := tp.PinataMetadata{Name: fi.Name(), KeyValues: d}
	s, err := json.Marshal(m)
	if err != nil {
		return err
	}

	bw.WriteField(tp.PINATAMETA, string(s))
	return nil
}

// Adding HTML form to multipart body
func addForm(bw *multipart.Writer, filePath tp.ExtendedFileInfo) error {
	// wrap in struct

	f, err := os.Open(filePath.AbsoultePath)
	if err != nil {
		log.Error("addform: can't open the file")
		return err

	}

	// fi, err := f.Stat()
	// if err != nil {
	// 	log.Error("addform: can't read stats from the given path")
	// 	return err
	// }

	//MIME Header setup

	h := make(textproto.MIMEHeader)
	h.Set("Content-Disposition",
		fmt.Sprintf(`form-data; name="file"; filename="%s"`, filePath.Path))
	h.Set("Content-Type", "application/octet-stream")
	content, _ := bw.CreatePart(h)

	io.Copy(content, f)

	defer f.Close()

	return nil
}

//Wrapping HTML forms in the request body
func createReqBody(filePaths []tp.ExtendedFileInfo) (string, io.Reader, error) {

	// creating a pipe
	pipeReader, pipeWriter := io.Pipe()
	// creating writer for multipart request
	bodyWriter := multipart.NewWriter(pipeWriter)

	// Adding data-form with metadata and option fields
	// NB! Ready types for this entry are ready in pkg types
	if err := setPinataOptions(bodyWriter, 1, false); err != nil {
		log.Error("addform: failed to add pinataOptions to the for. %v", err)
	}
	d := make(map[string]string)

	if err := setPinataMetadata(bodyWriter, filePaths[0].Info, d); err != nil {
		log.Error("addform: failed to add pinataMetadata to the for. %v", err)

	}

	// calling for a goroutine to add all forms found by walker
	for _, t := range filePaths {
		fmt.Println(t.Path)
	}
	go func() {
		for _, filePath := range filePaths {
			if err := addForm(bodyWriter, filePath); err != nil {
				log.Error("createbody: failed to add form to multipart request")
				return

			}
			log.Info("pinned: %v", filePath.Info.Name())

		}

		bodyWriter.Close()
		pipeWriter.Close()

	}()

	return bodyWriter.FormDataContentType(), pipeReader, nil

}

//Parsing directory tree recursively. NB: SLOW
func walker(rootDir string) []tp.ExtendedFileInfo {

	var wg sync.WaitGroup
	var efi = []tp.ExtendedFileInfo{}

	// calling for a goroutine which will yield res through chan
	wg.Add(1)
	go func() {
		base := filepath.Base(rootDir) + "/"
		err := filepath.Walk(rootDir, func(path string, info fs.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if !info.IsDir() {
				rel, err := filepath.Rel(rootDir, path)
				if err != nil {
					log.Error("walker: can't get relative path for %v. err: %v", path, err)
				}
				fn := filepath.Clean(base + rel)
				efi = append(efi, tp.ExtendedFileInfo{Info: info, Path: fn, AbsoultePath: rootDir})

			}

			// wout <- fn + ":" + path
			return nil

		})
		if err != nil {
			return
		}
		wg.Done()
	}()
	wg.Wait()

	return efi

}

//Pins given file/directory to pinata.cloud service using api v1
func Pin(args []string, keys tp.Keys) error {
	path := args[0]
	// checking if the path is valid and file/folder exist
	if _, err := os.Stat(path); os.IsNotExist(err) {
		log.Error("pin: provided path doesn't exist")
		return err
	}
	// parsing the tree
	filePaths := walker(path)

	// creating requestbody
	contType, reader, err := createReqBody(filePaths)
	if err != nil {
		log.Error("pin: failed to create body")
		return err
	}
	log.Info("createReqBody ok\n")

	// forming request
	req, err := http.NewRequest("POST", tp.BASE_URL+tp.PINFILE, reader)
	if err != nil {
		log.Error("pin: failed to assemble request")
		return err
	}

	//adding headers

	// req.Header.Add("pinata_api_key", keys.Api_key)
	// req.Header.Add("pinata_secret_api_key", keys.Api_secret)
	req.Header.Add("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiIzNWRjZDc0OC1mMDE3LTQ0NjEtYTdiOC0wOGVkZDc3MDU2NzciLCJlbWFpbCI6InlhaWV2Z2VuaXlAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBpbl9wb2xpY3kiOnsicmVnaW9ucyI6W3siaWQiOiJGUkExIiwiZGVzaXJlZFJlcGxpY2F0aW9uQ291bnQiOjF9XSwidmVyc2lvbiI6MX0sIm1mYV9lbmFibGVkIjpmYWxzZSwic3RhdHVzIjoiQUNUSVZFIn0sImF1dGhlbnRpY2F0aW9uVHlwZSI6InNjb3BlZEtleSIsInNjb3BlZEtleUtleSI6ImRiYzYzNWMxYzFkZDY5YTRhMDE4Iiwic2NvcGVkS2V5U2VjcmV0IjoiNWYwZDVjOTdhNDc0YzkxYTMzMzU4ODZlNjA1MDA4NTFjNzY3ZjYyYmE1OTI5MDQ3ODMzOThlYTlmMDgyZmIxYSIsImlhdCI6MTY1NTI4OTQ2NX0.Zooi19QTZJDR6mueWpvAnD_qaG3T9LtPpInI_lTBrGo")
	req.Header.Add("Content-Type", contType)

	client := NewClient()

	// Printing request with all data for debugging

	requestDump, err := httputil.DumpRequest(req, true)
	if err != nil {
		fmt.Println(err)

	}
	fmt.Println(string(requestDump))

	// sending request
	resp, err := client.Do(req)
	if err != nil {
		log.Error("pin: request send error:", err)
		return err
	}

	defer resp.Body.Close()

	// checking a response code
	if resp.StatusCode == http.StatusOK {
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("pin: can't read the request body %v", err)
		}

		// Parsing response
		r := tp.PinResponse{}
		e := json.Unmarshal(bytes, &r)
		if e != nil {
			log.Error("pin: failed to unmarshal json from response %v", e)
		}
		log.Info("Finished successfully...\nCID: %v\nsize: %v\ntime: %v\nduplicate: %v", r.IpfsHash, r.PinSize, r.Timestamp, r.Duplicate)

	} else {
		// if something unexpected received in the response body
		log.Info("status: %v\n", resp.StatusCode)
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("pin: can't read the request body %v", err)
		}
		log.Error("pin: request body: %v", string(bytes))
	}

	return nil
}

// Deleting data from pinata.cloud by hash (CID)
func Unpin(args []string, keys tp.Keys) error {
	c := NewClient()

	req, err := http.NewRequest(http.MethodDelete, tp.BASE_URL+tp.UNPIN+"/"+args[0], nil)
	if err != nil {
		log.Error("unpin: failed to assemble request ")
		return err
	}
	req.Header.Add("pinata_api_key", keys.Api_key)
	req.Header.Add("pinata_secret_api_key", keys.Api_secret)

	resp, err := c.Do(req)

	if err != nil {
		log.Error("unpin: didn't get any response", err)
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("unpin: can't read the request body", err)
			return err
		}
		log.Info("deleted. CID: %v. Server response: %v", args[0], string(bytes))

	} else {
		log.Error("unpin: file/Folder could NOT be unpinned or deleted from IPFS")
		return err
	}
	return nil
}

// GetCidV1 accept byte slice and count hash sum
func GetCidV1(b []byte) (cid.Cid, error) {
	builder := cid.V1Builder{
		Codec:    cid.DagProtobuf,
		MhType:   mh.SHA2_256,
		MhLength: -1,
	}
	c, err := builder.Sum(b)
	if err != nil {
		return cid.Cid{}, err
	}
	return c, nil

}

func GetCidV0(b []byte) (cid.Cid, error) {
	builder := cid.V0Builder{}
	c, err := builder.Sum(b)
	if err != nil {
		return cid.Cid{}, err
	}
	return c, nil

}

//Checking data if it is pinned on pinata.cloud
func Pinned(args []string, keys tp.Keys) {
	c := NewClient()

	req, err := http.NewRequest(http.MethodDelete, tp.BASE_URL+tp.UNPIN+"/"+args[0], nil)
	if err != nil {
		return
	}
	req.Header.Add("pinata_api_key", keys.Api_key)
	req.Header.Add("pinata_secret_api_key", keys.Api_secret)

	param := req.URL.Query()
	param.Add("hashContains", args[0])
	req.URL.RawQuery = param.Encode()

	resp, err := c.Do(req)

	if err != nil {
		log.Error("didn't get any response", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("can't read the request body", err)
		}
		log.Info("file exists: %v. %v", args[0], string(bytes))

	} else {
		log.Error("file with CID %v doesn't exist", args[0])
	}

}

//Downloading data. TODO: adding download for directories
func Download(args []string, keys tp.Keys, gateway string) {
	c := NewClient()

	req, err := http.NewRequest(http.MethodGet, gateway+"/ipfs/"+args[0], nil)
	if err != nil {
		return
	}
	req.Header.Add("pinata_api_key", keys.Api_key)
	req.Header.Add("pinata_secret_api_key", keys.Api_secret)

	f, err := os.Create(args[0])
	if err != nil {
		log.Error("download: failed to create file/folder")
		return
	}

	resp, err := c.Do(req)
	if err != nil {
		log.Error("download: failed to get the response")
		return
	}

	if _, err = io.Copy(f, resp.Body); err != nil {
		log.Error("download: failed to io.Copy")

	}
	defer resp.Body.Close()
	r, _ := io.ReadAll(resp.Body)
	fmt.Println(string(r))

}

func PostDownloadCheck(args []string) {

}
