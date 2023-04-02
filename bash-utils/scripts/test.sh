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
echoWarn "TEST: bashUtilsVersion"
ver=$(bashUtilsVersion)
ver_expected=$(../scripts/version.sh)

[ "$ver" != "$ver_expected" ] && \
 echoErr "ERROR: Verison check failed, expected 'bashUtilsVersion' to return '$ver_expected', but got '$ver'" && exit 1 || echoInfo "INFO: Test 1 passed"

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
echoWarn "TEST: ipfsGet"

TEST_FILE="/tmp/test.file"
rm -fv $TEST_FILE
ipfsGet "$TEST_FILE" "QmNPG6RQSDa6jKqaPbNDyP9iM9CRxmv1kaHaPMCw2aQceb"

if ($(isFileEmpty $TEST_FILE)); then
    echoErr "ERROR: Expected public ipfs file 'QmNPG6RQSDa6jKqaPbNDyP9iM9CRxmv1kaHaPMCw2aQceb' to NOT be empty"
    exit 1
fi

rm -fv $TEST_FILE
ipfsGet --timeout="30" --file="$TEST_FILE" --cid="QmNPG6RQSDa6jKqaPbNDyP9iM9CRxmv1kaHaPMCw2aQcec" --url="https://ipfs.snggle.com/ipfs" || :

if (! $(isFileEmpty $TEST_FILE)); then
    echoErr "ERROR: Expected non existent file to be empty when attempted to be downloaded from IPFS"
    exit 1
fi

#################################################################
echoWarn "TEST: safeWget"
rm -fv /usr/local/bin/cosign_amd64 /usr/local/bin/cosign_arm64
rm -rfv /tmp/downloads

# safe fetch with public key from IPFS and grab default sig file
TEST_FILE="/tmp/bash-utils.sh.tmp"
safeWget "$TEST_FILE" https://github.com/KiraCore/tools/releases/download/v0.2.20/bash-utils.sh QmeqFDLGfwoWgCy2ZEFXerVC5XW8c5xgRyhK5bLArBr2ue
FILE_SHA256=$(sha256 $TEST_FILE) && EXPECTED_FILE_SHA256="0b1d5565448a94c5e7717d11c11150b4dd7992ac2227dd253067420102ce5c71"

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
setTomlVar "tag" ddd "" ./test.toml
setTomlVar "[tag_2]" b -4 ./test.toml
setTomlVar "tag_2" cc_cc false ./test.toml
setTomlVar "[tag_2]" ddd "   " ./test.toml

[ "$(sha256 ./test.toml)" != "$(sha256 ./expected.toml)" ] && \
 echoNErr "\nERROR: Expected ' ./test.toml' to have a hash '$(sha256 ./test.toml)', but got '$(sha256 ./expected.toml)':\n$(cat ./test.toml)\n" && exit 1 || echoInfo "INFO: Test 1 passed"

#################################################################
echoWarn "TEST: getTomlVarName"

VAR_NAME=$(getTomlVarName 1 ./test.toml) && VAR_NAME_EXP="[base] aaa"
[ "$VAR_NAME" != "$VAR_NAME_EXP" ] && \
 echoErr "ERROR: Expected variable name 1 to be '$VAR_NAME', but got $VAR_NAME_EXP" && exit 1 || echoInfo "INFO: Test 1 passed"

VAR_NAME=$(getTomlVarName 3 ./test.toml) && VAR_NAME_EXP="[base] cc_cc"
[ "$VAR_NAME" != "$VAR_NAME_EXP" ] && \
 echoErr "ERROR: Expected variable name 3 to be '$VAR_NAME', but got $VAR_NAME_EXP" && exit 1 || echoInfo "INFO: Test 2 passed"

VAR_NAME=$(getTomlVarName 8 ./test.toml) && VAR_NAME_EXP="[tag] ddd"
[ "$VAR_NAME" != "$VAR_NAME_EXP" ] && \
 echoErr "ERROR: Expected variable name 8 to be '$VAR_NAME', but got $VAR_NAME_EXP" && exit 1 || echoInfo "INFO: Test 3 passed"

