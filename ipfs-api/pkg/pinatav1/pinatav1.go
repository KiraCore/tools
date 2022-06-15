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
	"strings"
	"time"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	tp "github.com/kiracore/tools/ipfs-api/types"
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

// Adding HTML form to multipart body
func addForm(bw *multipart.Writer, filePath string) error {
	// wrap in struct
	data := strings.Split(filePath, ":")
	fileName := data[0]
	path := data[1]

	f, err := os.Open(path)
	if err != nil {
		log.Error("addform: can't open the file")
		defer f.Close()
		return err

	}
	fi, err := f.Stat()
	if err != nil {
		log.Error("addform: can't read stats from the given path")
		return err
	}
	defer f.Close()

	//MIME Header setup
	// if not a standalone directory - add MIME.header
	if !fi.IsDir() {
		h := make(textproto.MIMEHeader)
		h.Set("Content-Disposition",
			fmt.Sprintf(`form-data; name="file"; filename="%s"`, fileName))
		h.Set("Content-Type", "application/octet-stream")

		bw.WriteField("pinataOptions", `{"cidVersion": 1}`)
		bw.WriteField("pinataMetadata", fmt.Sprintf(`{"name": "%v"}`, fileName))

		content, _ := bw.CreatePart(h)
		io.Copy(content, f)

	}
	return nil
}

//Wrapping HTML forms in the request body
func createReqBody(filePaths []string) (string, io.Reader, error) {
	// creating a pipe
	pipeReader, pipeWriter := io.Pipe()
	// creating writer for multipart request
	bodyWriter := multipart.NewWriter(pipeWriter)

	// calling for a goroutine to add all forms found by walker
	go func() {
		for _, filePath := range filePaths {
			if err := addForm(bodyWriter, filePath); err != nil {
				log.Error("createbody: failed to add form to multipart request")
				return
			}
			log.Info("pinned: %v", filePath)
		}

		bodyWriter.Close()
		pipeWriter.Close()

	}()
	return bodyWriter.FormDataContentType(), pipeReader, nil

}

//Parsing directory tree recursively. NB: SLOW
func walker(rootDir string) []string {
	// add error handling
	var res []string
	wout := make(chan string)

	// calling for a goroutine which will yield res through chan
	go func() {
		defer close(wout) // Chan is empty can be closed
		base := filepath.Base(rootDir) + "/"
		err := filepath.Walk(rootDir, func(path string, info fs.FileInfo, err error) error {
			if err != nil {
				return err
			}

			rel, err := filepath.Rel(rootDir, path)
			if err != nil {
				log.Error("walker: can't get relative path for %v. err: %v", path, err)
			}
			fn := filepath.Clean(base + rel)
			wout <- fn + ":" + path
			return nil
		})
		if err != nil {
			return
		}
	}()

	for {
		if msg, state := <-wout; state {
			res = append(res, msg)
		} else {
			break
		}

	}
	return res

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
	req.Header.Add("Content-Type", contType)
	req.Header.Add("pinata_api_key", keys.Api_key)
	req.Header.Add("pinata_secret_api_key", keys.Api_secret)

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
		log.Error("Failed to io.Copy")

	}
	defer resp.Body.Close()
	r, _ := io.ReadAll(resp.Body)
	fmt.Println(string(r))

}
