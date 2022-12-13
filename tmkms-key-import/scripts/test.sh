#!/usr/bin/env bash
set -e
set +x
. /etc/profile
set -x

. ../bash-utils/bash-utils.sh

LOCAL_PLATFORM="$(uname)" && LOCAL_PLATFORM="$(echo "$LOCAL_PLATFORM" |  tr '[:upper:]' '[:lower:]' )"
LOCAL_ARCH=$(([[ "$(uname -m)" == *"arm"* ]] || [[ "$(uname -m)" == *"aarch"* ]]) && echo "arm64" || echo "amd64")

./bin/tmkms-key-import-${LOCAL_PLATFORM}-${LOCAL_ARCH} version
