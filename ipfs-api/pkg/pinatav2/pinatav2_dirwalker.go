package pinatav2

import (
	"io/fs"
	"os"
	"path/filepath"
	"sync"

	log "github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
)

func (w *Walker) Walk(rootDir string) error {
	ap, err := filepath.Abs(rootDir)
	base := filepath.Base(ap)
	if err != nil {
		return err
	}

	var wg sync.WaitGroup
	var efi = []ExtendedFileInfo{}

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
				e := ExtendedFileInfo{}
				efi = append(efi, e.Set(info, fn, path))
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
	w.bulk = efi
	return nil

}
