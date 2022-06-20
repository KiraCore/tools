package types

import (
	"io/fs"

	"github.com/sirupsen/logrus"
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

var LogLevelMap = []logrus.Level{
	1: logrus.TraceLevel,
	2: logrus.DebugLevel,
	3: logrus.InfoLevel,
	4: logrus.WarnLevel,
	5: logrus.ErrorLevel,
	6: logrus.FatalLevel,
	7: logrus.PanicLevel,
}

var V int32
