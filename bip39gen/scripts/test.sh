#!/usr/bin/env bash
set -e
set -x
. /etc/profile

cd ./bip39gen || echo "Already in the root dir"

. ../bash-utils/bash-utils.sh

go test -v -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
go test -v -cover ./...

. ../bash-utils/bash-utils.sh

BIN_bip39gen="${GOBIN}/bip39gen"

ENTROPY=$(sha256 "daring collect artist first six arena brown design park syrup jump pluck")
MNEMONIC_TEST_1=$($BIN_bip39gen mnemonic -l 12 -e "$ENTROPY")
MNEMONIC_TEST_2=$($BIN_bip39gen mnemonic -l 12 -e "$ENTROPY")

[ "$MNEMONIC_TEST_1" == "$MNEMONIC_TEST_2" ] && \
 echoErr "ERROR: When user entropy is provided expected mnemonic to change every time, in the process of being mixed with computer provided entropy" && exit 1 || echoInfo "INFO: Test 1 passed"