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

# testing SHA & MD5
TEST_FILE=/tmp/testfile.tmp
echo "Hello World" > $TEST_FILE
FILE_SHA256=$(sha256 $TEST_FILE) && EXPECTED_FILE_SHA256="d2a84f4b8b650937ec8f73cd8be2c74add5a911ba64df27458ed8229da804a26"
FILE_MD5=$(md5 $TEST_FILE) && EXPECTED_FILE_MD5="e59ff97941044f85df5297e1c302d260"

if (!$(isSHA256 $FILE_SHA256)) || [ "$FILE_SHA256" != "$EXPECTED_FILE_SHA256" ] ; then
    echoErr "ERROR: Expected '$TEST_FILE' sha256 to be '$EXPECTED_FILE_SHA256', but got '$FILE_SHA256'"
    exit 1
fi

if (!$(isMD5 $FILE_MD5)) || [ "$FILE_MD5" != "$EXPECTED_FILE_MD5" ] ; then
    echoErr "ERROR: Expected '$TEST_FILE' md5 to be '$EXPECTED_FILE_MD5', but got '$FILE_SHA256'"
    exit 1
fi

# hash of non existent file should be empty string
rm -fv $TEST_FILE
FILE_SHA256=$(sha256 $TEST_FILE) && EXPECTED_FILE_SHA256=""
FILE_MD5=$(md5 $TEST_FILE) && EXPECTED_FILE_MD5=""

if ($(isSHA256 "$FILE_MD5")) || [ "$FILE_SHA256" != "$EXPECTED_FILE_SHA256" ] ; then
    echoErr "ERROR: Expected '$TEST_FILE' sha256 to be '$EXPECTED_FILE_SHA256', but got '$FILE_SHA256'"
    exit 1
fi

if ($(isMD5 "$FILE_MD5")) || [ "$FILE_MD5" != "$EXPECTED_FILE_MD5" ] ; then
    echoErr "ERROR: Expected '$TEST_FILE' md5 to be '$EXPECTED_FILE_MD5', but got '$FILE_SHA256'"
    exit 1
fi

echoInfo "INFO: Successsfully executed all bash-utils test cases, elapsed $(prettyTime $(timerSpan))"