VAR_NAME=$(getTomlVarName 10 ./test.toml) && VAR_NAME_EXP="[tag_2] b"
[ "$VAR_NAME" != "$VAR_NAME_EXP" ] && \
 echoErr "ERROR: Expected variable name 10 to be '$VAR_NAME', but got $VAR_NAME_EXP" && exit 1 || echoInfo "INFO: Test 4 passed"

#################################################################
echoWarn "TEST: getTomlVarNames"

getTomlVarNames ./test.toml > ./names_test.toml

cat > ./expected.toml << EOL
[base] aaa
[base] b
[base] cc_cc
[base] ddd
[tag] aaa
[tag] b
[tag] cc_cc
[tag] ddd
[tag_2] aaa
[tag_2] b
[tag_2] cc_cc
[tag_2] ddd
EOL

[ "$(sha256 ./names_test.toml)" != "$(sha256 ./expected.toml)" ] && \
 echoNErr "\nERROR: Expected ' ./names_test.toml' to have a hash '$(sha256 ./names_test.toml)', but got '$(sha256 ./expected.toml)':\n$(cat ./names_test.toml)\n" && exit 1 || echoInfo "INFO: Test 1 passed"

#################################################################
echoWarn "TEST: setLastLineBySubStrOrAppend"

cat > ./test.txt << EOL
10.1.0.2 registry.local
10.2.0.2 validator.local
10.3.0.2 interx.local
127.0.0.1 localhost
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOL

setLastLineBySubStrOrAppend "interx.local" "172.16.0.2 interx.local" ./test.txt
setLastLineBySubStrOrAppend "ip6-allhos" "ff02::4 ip6-allhosts2" ./test.txt
setLastLineBySubStrOrAppend "ip6-mcastprefix" "" ./test.txt
sort -u ./test.txt -o ./test.txt

cat > ./expected.txt << EOL
10.1.0.2 registry.local
10.2.0.2 validator.local
127.0.0.1 localhost
172.16.0.2 interx.local
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::4 ip6-allhosts2
EOL

[ "$(sha256 ./test.txt)" != "$(sha256 ./expected.txt)" ] && \
 echoNErr "\nERROR: Expected ' ./test.txt' to have a hash '$(sha256 ./test.txt)', but got '$(sha256 ./expected.txt)':\n$(cat ./test.txt)\n" && exit 1 || echoInfo "INFO: Test 1 passed"
#################################################################
echoWarn "TEST: getArgs"

test0="aaa"
getArgs -test1="test 1" --test_2="te\st 2" -t3='t3' -e="t 4" --p="test5" -z=" \"  :)" --l-ol=lol --test0=

RES="${test1}${test0}${test_2}${t3}${e}${p}${z}${l_ol}"
RES_EXP="test 1te\st 2t3t 4test5 \"  :)lol"

[ "$RES" != "$RES_EXP" ] && \
 echoErr "ERROR: Expected args parsing result to be '$RES_EXP', but got '$RES'" && exit 1 || echoInfo "INFO: Test 1 passed"

#################################################################
echoWarn "TEST: isCID"

CID_0="QmcRD4wkPPi6dig81r5sLj9Zm1gDCL4zgpEj9CfuRrGbzF"
CID_1="bafybeigrf2dwtpjkiovnigysyto3d55opf6qkdikx6d65onrqnfzwgdkfa"
CID_e0="pmcRD4wkPPi6dig81r5sLj9Zm1gDCL4zgpEj9CfuRrGbzF"
CID_e1="bafybeigrf2dwtpjkiovnigysyto3d55of6qkdikx6d65onrqnfzwgdkfa"

(! $(isCID $CID_0)) && echoErr "ERROR: Expected '$CID_0' to be a valid CID, but got false response" && exit 1 || echoInfo "INFO: Test 1 passed"
(! $(isCID $CID_1)) && echoErr "ERROR: Expected '$CID_1' to be a valid CID, but got false response" && exit 1 || echoInfo "INFO: Test 2 passed"
($(isCID $CID_e0)) && echoErr "ERROR: Expected '$CID_e0' to be an invalid CID, but got true response" && exit 1 || echoInfo "INFO: Test 3 passed"
($(isCID $CID_e1)) && echoErr "ERROR: Expected '$CID_e1' to be an invalid CID, but got true response" && exit 1 || echoInfo "INFO: Test 4 passed"
($(isCID "")) && echoErr "ERROR: Expected '' to be an invalid CID, but got true response" && exit 1 || echoInfo "INFO: Test 5 passed"

