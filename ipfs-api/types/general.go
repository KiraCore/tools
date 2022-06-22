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
	logrus.TraceLevel,
	logrus.DebugLevel,
	logrus.InfoLevel,
	logrus.WarnLevel,
	logrus.ErrorLevel,
	logrus.FatalLevel,
	logrus.PanicLevel,
}

var V int32
