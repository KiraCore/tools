#!/usr/bin/env bash
set -e
set -x
. /etc/profile

LOCAL_PLATFORM="$(uname)" && LOCAL_PLATFORM="$(echo "$LOCAL_PLATFORM" |  tr '[:upper:]' '[:lower:]' )"
LOCAL_ARCH=$(([[ "$(uname -m)" == *"arm"* ]] || [[ "$(uname -m)" == *"aarch"* ]]) && echo "arm64" || echo "amd64")
LOCAL_OUT="${GOBIN}/tmconnect"

PLATFORM="$1" && [ -z "$PLATFORM" ] && PLATFORM="$LOCAL_PLATFORM"
ARCH="$2" && [ -z "$ARCH" ] && ARCH="$LOCAL_ARCH"
OUTPUT="$3" && [ -z "$OUTPUT" ] && OUTPUT="$LOCAL_OUT"

CONSTANS_FILE=./main.go
VERSION=$(grep -Fn -m 1 'TmConnectVersion ' $CONSTANS_FILE | rev | cut -d "=" -f1 | rev | xargs | tr -dc '[:alnum:]\-\.' || echo '')
($(isNullOrEmpty "$VERSION")) && ( echoErr "ERROR: TmConnectVersion was NOT found in contants '$CONSTANS_FILE' !" && sleep 5 && exit 1 )

rm -fv "$OUTPUT" || echo "ERROR: Failed to wipe old sekaid binary"

go mod tidy
GO111MODULE=on go mod verify
env GOOS=$PLATFORM GOARCH=$ARCH go build -o "$OUTPUT" ./

( [ "$PLATFORM" == "$LOCAL_PLATFORM" ] && [ "$ARCH" == "$LOCAL_ARCH" ] && [ -f $OUTPUT ] ) && \
    echoInfo "INFO: Sucessfully built tmconnect $($OUTPUT version)" || echoInfo "INFO: Sucessfully built tmconnect to '$OUTPUT'"

