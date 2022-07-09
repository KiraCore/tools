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

safeWget /usr/local/bin/cosign_arm64 "https://github.com/sigstore/cosign/releases/download/v1.7.2/cosign-$(getPlatform)-arm64" \
    ./release-cosign.pub
safeWget /usr/local/bin/cosign_amd64 "https://github.com/sigstore/cosign/releases/download/v1.7.2/cosign-$(getPlatform)-amd64" \
    ./release-cosign.pub

chmod 755 /usr/local/bin/cosign_amd64 /usr/local/bin/cosign_arm64
cosign_$(getArch) version

SYSCTRL_DESTINATION=/usr/bin/systemctl2
safeWget $SYSCTRL_DESTINATION \
 https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/9cbe1a00eb4bdac6ff05b96ca34ec9ed3d8fc06c/files/docker/systemctl.py \
 "e02e90c6de6cd68062dadcc6a20078c34b19582be0baf93ffa7d41f5ef0a1fdd"

chmod -v 555 $SYSCTRL_DESTINATION
systemctl2 version

#################################################################
echoWarn "TEST: setVar"
TEST_FILE=/tmp/setVar.test
rm -rfv $TEST_FILE && touch $TEST_FILE

BASH_UTIL_TEST_1=""
BASH_UTIL_TEST_2=""

setVar BASH_UTIL_TEST_1 ":) Oo" $TEST_FILE
setVar BASH_UTIL_TEST_2 "test" $TEST_FILE
setVar BASH_UTIL_TEST_1 ":) Oo !" $TEST_FILE

source $TEST_FILE

[ "$BASH_UTIL_TEST_1" != ":) Oo !" ]  && echoErr "ERROR: Expected 'BASH_UTIL_TEST_1' to be ':) Oo !', but got '$BASH_UTIL_TEST_1'" && exit 1
[ "$BASH_UTIL_TEST_2" != "test" ]  && echoErr "ERROR: Expected 'BASH_UTIL_TEST_2' to be ':) Oo !', but got '$BASH_UTIL_TEST_2'" && exit 1

#################################################################
echoWarn "TEST: date2unix"

TMP_DATE_1=$(date)
TMP_DATE_1_RESULT_1=$(date2unix "$TMP_DATE_1")
TMP_DATE_1_RESULT_2=$(echo "$TMP_DATE_1" | date2unix)

( (! $(isNaturalNumber "$TMP_DATE_1_RESULT_1")) || [ $TMP_DATE_1_RESULT_1 -lt 1 ] || [ "$TMP_DATE_1_RESULT_1" != "$TMP_DATE_1_RESULT_2" ]  ) && \
 echoErr "ERROR: Expected 'TMP_DATE_1_RESULT_1' to be greter than 0 and equal to 'TMP_DATE_1_RESULT_2', but got '$TMP_DATE_1_RESULT_1' && '$TMP_DATE_1_RESULT_2' from '$TMP_DATE_1'" && exit 1 || echoInfo "INFO: Test 1 passed"

TMP_DATE_3="1970-01-01T00:00:00"
TMP_DATE_3_EXPECTED="0"
TMP_DATE_3_RESULT_1=$(date2unix "$TMP_DATE_3")
TMP_DATE_3_RESULT_2=$(echo "$TMP_DATE_3" | date2unix)
TMP_DATE_3_RESULT_3=$(date2unix "")
TMP_DATE_3_RESULT_4=$(echo "" | date2unix)

( (! $(isNaturalNumber "$TMP_DATE_3_RESULT_1")) || [ "${TMP_DATE_3_RESULT_1},${TMP_DATE_3_RESULT_2},${TMP_DATE_3_RESULT_3},${TMP_DATE_3_RESULT_4}" != "0,0,0,0" ] ) && \
 echoErr "ERROR: Expected 'TMP_DATE_3_RESULT_1' to be equal to 'TMP_DATE_3_RESULT_2', 'TMP_DATE_3_RESULT_3', 'TMP_DATE_3_RESULT_4' and '$TMP_DATE_3_EXPECTED', but got '$TMP_DATE_3_RESULT_1', '$TMP_DATE_3_RESULT_2', '$TMP_DATE_3_RESULT_3' && '$TMP_DATE_3_RESULT_4' from '$TMP_DATE_3' && ''" && exit 1 || echoInfo "INFO: Test 2 passed"

TMP_DATE_2="2022-06-24T11:35:30.636Z"
TMP_DATE_2_EXPECTED="1656070530"
TMP_DATE_2_RESULT_1=$(date2unix "$TMP_DATE_2")
TMP_DATE_2_RESULT_2=$(echo "$TMP_DATE_2" | date2unix)

( (! $(isNaturalNumber "$TMP_DATE_2_RESULT_1")) || [ $TMP_DATE_2_RESULT_1 -ne $TMP_DATE_2_EXPECTED ] || [ "$TMP_DATE_2_RESULT_1" != "$TMP_DATE_2_RESULT_2" ] ) && \
 echoErr "ERROR: Expected 'TMP_DATE_2_RESULT_1' to be equal to 'TMP_DATE_2_RESULT_2' and '$TMP_DATE_2_EXPECTED', but got '$TMP_DATE_2_RESULT_1' && '$TMP_DATE_2_RESULT_2' from '$TMP_DATE_2'" && exit 1 || echoInfo "INFO: Test 3 passed"

#################################################################
echoWarn "TEST: versionToNumber"

