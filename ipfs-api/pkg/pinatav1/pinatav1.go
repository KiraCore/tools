package pinatav1

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"mime/multipart"
	"net/http"
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

// Adding authentication method from given input, json or plain text file
func addKeysToHeader(req *http.Request, keys tp.Keys) {
	if keys.JWT != "" {

		req.Header.Add("Authorization", "Bearer "+keys.JWT)

	} else {
		req.Header.Add("pinata_api_key", keys.Api_key)
		req.Header.Add("pinata_secret_api_key", keys.Api_secret)
	}
}

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
		os.Exit(1)
		return err
	}

	addKeysToHeader(req, keys)

	resp, err := c.Do(req)
	if err != nil {
		log.Error("test: didn't get any response", err)
		os.Exit(1)
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("test: can't read the request body", err)
			os.Exit(1)
			return err
		}

		// Parsing response
		r := tp.TestResponse{}
		e := json.Unmarshal(bytes, &r)
		if e != nil {
			log.Error("Test: failed to unmarshal json", e)
			os.Exit(1)
			return e
		}
		log.Info(r.Message)

	}
	return nil
}

// Adding pinataOptions to the request.
// func using external variable tp.Opts to write
// user input data
func setPinataOptions(bw *multipart.Writer, c int8, w bool) error {
	v, err := json.Marshal(tp.Opts)
	if err != nil {
		os.Exit(1)
		return err
	}
	bw.WriteField(tp.PINATAOPTS, string(v))

	return nil

}
func setPinataMetadata(bw *multipart.Writer, fi fs.FileInfo, d map[string]string) error {

	m := tp.PinataMetadata{Name: fi.Name(), KeyValues: d}
	s, err := json.Marshal(m)
	if err != nil {
		os.Exit(1)
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
		log.Error("addform: can't open the file %v", filePath.AbsoultePath)
		os.Exit(1)
		return err

	}

	h := make(textproto.MIMEHeader)
	h.Set("Content-Disposition",
		fmt.Sprintf(`form-data; name="file"; filename="%s"`, filePath.Path))
	h.Set("Content-Type", "application/octet-stream")

	content, _ := bw.CreatePart(h)
	d, err := io.Copy(content, f)

	if err != nil {
		log.Error("addForm: failed to copy data: %v", err)
	} else {
		log.Info("addForm: uploaded file %v: bytes : %v", filePath.Path, d)
	}

	f.Close()

	return nil
}

//Wrapping HTML forms in the request body
func createReqBody(filePaths []tp.ExtendedFileInfo) (string, io.Reader, error) {
	// creating a pipe
	pipeReader, pipeWriter := io.Pipe()
	// creating writer for multipart request

	bodyWriter := multipart.NewWriter(pipeWriter)

	go func() {
		if err := setPinataOptions(bodyWriter, 1, false); err != nil {
			log.Error("addform: failed to add pinataOptions to the for. %v", err)
			os.Exit(1)
		}

		for _, filePath := range filePaths {
			if err := addForm(bodyWriter, filePath); err != nil {
				log.Error("createbody: failed to add form to multipart request")
				os.Exit(1)
				return

			}

		}

		bodyWriter.Close()
		pipeWriter.Close()

	}()

	return bodyWriter.FormDataContentType(), pipeReader, nil

}

//Parsing directory tree recursively. NB: SLOW
func walker(rootDir string) []tp.ExtendedFileInfo {
	ap, err := filepath.Abs(rootDir)
	base := filepath.Base(ap)
	if err != nil {
		log.Error("walker: failed to get absolute path")
		os.Exit(1)
	}

	var wg sync.WaitGroup
	var efi = []tp.ExtendedFileInfo{}

	wg.Add(1)
	go func() {

		err := filepath.Walk(ap, func(path string, info fs.FileInfo, err error) error {
			if err != nil {
				os.Exit(1)
				return err
			}
			if !info.IsDir() {
				rel, err := filepath.Rel(ap, path)

				if err != nil {
					log.Error("walker: can't get relative path for %v. err: %v", path, err)
					os.Exit(1)
				}
				fn := filepath.Clean(base + "/" + rel)
				efi = append(efi, tp.ExtendedFileInfo{Info: info, Path: fn, AbsoultePath: path})
			}

			return nil

		})
		if err != nil {
			os.Exit(1)
			return
		}
		wg.Done()
	}()
	wg.Wait()

	return efi

}

