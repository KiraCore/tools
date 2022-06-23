// Package provides minimal needed number of functions and settings
// for logging the app
package ipfslog

import (
	"errors"
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

func SetDebugLvl(l int8) error {
	if l >= 0 && l < 8 {
		switch l {
		case 0:
			Log.SetOutput(ioutil.Discard)
		case 7:
			Log.SetLevel(logrus.TraceLevel)
		case 6:
			Log.SetLevel(logrus.DebugLevel)
		case 5:
			Log.SetLevel(logrus.InfoLevel)
		case 4:
			Log.SetLevel(logrus.WarnLevel)
		case 3:
			Log.SetLevel(logrus.ErrorLevel)
		case 2:
			Log.SetLevel(logrus.FatalLevel)
		case 1:
			Log.SetLevel(logrus.PanicLevel)
		}
	} else {
		return errors.New("verbocity should be in range 0 to 7")
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
