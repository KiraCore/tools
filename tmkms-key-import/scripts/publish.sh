#!/usr/bin/env bash
set -e
set +x
. /etc/profile
set -x

. ../bash-utils/bash-utils.sh

LOCAL_PLATFORM="$(uname)" && LOCAL_PLATFORM="$(echo "$LOCAL_PLATFORM" |  tr '[:upper:]' '[:lower:]' )"
LOCAL_ARCH=$(([[ "$(uname -m)" == *"arm"* ]] || [[ "$(uname -m)" == *"aarch"* ]]) && echo "arm64" || echo "amd64")
BASEDIR=$PWD
WORKDIR=./bin/.work
SPECDIR=./bin/.spec
DISTDIR=./bin/.dist

rm -rfv ./bin
mkdir -p ./bin

function pcgRelease() {
    local ARCH="$1" && ARCH=$(toLower "$ARCH")
    local VERSION="$2" && VERSION=$(toLower "$VERSION")
    local PLATFORM="$3" && PLATFORM=$(toLower "$PLATFORM")

    #local BIN_PATH=./bin/$ARCH/$PLATFORM
    #local RELEASE_DIR=./bin/deb/$PLATFORM
    #mkdir -p $BIN_PATH $RELEASE_DIR

    echoInfo "INFO: Building $ARCH package for $PLATFORM..."
    
    #TMP_PKG_CONFIG_FILE=./nfpm_${ARCH}_${PLATFORM}.yaml
    #rm -rfv $TMP_PKG_CONFIG_FILE && cp -v $PKG_CONFIG_FILE $TMP_PKG_CONFIG_FILE

    [ "$ARCH" == "amd64" ] && ARCH_PY="x86_64" || ARCH_PY="$ARCH"

    if [ "$PLATFORM" == "windows" ] ; then
        echoErr "ERROR: Unsupported platform '$PLATFORM'" && exit 1
    elif [ "$PLATFORM" == "darwin" ] ; then
        echoErr "ERROR: Unsupported platform '$PLATFORM'" && exit 1
    elif [ "$PLATFORM" == "linux" ] ; then
        pyinstaller ./tmkms-key-import.py \
 --log-level=DEBUG \
 --onefile \
 --clean \
 --name "tmkms-key-import" \
 --workpath=$WORKDIR \
 --specpath=$SPECDIR \
 --distpath=$DISTDIR \
 --target-architecture="$ARCH_PY" \
 --noconfirm
    else
        echoErr "ERROR: Unknown platform '$PLATFORM'" && exit 1
    fi

    cp -fv $DISTDIR/tmkms-key-import ./bin/tmkms-key-import-${PLATFORM}-${ARCH}
    rm -rfv $WORKDIR $SPECDIR $DISTDIR __pycache__
}

# NOTE: Pyinstaller ONLY creates releases for the architecrutes it runs on, the binary will fail on the incompatible arch !!!
pcgRelease "$LOCAL_ARCH" "$VERSION" "linux"

LOCAL_BIN="tmkms-key-import-${LOCAL_PLATFORM}-${LOCAL_ARCH}"

[ -f $LOCAL_BIN ] && ./bin/tmkms-key-import-${LOCAL_PLATFORM}-${LOCAL_ARCH} version

cd $BASEDIR