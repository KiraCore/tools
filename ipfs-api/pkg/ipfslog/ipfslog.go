// Package provides minimal needed number of functions and settings
// for logging the app
package ipfslog

import (
	"github.com/sirupsen/logrus"
)

var log *logrus.Logger

func init() {
	log = logrus.New()
	log.SetLevel(5)
}

// TODO: add colored output for critical information

func Info(format string, v ...interface{}) {
	log.Infof(format, v...)
}

func Warn(format string, v ...interface{}) {
	log.Warnf(format, v...)
}

func Debug(format string, v ...interface{}) {
	log.Debugf(format, v...)
}

func Error(format string, v ...interface{}) {
	log.Errorf(format, v...)
}
