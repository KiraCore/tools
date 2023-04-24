package pinatav2

import "io/fs"

func (e ExtendedFileInfo) Set(fs fs.FileInfo, p string, ap string) ExtendedFileInfo {
	return ExtendedFileInfo{info: fs, path: p, absoultePath: ap}
}
func (e ExtendedFileInfo) Abs() string {
	return e.absoultePath
}

func (e ExtendedFileInfo) Path() string {
	return e.path
}