func GetHashByName(args []string, keys tp.Keys) {
	if len(args) > 1 {
		c := NewClient()
		req, err := http.NewRequest("GET", tp.BASE_URL+tp.PINNEDDATA+"?metadata[name]="+args[1], nil)
		if err != nil {
			log.Error("GetHashByName: failed to assemble request: %v", err)
			os.Exit(1)
		}
		//q := req.URL.Query()
		//q.Add("metadata[name]", args[1])

		addKeysToHeader(req, keys)
		//req.URL.RawQuery = q.Encode()
		resp, err := c.Do(req)
		if err != nil {
			log.Error("GetHashByName: failed to ger response: %v", err)
			os.Exit(1)
		}
		defer resp.Body.Close()
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("pin: can't read the request body %v", err)
			os.Exit(1)
		}
		// Printing request with all data for debugging

		// requestDump, err := httputil.DumpRequest(req, true)
		// if err != nil {
		// 	fmt.Println(err)

		// }
		// fmt.Println(string(requestDump))

		// sending request
		fmt.Println(string(bytes))

	}

}

//Pins given file/directory to pinata.cloud service using api v1
func Pin(args []string, keys tp.Keys) error {
	path := args[0]
	// checking if the path is valid and file/folder exist
	if _, err := os.Stat(path); os.IsNotExist(err) {
		log.Error("pin: provided path doesn't exist")
		os.Exit(1)
		return err
	}
	// parsing the tree
	filePaths := walker(path)

	// creating requestbody
	contType, reader, err := createReqBody(filePaths)
	if err != nil {
		log.Error("pin: failed to create body")
		os.Exit(1)
		return err
	}
	log.Info("pin: body formed\n")

	// forming request
	req, err := http.NewRequest("POST", tp.BASE_URL+tp.PINFILE, reader)
	if err != nil {
		log.Error("pin: failed to assemble request")
		os.Exit(1)
		return err
	}

	addKeysToHeader(req, keys)
	req.Header.Add("Content-Type", contType)

	client := NewClient()

	// Printing request with all data for debugging

	// requestDump, err := httputil.DumpRequest(req, true)
	// if err != nil {
	// 	fmt.Println(err)

	// }
	// log.Debug(string(requestDump))

	// sending request
	resp, err := client.Do(req)
	if err != nil {
		log.Error("pin: request send error:", err)
		os.Exit(1)
		return err
	}

	defer resp.Body.Close()

	// checking a response code
	if resp.StatusCode == http.StatusOK {
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("pin: can't read the request body %v", err)
			os.Exit(1)
		}

		// Parsing response
		r := tp.PinResponse{}
		e := json.Unmarshal(bytes, &r)
		if e != nil {
			log.Error("pin: failed to unmarshal json from response %v", e)
			os.Exit(1)
		}
		log.Info("Finished successfully...\nCID: %v\nsize: %v\ntime: %v\nduplicate: %v", r.IpfsHash, r.PinSize, r.Timestamp, r.Duplicate)
		fmt.Println(string(bytes))

	} else {
		// if something unexpected received in the response body
		log.Info("status: %v\n", resp.StatusCode)
		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error("pin: can't read the request body %v", err)
			os.Exit(1)
		}
		log.Error("pin: request body: %v", string(bytes))
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
		os.Exit(1)
		return cid.Cid{}, err
	}
	return c, nil

}

func GetCidV0(b []byte) (cid.Cid, error) {
	builder := cid.V0Builder{}
	c, err := builder.Sum(b)
	if err != nil {
		os.Exit(1)
		return cid.Cid{}, err
	}
	return c, nil

}

//Downloading data. TODO: adding download for directories
func Download(args []string, keys tp.Keys, gateway string) {
	c := NewClient()

	req, err := http.NewRequest(http.MethodGet, gateway+"/ipfs/"+args[0], nil)
	if err != nil {
		os.Exit(1)
		return
	}
	addKeysToHeader(req, keys)

	f, err := os.Create(args[0])
	if err != nil {
		log.Error("download: failed to create file/folder")
		os.Exit(1)
		return
	}

	resp, err := c.Do(req)
	if err != nil {
		log.Error("download: failed to get the response")
		os.Exit(1)
		return
	}

	if _, err = io.Copy(f, resp.Body); err != nil {
		log.Error("download: failed to io.Copy")

		os.Exit(1)
	}
	defer resp.Body.Close()
	r, _ := io.ReadAll(resp.Body)
	fmt.Println(string(r))

}
