package main

import (
	"github.com/kiracore/tools/ipfs-api/pkg/cli"
	"github.com/kiracore/tools/ipfs-api/pkg/ipfslog"
	tp "github.com/kiracore/tools/ipfs-api/types"
)

func main() {
	cli.Start()
	if tp.V != 0 {
		ipfslog.Log.SetLevel(tp.LogLevelMap[tp.V])
	}

}
