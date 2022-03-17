#!/usr/bin/env bash
set -e
set -x
. /etc/profile
. ../bash-utils/utils.sh

go mod tidy
GO111MODULE=on go mod verify

PKG_CONFIG_FILE=./nfpm.yaml 

function pcgConfigure() {
    local ARCH="$1"
    local VERSION="$2"
    local PLATFORM="$3"
    local SOURCE="$4"
    local CONFIG="$5"
    SOURCE=${SOURCE//"/"/"\/"}
    sed -i"" "s/\${ARCH}/$ARCH/" $CONFIG
    sed -i"" "s/\${VERSION}/$VERSION/" $CONFIG
    sed -i"" "s/\${PLATFORM}/$PLATFORM/" $CONFIG
    sed -i"" "s/\${SOURCE}/$SOURCE/" $CONFIG
}

BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD || echo "")
( [ -z "$BRANCH" ] || [ "${BRANCH,,}" == "head" ] ) && BRANCH="${SOURCE_BRANCH}"

CONSTANS_FILE=./main.go
VERSION=$(grep -Fn -m 1 'TmConnectVersion ' $CONSTANS_FILE | rev | cut -d "=" -f1 | rev | xargs | tr -dc '[:alnum:]\-\.' || echo '')
($(isNullOrEmpty "$VERSION")) && ( echoErr "ERROR: TmConnectVersion was NOT found in '$CONSTANS_FILE' !" && sleep 5 && exit 1 )

function pcgRelease() {
    local ARCH="$1" && ARCH=$(echo "$ARCH" |  tr '[:upper:]' '[:lower:]' )
    local VERSION="$2" && VERSION=$(echo "$VERSION" |  tr '[:upper:]' '[:lower:]' )
    local PLATFORM="$3" && PLATFORM=$(echo "$PLATFORM" |  tr '[:upper:]' '[:lower:]' )

    local BIN_PATH=./bin/$ARCH/$PLATFORM
    local RELEASE_DIR=./bin/deb/$PLATFORM

    mkdir -p $BIN_PATH $RELEASE_DIR

    echoInfo "INFO: Building $ARCH package for $PLATFORM..."
    
    TMP_PKG_CONFIG_FILE=./nfpm_${ARCH}_${PLATFORM}.yaml
    rm -rfv $TMP_PKG_CONFIG_FILE && cp -v $PKG_CONFIG_FILE $TMP_PKG_CONFIG_FILE

    if [ "$PLATFORM" != "windows" ] ; then
        local RELEASE_PATH="${RELEASE_DIR}/tmconnect_${VERSION}_${ARCH}.deb"
        ./scripts/build.sh "${PLATFORM}" "${ARCH}" "$BIN_PATH/tmconnect"
        pcgConfigure "$ARCH" "$VERSION" "$PLATFORM" "$BIN_PATH" $TMP_PKG_CONFIG_FILE
        nfpm pkg --packager deb --target "$RELEASE_PATH" -f $TMP_PKG_CONFIG_FILE
        cp -fv "$RELEASE_PATH" ./bin/tmconnect-${PLATFORM}-${ARCH}.deb
    else
        ./scripts/build.sh "${PLATFORM}" "${ARCH}" "$BIN_PATH/tmconnect.exe"
        # deb is not supported on windows, simply copy the executables
        cp -fv $BIN_PATH/tmconnect.exe ./bin/tmconnect-${PLATFORM}-${ARCH}.exe
    fi
}

rm -rfv ./bin

# NOTE: To see available build architectures, run: go tool dist list
pcgRelease "amd64" "$VERSION" "linux"
pcgRelease "amd64" "$VERSION" "darwin"
pcgRelease "amd64" "$VERSION" "windows"
pcgRelease "arm64" "$VERSION" "linux"
pcgRelease "arm64" "$VERSION" "darwin"
pcgRelease "arm64" "$VERSION" "windows"

rm -rfv ./bin/amd64 ./bin/arm64 ./bin/deb
echoInfo "INFO: Sucessfully published SEKAI deb packages into ./bin"
