#!/usr/bin/env bash
set -e
set -x
. /etc/profile
. ./bash-utils/bash-utils.sh

WORKDIR=$PWD

echoInfo "INFO: KIRA utils, latest version $(bashUtilsVersion)"

# Build `tmconnect`
cd ./tmconnect
make build
cd $WORKDIR

cd ./validator-key-gen
make build
cd $WORKDIR

cd ./bip39gen
make build
cd $WORKDIR

cd ./ipfs-api
make build
cd $WORKDIR


echoInfo "SUCCESS: Build finished, tmkms $(tmconnect version), validator-key-gen $(validator-key-gen --version), bip39gen $(bip39gen version), ipfs-api $(ipfs-api version)"