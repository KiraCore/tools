// Package provides minimal needed number of functions and settings
// for logging the app
package ipfslog

import (
	"io/ioutil"

	"github.com/sirupsen/logrus"
)

var Log *logrus.Logger

// log.Trace("Something very low level.")
// log.Debug("Useful debugging information.")
// log.Info("Something noteworthy happened!")
// log.Warn("You should probably take a look at this.")
// log.Error("Something failed but I'm not quitting.")
// // Calls os.Exit(1) after logging
// log.Fatal("Bye.")
// // Calls panic() after logging
// log.Panic("I'm bailing.")

func SetDebugLvl(l bool) error {

	switch l {
	case false:
		Log.SetOutput(ioutil.Discard)
	case true:
		Log.SetLevel(logrus.TraceLevel)

	}

	return nil
}
func init() {

	Log = logrus.New()
	//Log.SetLevel(logrus.InfoLevel)

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