#################################################################
echoWarn "TEST: isURL"

URL_0="https://github.com/KiraCore/tools/runs/7763984248?check_suite_focus=true"
URL_1="ghcr.io/kiracore/docker/base-image:v0.11.4"
URL_e0="v0.11.4"
URL_e1="http://ghcrio"

(! $(isURL $URL_0)) && echoErr "ERROR: Expected '$URL_0' to be a valid URL, but got false response" && exit 1 || echoInfo "INFO: Test 1 passed"
(! $(isURL $URL_1)) && echoErr "ERROR: Expected '$URL_1' to be a valid URL, but got false response" && exit 1 || echoInfo "INFO: Test 2 passed"
($(isURL $URL_e0)) && echoErr "ERROR: Expected '$URL_e0' to be an invalid URL, but got true response" && exit 1 || echoInfo "INFO: Test 3 passed"
($(isURL $URL_e1)) && echoErr "ERROR: Expected '$URL_e1' to be an invalid URL, but got true response" && exit 1 || echoInfo "INFO: Test 4 passed"
($(isURL "")) && echoErr "ERROR: Expected '' to be an invalid URL, but got true response" && exit 1 || echoInfo "INFO: Test 5 passed"

#################################################################
echoWarn "TEST: strShort"

TEST_S0="1234567890"
TEST_S1="$(strShort "$TEST_S0" 1)"
TEST_S2="1...0"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed string shorting, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 1 passed"

TEST_S1="$(strShort "$TEST_S0" 3)"
TEST_S2="123...890"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed string shorting, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 2 passed"

TEST_S1="$(strShort "$TEST_S0" 20)"
[ "$TEST_S1" != "$TEST_S0" ] && echoErr "ERROR: Failed string shorting, got '$TEST_S1', expected '$TEST_S0'" && exit 1 ||  echoInfo "INFO: Test 3 passed"

#################################################################
echoWarn "TEST: strFixL"

TEST_S0="1234567890"
TEST_S1="| $(strFixL "$TEST_S0" 15) |"
TEST_S2="| 1234567890      |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed L padding T1, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 1 passed"

TEST_S0="123456789423432523523523"
TEST_S1="| $(strFixL "$TEST_S0" 15) |"
TEST_S2="| 123456...523523 |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed L padding T2, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 2 passed"

TEST_S1="| $(strFixL "$TEST_S0" 16) |"
TEST_S2="| 1234567...523523 |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed L padding T3, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 3 passed"

#################################################################
echoWarn "TEST: strFixR"

TEST_S0="1234567890"
TEST_S1="| $(strFixR "$TEST_S0" 15) |"
TEST_S2="|      1234567890 |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed R padding T1, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 1 passed"

TEST_S0="123456789423432523523523"
TEST_S1="| $(strFixR "$TEST_S0" 15) |"
TEST_S2="| 123456...523523 |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed R padding T2, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 2 passed"

TEST_S1="| $(strFixR "$TEST_S0" 16) |"
TEST_S2="| 1234567...523523 |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed R padding T3, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 3 passed"

#################################################################
echoWarn "TEST: strFixC"

TEST_S0="123456789"
TEST_S1="| $(strFixC "$TEST_S0" 15) |"
TEST_S2="|    123456789    |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed C padding, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 1 passed"

TEST_S0="123456789423432523523523"
TEST_S1="| $(strFixC "$TEST_S0" 15) |"
TEST_S2="| 123456...523523 |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed C padding, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 2 passed"

TEST_S0="1234567890"
TEST_S1="| $(strFixC "$TEST_S0" 15) |"
TEST_S2="|   1234567890    |"
[ "$TEST_S1" != "$TEST_S2" ] && echoErr "ERROR: Failed C padding, got '$TEST_S1', expected '$TEST_S2'" && exit 1 ||  echoInfo "INFO: Test 3 passed"

#################################################################
echoWarn "TEST: getVar & setVar"

FILE="/tmp/test"
rm -rfv $FILE && touch $FILE

