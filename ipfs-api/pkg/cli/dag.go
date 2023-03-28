package cli

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"time"

	"github.com/ipfs/go-cid"
	"github.com/ipfs/go-libipfs/blocks"
	"github.com/ipfs/go-unixfsnode/data/builder"
	"github.com/ipld/go-car/v2"
	"github.com/ipld/go-car/v2/blockstore"
	dagpb "github.com/ipld/go-codec-dagpb"
	"github.com/ipld/go-ipld-prime"
	cidlink "github.com/ipld/go-ipld-prime/linking/cid"
	"github.com/multiformats/go-multicodec"
	"github.com/multiformats/go-multihash"
	"github.com/spf13/cobra"
)

var (
	out    string
	verCAR int8
	export bool
)

var dagCommand = &cobra.Command{
	Use:   "dag [OPTION]... PATH...",
	Short: "Import/export dag",
	Long:  "Import/export dag as a car file of specific version or print CID address of the given directory",
	Args:  cobra.MatchAll(cobra.ExactArgs(1), validPath),
	RunE:  dagCmd,
}

// Check the path if it is valid and exist
func validPath(cmd *cobra.Command, args []string) error {
	// Clean the input path to eliminate redundant separators, dots, etc.
	cleanedPath := filepath.Clean(args[0])
	// Check if the cleaned path exists and if it's a file or a directory.
	_, err := os.Stat(cleanedPath)
	if err != nil {
		if os.IsNotExist(err) {
			fmt.Println("path does not exist", cleanedPath)
		} else {
			fmt.Println("malformed path", err)
		}
		return err
	}

	return nil
}

func dagCmd(cmd *cobra.Command, args []string) error {
	if !export {
		createDag(cmd.Flags().Arg(0))
	}
	return nil
}

func createDag(path string) error {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	// Check if the required flags are set
	if out == "" {
		flag.Usage()
		return fmt.Errorf("Error: a file destination must be specified\n")
	}

	// Make a cid with the right length(32 bytes) that we eventually will patch with the root.
	hasher, err := multihash.GetHasher(multihash.SHA2_256)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		return err
	}

	// Variable is a byte slice that represents the result of hashing an empty byte slice using the SHA2-256 hash function
	digest := hasher.Sum([]byte{})

	// Create multihash object, which includes the hash function identifier (SHA2-256) and the digest
	hash, err := multihash.Encode(digest, multihash.SHA2_256)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		return err
	}

	// Create a new CID with DagPb codec. proxyRoot is an object of interface type cid.Cid
	proxyRoot := cid.NewCidV1(uint64(multicodec.DagPb), hash)

	// Create variable wich holds car configuration as car.Option interface
	options := []car.Option{}

	// Switch between versions
	switch verCAR {
	case 1:
		options = []car.Option{blockstore.WriteAsCarV1(true)}
	case 2:
		// already the default
	default:
		fmt.Println("Error: invalid CAR version", verCAR)
		flag.Usage()
		return err
	}
	// Creates a car file
	cdest, err := blockstore.OpenReadWrite(out, []cid.Cid{proxyRoot}, options...)
	if err != nil {
		fmt.Println("Error:", err)
		return err
	}

	// adding files from given path to string array
	paths := []string{} // recursively add every file path
	if err := filepath.WalkDir(path, func(path string, d fs.DirEntry, err error) error {

		paths = append(paths, path)

		return nil

	}); err != nil {

	}
	fmt.Println("Paths: ", paths)

	root, err := writeFiles(ctx, cdest, paths...)
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
		return err
	}

	if err := cdest.Finalize(); err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
		return err
	}

	car.ReplaceRootsInFile(out, []cid.Cid{root})
	return nil

}

func writeFiles(ctx context.Context, bs *blockstore.ReadWrite, paths ...string) (cid.Cid, error) {
	ls := cidlink.DefaultLinkSystem()
	ls.TrustedStorage = true
	ls.StorageReadOpener = func(_ ipld.LinkContext, l ipld.Link) (io.Reader, error) {
		cl, ok := l.(cidlink.Link)
		if !ok {
			return nil, fmt.Errorf("not a cidlink")
		}
		blk, err := bs.Get(ctx, cl.Cid)
		if err != nil {
			return nil, err
		}
		return bytes.NewBuffer(blk.RawData()), nil
	}
	ls.StorageWriteOpener = func(_ ipld.LinkContext) (io.Writer, ipld.BlockWriteCommitter, error) {
		buf := bytes.NewBuffer(nil)
		return buf, func(l ipld.Link) error {
			cl, ok := l.(cidlink.Link)
			if !ok {
				return fmt.Errorf("not a cidlink")
			}
			blk, err := blocks.NewBlockWithCid(buf.Bytes(), cl.Cid)
			if err != nil {
				return err
			}
			bs.Put(ctx, blk)
			return nil
		}, nil
	}

	topLevel := make([]dagpb.PBLink, 0, len(paths))
	for _, p := range paths {
		l, size, err := builder.BuildUnixFSRecursive(p, &ls)
		if err != nil {
			return cid.Undef, err
		}
		fmt.Println(p, l, l.String())
		name := filepath.Base(p)
		entry, err := builder.BuildUnixFSDirectoryEntry(name, int64(size), l)
		topLevel = append(topLevel, entry)
	}

	// make a directory for the file(s).
	fmt.Println(topLevel)
	root, _, err := builder.BuildUnixFSDirectory(topLevel, &ls)
	if err != nil {
		return cid.Undef, nil
	}
	fmt.Println("root string: ", root.String())

	rcl, ok := root.(cidlink.Link)
	if !ok {
		return cid.Undef, fmt.Errorf("could not interpret %s", root)
	}
	fmt.Println("return string: ", root.(cidlink.Link).Cid)

	return rcl.Cid, nil
}
