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

# Test utils
cd ./bip39gen
make test
cd $WORKDIR

echoInfo "SUCCESS: Testing finished"