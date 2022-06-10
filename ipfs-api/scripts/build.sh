#!/usr/bin/env bash
set -e
set +x
. /etc/profile
set -x

. ../bash-utils/bash-utils.sh

LOCAL_PLATFORM=$(toLower $(uname))
LOCAL_ARCH=$(([[ "$(uname -m)" == *"arm"* ]] || [[ "$(uname -m)" == *"aarch"* ]]) && echo "arm64" || echo "amd64")
LOCAL_OUT="${GOBIN}/ipfs-api"

PLATFORM="$1" && [ -z "$PLATFORM" ] && PLATFORM="$LOCAL_PLATFORM"
ARCH="$2" && [ -z "$ARCH" ] && ARCH="$LOCAL_ARCH"
OUTPUT="$3" && [ -z "$OUTPUT" ] && OUTPUT="$LOCAL_OUT"

CONSTANS_FILE=./types/constants.go
VERSION=$(grep -Fn -m 1 'IpfsApiVersion ' $CONSTANS_FILE | rev | cut -d "=" -f1 | rev | xargs | tr -dc '[:alnum:]\-\.' || echo '')
($(isNullOrEmpty "$VERSION")) && ( echoErr "ERROR: IpfsApiVersion was NOT found in contants '$CONSTANS_FILE' !" && sleep 5 && exit 1 )

rm -fv "$OUTPUT" || echo "ERROR: Failed to wipe old ipfs-api binary"

go mod tidy
GO111MODULE=on go mod verify
env GOOS=$PLATFORM GOARCH=$ARCH go build -o "$OUTPUT" ./