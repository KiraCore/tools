package types

import "io/fs"

type Keys struct {
	Api_key    string
	Api_secret string
	JWT        string
}

type ExtendedFileInfo struct {
	Info         fs.FileInfo
	Path         string
	AbsoultePath string
}
