#!/usr/bin/env bash
set -e
set -x
. /etc/profile
. ./bash-utils/utils.sh

WORKDIR=$PWD

echoInfo "INFO: KIRA utils, latest version $(utilsVersion)"

# Build `tmconnect`
cd ./tmconnect
make build
cd $WORKDIR

cd ./validator-key-gen
make build
cd $WORKDIR


echoInfo "SUCCESS: Build finished, tmkms $(tmconnect version), validator-key-gen $(validator-key-gen --version)"