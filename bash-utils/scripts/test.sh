#!/usr/bin/env bash
set -e
set +x
. /etc/profile
set -x

. ./bash-utils.sh

timerStart
echoInfo "INFO: Starting bash-utils $(bashUtilsVersion) testing..."

sleep 2

if [[ $(timerSpan) -lt 2 ]] ; then
    echoErr "ERROR: Failed testing timeStar, timeSpan, expected at least 2 seconds to elapse, but got '$(timerSpan)'"
    exit 1
elif [[ $(timerSpan) -gt 10 ]] ; then
    echoErr "ERROR: Failed testing timeSpan, expected less then 10 seconds to elapse, but got '$(timerSpan)'"
    exit 1
fi

timerPause
TMP_TIMER_SPAN=$(timerSpan)

globDel UTILS_TESTS
globSet UTILS_TESTS "test"

if [ "$(globGet utils_tests)" != "test" ] ; then
    echoErr "ERROR: Failed testing globSet, globDel, globGet"
    exit 1
fi

sleep 1

if [[ $(timerSpan) -ne $TMP_TIMER_SPAN ]] ; then
    echoErr "ERROR: Failed testing timerPause, timerSpan, expected timer span to NOT change, got '$(timerSpan)', expected '$TMP_TIMER_SPAN'"
    exit 1
fi

timerUnpause

sleep 1

if [[ $(timerSpan) -lt 3 ]] ; then
    echoErr "ERROR: Failed testing timerUnpause, timerSpan, expected at least 3 seconds to elapse, but got '$(timerSpan)'"
    exit 1
fi

echoInfo "INFO: Successsfully executed all bash-utils test cases, elapsed $(prettyTime $(timerSpan))"
