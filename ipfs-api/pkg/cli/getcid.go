package cli

// TODO: Try to wrap data in node.UnixFS and after that to put this node into merkle DAG

import (
	"os"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	pnt "github.com/kiracore/tools/ipfs-api/pkg/pinatav1"
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
	f, _ := os.Open(args[0])
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		return err
	}

	bytes := make([]byte, fi.Size())
	rb, err := f.Read(bytes)

	if err != nil {
		return err
	}

	c, err := pnt.GetCidV0(bytes)
	if err != nil {
		log.Error("cmdGetCIDv1: failed to get the cid: %v", err)
	}
	log.Info("cid v1. hash: %v. bytes: %v", c, rb)

	return nil

}
func cmdGetCIDv1(cmd *cobra.Command, args []string) error {

	f, _ := os.Open(args[0])
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		return err
	}

	bytes := make([]byte, fi.Size())
	rb, err := f.Read(bytes)

	if err != nil {
		return err
	}

	c, err := pnt.GetCidV1(bytes)
	if err != nil {
		log.Error("cmdGetCIDv1: failed to get the cid: %v", err)
	}
	log.Info("cid v1. hash: %v. bytes: %v", c, rb)

	return nil

}
