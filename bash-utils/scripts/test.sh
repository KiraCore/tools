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

#################################################################
echoWarn "TEST: SHA & MD5"
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

#################################################################
echoWarn "TEST: hash of non existent file should be empty string"
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

#################################################################
echoWarn "TEST: safeWget"
rm -fv /usr/local/bin/cosign_amd64 /usr/local/bin/cosign_arm64
rm -rfv /tmp/downloads

safeWget /usr/local/bin/cosign_arm64 "https://github.com/sigstore/cosign/releases/download/v1.7.2/cosign-$(getPlatform)-arm64" \
    "2448231e6bde13722aad7a17ac00789d187615a24c7f82739273ea589a42c94b,80f80f3ef5b9ded92aa39a9dd8e028f5b942a3b6964f24c47b35e7f6e4d18907"
safeWget /usr/local/bin/cosign_amd64 "https://github.com/sigstore/cosign/releases/download/v1.7.2/cosign-$(getPlatform)-amd64" \
    "2448231e6bde13722aad7a17ac00789d187615a24c7f82739273ea589a42c94b,80f80f3ef5b9ded92aa39a9dd8e028f5b942a3b6964f24c47b35e7f6e4d18907"

chmod 755 /usr/local/bin/cosign_amd64 /usr/local/bin/cosign_arm64
cosign_$(getArch) version

cat > ./release-cosign.pub << EOL
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhyQCx0E9wQWSFI9ULGwy3BuRklnt
IqozONbbdbqz11hlRJy9c7SG+hdcFl9jE9uE/dwtuwU2MqU9T/cN0YkWww==
-----END PUBLIC KEY-----
EOL

rm -fv /usr/local/bin/cosign_amd64 /usr/local/bin/cosign_arm64

safeWget /usr/local/bin/cosign_arm64 "https://github.com/sigstore/cosign/releases/download/v1.7.2/cosign-$(toLower $(uname))-arm64" \
    ./release-cosign.pub
safeWget /usr/local/bin/cosign_amd64 "https://github.com/sigstore/cosign/releases/download/v1.7.2/cosign-$(toLower $(uname))-amd64" \
    ./release-cosign.pub

chmod 755 /usr/local/bin/cosign_amd64 /usr/local/bin/cosign_arm64
cosign_$(getArch) version

echoInfo "INFO: Successsfully executed all bash-utils test cases, elapsed $(prettyTime $(timerSpan))"