TEST_V1=" some simple value = comes here :) \n ~"
TEST_V2="somesimplevalue=comeshere:)\n~"
TEST_V3="\" some simple 2 value = comes here :) \n ~"

setVar test1 "$TEST_V1" $FILE
setVar test2 "$TEST_V2" $FILE
setVar test1 "$TEST_V3" $FILE

TEST_R1="$(getVar test1 $FILE)"
TEST_R2="$(getVar test2 $FILE)"

[ "$TEST_R1" != "$TEST_V3" ] && echoErr "ERROR: Failed value read, got '$TEST_R1', expected '$TEST_V3'" && exit 1 ||  echoInfo "INFO: Test 1 passed"
[ "$TEST_R2" != "$TEST_V2" ] && echoErr "ERROR: Failed value read, got '$TEST_R2', expected '$TEST_V2'" && exit 1 ||  echoInfo "INFO: Test 2 passed"

#################################################################
echoWarn "TEST: jsonParse"

T1_FILE="/tmp/test1"
T2_FILE="/tmp/test2"
T3_FILE="/tmp/test3"
T4_FILE="/tmp/test4"
T5_FILE="/tmp/test5"
T6_FILE="/tmp/test6"
rm -rfv $T1_FILE $T2_FILE $T3_FILE $T4_FILE $T6_FILE && touch $T1_FILE $T2_FILE $T3_FILE $T4_FILE $T6_FILE

cat > $T1_FILE << EOL
{
    "c": "a1",
    "a": {
        "z": "z1 z2 z3",
        "a": [3, 2, 1 ],
        "d": 123
    },
    "b": [ 3, 2, 1]
}
EOL

TEST_R1=$(cat $T1_FILE | jsonParse "a.d")
TEST_V1=123

jsonParse "a" "$T1_FILE" "$T2_FILE"
TEST_R2=$(cat $T2_FILE | jsonParse "a")
TEST_V2="[3,2,1]"

jsonParse "a" "$T1_FILE" "$T3_FILE" --sort_keys=true
cat > $T4_FILE << EOL
{"a":[3,2,1],"d":123,"z":"z1 z2 z3"}
EOL
# remove newline at the end
truncate -s -1 $T4_FILE

TEST_R3="$(sha256 $T3_FILE)"
TEST_V3="$(sha256 $T4_FILE)"


jsonParse "a.a" "$T1_FILE" "$T5_FILE" --sort_keys=true --indent=true
cat > $T6_FILE << EOL
[
    3,
    2,
    1
]
EOL
# remove newline at the end
truncate -s -1 $T6_FILE


TEST_R4="$(sha256 $T5_FILE)"
TEST_V4="$(sha256 $T6_FILE)"

t=1
[ "$TEST_R1" != "$TEST_V1" ] && echoErr "ERROR: Failed json Parse, got '$TEST_R1', expected '$TEST_V1'" && t=$((t + 1)) && exit 1 || echoInfo "INFO: Test $t passed"
[ "$TEST_R2" != "$TEST_V2" ] && echoErr "ERROR: Failed json Parse, got '$TEST_R2', expected '$TEST_V2'" && t=$((t + 1)) && exit 1 || echoInfo "INFO: Test $t passed"
[ "$TEST_R3" != "$TEST_V3" ] && echoErr "ERROR: Failed json Parse, got '$TEST_R3', expected '$TEST_V3'" && t=$((t + 1)) && exit 1 || echoInfo "INFO: Test $t passed"
[ "$TEST_R4" != "$TEST_V4" ] && echoErr "ERROR: Failed json Parse, got '$TEST_R4', expected '$TEST_V4'" && t=$((t + 1)) && exit 1 || echoInfo "INFO: Test $t passed"

#################################################################
echoWarn "TEST: strRangesToArr"

TEST_S1=($(strRangesToArr "1-3,4,6-7"))
TEST_V1="${TEST_S1[*]}"
TEST_R1="1 2 3 4 6 7"
[ "$TEST_V1" != "$TEST_R1" ] && echoErr "ERROR: Failed R padding T1, got '$TEST_V1', expected '$TEST_R1'" && exit 1 ||  echoInfo "INFO: Test 1 passed"

#################################################################

echoInfo "INFO: Successsfully executed all bash-utils test cases, elapsed $(prettyTime $(timerSpan))"
