#!/usr/bin/env bash
set -e
set +x
. /etc/profile
set -x

. ./bash-utils/bash-utils.sh

WORKDIR=$PWD

echoInfo "INFO: Staring all testing utilities..."

# Test utils
cd ./bash-utils
make test
cd $WORKDIR

# Test mnemonic generator
cd ./bip39gen
make test
cd $WORKDIR

# Test tm key importer
cd ./tmkms-key-import
make test
cd $WORKDIR

# Test tm key importer
cd ./ipfs-api
make test
cd $WORKDIR

echoInfo "SUCCESS: Testing finished"