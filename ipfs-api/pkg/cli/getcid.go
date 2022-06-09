package cli

// TODO: Try to wrap data in node.UnixFS and after that to put this node into merkle DAG

import (
	"bufio"
	"encoding/hex"
	"fmt"
	"os"

	cid "github.com/ipfs/go-cid"
	mh "github.com/multiformats/go-multihash"
	"github.com/spf13/cobra"
)

var cidZeroCommand = &cobra.Command{
	Use:   "CID-v0 <filepath>",
	Short: "CID v0 hash calculator",
	Long:  "Get CID-v0 of the file",
	RunE:  cmdGetCIDv0,
}

var cidOneCommand = &cobra.Command{
	Use:   "CID-v1 <filepath>",
	Short: "CID v1 hash calculator",
	Long:  "Get CID-v1 of the file",
	RunE:  cmdGetCIDv1,
}

func cmdGetCIDv0(cmd *cobra.Command, args []string) error {
	prefix := cid.Prefix{
		Version:  0,
		Codec:    cid.DagProtobuf,
		MhType:   mh.SHA2_256,
		MhLength: -1,
	}

	file, _ := os.Open(args[0])

	defer file.Close()

	bytes := make([]byte, 32)
	for {
		_, err := file.Read(bytes)
		if err != nil {
			break
		}
	}

	cid, _ := prefix.Sum(bytes)
	fmt.Println(cid)
	return nil

}
func cmdGetCIDv1(cmd *cobra.Command, args []string) error {
	builder := cid.V1Builder{
		Codec:    cid.Raw,
		MhType:   mh.SHA2_256,
		MhLength: 32,
	}

	file, _ := os.Open(args[0])

	defer file.Close()

	rd := bufio.NewReader(file)
	data, _ := rd.ReadBytes(32)
	fmt.Println(len(data))
	fmt.Println(hex.EncodeToString(data))

	cid, _ := builder.Sum(data)
	fmt.Println(cid)

	return nil

}
