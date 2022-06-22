// Package provides minimal needed number of functions and settings
// for logging the app
package ipfslog

import (
	"io/ioutil"

	"github.com/sirupsen/logrus"
)

var Log *logrus.Logger

func init() {

	Log = logrus.New()
	Log.SetLevel(logrus.TraceLevel)
	Log.Out = ioutil.Discard

}

// TODO: add colored output for critical information

func Info(format string, v ...interface{}) {
	Log.Infof(format, v...)
}

func Warn(format string, v ...interface{}) {
	Log.Warnf(format, v...)
}

func Debug(format string, v ...interface{}) {
	Log.Debugf(format, v...)
}

func Error(format string, v ...interface{}) {
	Log.Errorf(format, v...)
}
