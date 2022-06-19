package types

import (
	"io/fs"
)

type Keys struct {
	Api_key    string `json:"api_key,omitempty"`
	Api_secret string `json:"api_secret,omitempty"`
	JWT        string `json:"jwt,omitempty"`
}

type ExtendedFileInfo struct {
	Info         fs.FileInfo
	Path         string
	AbsoultePath string
}
