#!/usr/bin/env bash
set -e
set -x
. /etc/profile
. ./bash-utils/utils.sh

WORKDIR=$PWD

BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD || echo "")
( [ -z "$BRANCH" ] || [ "${BRANCH,,}" == "head" ] ) && BRANCH="${SOURCE_BRANCH}"

# Cleanup old binaries
rm -rfv ./bin

# Publish tmconnect
cd ./tmconnect
make publish
cd $WORKDIR

# Publish tmkms-key-import
cd ./tmkms-key-import
make publish
cd $WORKDIR

# Publish validator-key-gen
cd ./validator-key-gen
make publish
cd $WORKDIR

# Copy all binaries to bin directory
mkdir -p ./bin

cp -rfv ./tmconnect/bin/* ./bin
cp -rfv ./tmkms-key-import/bin/* ./bin
cp -rfv ./validator-key-gen/bin/* ./bin
cp -rfv ./bash-utils/utils.sh ./bin/kira-utils.sh

rm -rfv ./tmconnect/bin/*
rm -rfv ./tmkms-key-import/bin/*
rm -rfv ./validator-key-gen/bin/*