[[ $(versionToNumber "v1.2.3.4") -lt $(versionToNumber "v0.999.999.999") ]] && \
 echoErr "ERROR: Version 'v1.2.3.4' must be greater than v0.999.999.999" && exit 1 || echoInfo "INFO: Test 1 passed"

[[ $(versionToNumber "v0.2.3.4") -gt $(versionToNumber "v0.999.999.999") ]] && \
 echoErr "ERROR: Version 'v0.2.3.4' must be less than v0.999.999.999" && exit 1 || echoInfo "INFO: Test 2 passed"

[ "$(versionToNumber v1.2.3.4)" != "1000200030004" ] && \
 echoErr "ERROR: Version 'v1.2.3.4' must be equal to 1000200030004, but got '$(versionToNumber v1.2.3.4)'" && exit 1 || echoInfo "INFO: Test 3 passed"

[ "$(versionToNumber v1.2.3-rc.4)" != "1000200030004" ] && \
 echoErr "ERROR: Version 'v1.2.3-rc.4' must be equal to 1000200030004, but got '$(versionToNumber v1.2.3-rc.4)'" && exit 1 || echoInfo "INFO: Test 4 passed"

[ "$(versionToNumber v1.2.3-alpha.4)" != "1000200030004" ] && \
 echoErr "ERROR: Version 'v1.2.3-alpha.4' must be equal to 1000200030004, but got '$(versionToNumber v1.2.3-alpha.4)'" && exit 1 || echoInfo "INFO: Test 5 passed"

( [ "$(versionToNumber v1.2.3)" != "1000200030000" ] || "$(echo "1.2.3" | versionToNumber)" != "1000200030000" ]  ) && \
 echoErr "ERROR: Version 'v1.2.3' must be equal to 1000200030004, but got '$(versionToNumber v1.2.3)'" && exit 1 || echoInfo "INFO: Test 6 passed"

( [ "$(echo "" | versionToNumber)" != "0" ] || [ "$(versionToNumber "")" != "0" ] ) && \
 echoErr "ERROR: Version '' must be equal to 0" && exit 1 || echoInfo "INFO: Test 7 passed"

#################################################################
echoWarn "TEST: setTomlVar"

cat > ./test.toml << EOL
aaa = "aaa"
b = 2
cc_cc = true
ddd = [ "aaa", "b", "cc_cc", ]

[tag]
aaa = "aaa"
b = 2
cc_cc = true
ddd = "empty test"

[tag_2]
aaa = "aaa"
b = 2
cc_cc = true
ddd = "whitespace test"
EOL

cat > ./expected.toml << EOL
aaa = "Hello World"
b = 2
cc_cc = true
ddd = [ "aaa", "b2", "cc_cc", ]

[tag]
aaa = "aaa"
b = 3
cc_cc = true
ddd = ""

[tag_2]
aaa = "aaa"
b = -4
cc_cc = false
ddd = "   "
EOL

setTomlVar "" aaa "Hello World" ./test.toml
setTomlVar "[base]" ddd '[ "aaa", "b2", "cc_cc", ]' ./test.toml
setTomlVar "[tag]" b 3 ./test.toml
setTomlVar "[tag]" ddd "" ./test.toml
setTomlVar "[tag_2]" b -4 ./test.toml
setTomlVar "[tag_2]" cc_cc false ./test.toml
setTomlVar "[tag_2]" ddd "   " ./test.toml

[ "$(sha256 ./test.toml)" != "$(sha256 ./expected.toml)" ] && \
 echoNErr "\nERROR: Expected ' ./test.toml' to have a hash '$(sha256 ./test.toml)', but got '$(sha256 ./expected.toml)':\n$(cat ./test.toml)\n" && exit 1 || echoInfo "INFO: Test 1 passed"

#################################################################
echoWarn "TEST: getTomlVarName"

VAR_NAME=$(getTomlVarName 1 ./test.toml) && VAR_NAME_EXP="[base] aaa"
[ "$VAR_NAME" != "$VAR_NAME_EXP" ] && \
 echoNErr "\nERROR: Expected variable name 1 to be '$VAR_NAME', but got $VAR_NAME_EXP" && exit 1 || echoInfo "INFO: Test 1 passed"

VAR_NAME=$(getTomlVarName 3 ./test.toml) && VAR_NAME_EXP="[base] cc_cc"
[ "$VAR_NAME" != "$VAR_NAME_EXP" ] && \
 echoNErr "\nERROR: Expected variable name 3 to be '$VAR_NAME', but got $VAR_NAME_EXP" && exit 1 || echoInfo "INFO: Test 2 passed"

VAR_NAME=$(getTomlVarName 8 ./test.toml) && VAR_NAME_EXP="[tag] ddd"
[ "$VAR_NAME" != "$VAR_NAME_EXP" ] && \
 echoNErr "\nERROR: Expected variable name 8 to be '$VAR_NAME', but got $VAR_NAME_EXP" && exit 1 || echoInfo "INFO: Test 3 passed"

VAR_NAME=$(getTomlVarName 10 ./test.toml) && VAR_NAME_EXP="[tag_2] b"
[ "$VAR_NAME" != "$VAR_NAME_EXP" ] && \
 echoNErr "\nERROR: Expected variable name 10 to be '$VAR_NAME', but got $VAR_NAME_EXP" && exit 1 || echoInfo "INFO: Test 4 passed"

#################################################################

echoInfo "INFO: Successsfully executed all bash-utils test cases, elapsed $(prettyTime $(timerSpan))"
