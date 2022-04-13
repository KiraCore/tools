#!/usr/bin/env bash
set -e
set +x
. /etc/profile
set -x

cd ./bip39 || echo "Already in the root dir"

. ../../bash-utils/bash-utils.sh

LOCAL_PLATFORM=$(toLower $(uname))
LOCAL_ARCH=$(([[ "$(uname -m)" == *"arm"* ]] || [[ "$(uname -m)" == *"aarch"* ]]) && echo "arm64" || echo "amd64")
LOCAL_OUT="${GOBIN}/bip39"

PLATFORM="$1" && [ -z "$PLATFORM" ] && PLATFORM="$LOCAL_PLATFORM"
ARCH="$2" && [ -z "$ARCH" ] && ARCH="$LOCAL_ARCH"
OUTPUT="$3" && [ -z "$OUTPUT" ] && OUTPUT="$LOCAL_OUT"

CONSTANS_FILE=./bip39.go
VERSION=$(grep -Fn -m 1 'Bip39Version ' $CONSTANS_FILE | rev | cut -d "=" -f1 | rev | xargs | tr -dc '[:alnum:]\-\.' || echo '')
($(isNullOrEmpty "$VERSION")) && ( echoErr "ERROR: Bip39Version was NOT found in contants '$CONSTANS_FILE' !" && sleep 5 && exit 1 )

rm -fv "$OUTPUT" || echo "ERROR: Failed to wipe old bip39 binary"

go mod tidy
GO111MODULE=on go mod verify
env GOOS=$PLATFORM GOARCH=$ARCH go build -o "$OUTPUT" ./
