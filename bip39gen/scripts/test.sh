#!/usr/bin/env bash
set -e
set +x
. /etc/profile
set -x

. ../bash-utils/bash-utils.sh

BIN_bip39gen="${GOBIN}/bip39gen"

ENTROPY=$(sha256 "daring collect artist first six arena brown design park syrup jump pluck")
MNEMONIC_TEST_1=$($BIN_bip39gen mnemonic -l 12 -e "$ENTROPY")
MNEMONIC_TEST_2=$($BIN_bip39gen mnemonic -l 12 -e "$ENTROPY")

[ "$MNEMONIC_TEST_1" == "$MNEMONIC_TEST_2" ] && \
 echoErr "ERROR: When user entropy is provided expected mnemonic to change every time, in the process of being mixed with computer provided entropy" && exit 1 || echoInfo "INFO: Test 1 passed"
