package main

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"net/http/httputil"
	"os"
	"path/filepath"
)

func main() {

	url := "https://api.pinata.cloud/pinning/pinFileToIPFS"
	method := "POST"

	payload := &bytes.Buffer{}
	writer := multipart.NewWriter(payload)

	file, errFile1 := os.Open("/home/eugene/Code/go/src/github.com/kiracore/tools/ipfs-api/cmd/ipfs-api/test_dir1/test_file1.txt")
	defer file.Close()
	part1,
		errFile1 := writer.CreateFormFile("file", "dir/"+filepath.Base("/home/eugene/Code/go/src/github.com/kiracore/tools/ipfs-api/cmd/ipfs-api/test_dir1/test_file1.txt"))
	_, errFile1 = io.Copy(part1, file)
	if errFile1 != nil {
		fmt.Println(errFile1)
		return
	}
	_ = writer.WriteField("pinataOptions", "{\"cidVersion\": 1}")
	_ = writer.WriteField("pinataMetadata", "{\"name\": \"MyFile\", \"keyvalues\": {\"company\": \"Pinata\"}}")

	file1, errFile2 := os.Open("/home/eugene/Code/go/src/github.com/kiracore/tools/ipfs-api/cmd/ipfs-api/test_dir1/test_dir_2/test_file2.txt")
	defer file.Close()
	part2,
		errFile2 := writer.CreateFormFile("file", "dir/"+filepath.Base("/home/eugene/Code/go/src/github.com/kiracore/tools/ipfs-api/cmd/ipfs-api/test_dir1/test_dir_2/test_file2.txt"))
	_, errFile2 = io.Copy(part2, file1)
	if errFile2 != nil {
		fmt.Println(errFile2)
		return
	}
	_ = writer.WriteField("pinataOptions", "{\"cidVersion\": 1}")
	_ = writer.WriteField("pinataMetadata", "{\"name\": \"MyFile\", \"keyvalues\": {\"company\": \"Pinata\"}}")
	err := writer.Close()
	if err != nil {
		fmt.Println(err)
		return
	}

	client := &http.Client{}
	req, err := http.NewRequest(method, url, payload)

	if err != nil {
		fmt.Println(err)
		return
	}
	req.Header.Add("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiIzNWRjZDc0OC1mMDE3LTQ0NjEtYTdiOC0wOGVkZDc3MDU2NzciLCJlbWFpbCI6InlhaWV2Z2VuaXlAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBpbl9wb2xpY3kiOnsicmVnaW9ucyI6W3siaWQiOiJGUkExIiwiZGVzaXJlZFJlcGxpY2F0aW9uQ291bnQiOjF9XSwidmVyc2lvbiI6MX0sIm1mYV9lbmFibGVkIjpmYWxzZSwic3RhdHVzIjoiQUNUSVZFIn0sImF1dGhlbnRpY2F0aW9uVHlwZSI6InNjb3BlZEtleSIsInNjb3BlZEtleUtleSI6ImRiYzYzNWMxYzFkZDY5YTRhMDE4Iiwic2NvcGVkS2V5U2VjcmV0IjoiNWYwZDVjOTdhNDc0YzkxYTMzMzU4ODZlNjA1MDA4NTFjNzY3ZjYyYmE1OTI5MDQ3ODMzOThlYTlmMDgyZmIxYSIsImlhdCI6MTY1NTI4OTQ2NX0.Zooi19QTZJDR6mueWpvAnD_qaG3T9LtPpInI_lTBrGo")

	req.Header.Set("Content-Type", writer.FormDataContentType())
	requestDump, err := httputil.DumpRequest(req, true)
	if err != nil {
		fmt.Println(err)

	}
	fmt.Println(string(requestDump))

	res, err := client.Do(req)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer res.Body.Close()

	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(string(body))
}
