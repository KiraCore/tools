#!/usr/bin/env bash
set -e
set +x
. /etc/profile
set -x

. ./bash-utils/bash-utils.sh

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

# Publish bip39gen
cd ./bip39gen
make publish
cd $WORKDIR

# Publish ipfs-api
cd ./ipfs-api
make publish
cd $WORKDIR

# Copy all binaries to bin directory
mkdir -p ./bin

cp -rfv ./tmconnect/bin/* ./bin
cp -rfv ./tmkms-key-import/bin/* ./bin
cp -rfv ./validator-key-gen/bin/* ./bin
cp -rfv ./bip39gen/bin/* ./bin
cp -rfv ./bash-utils/bash-utils.sh ./bin/bash-utils.sh

rm -rfv ./tmconnect/bin/*
rm -rfv ./tmkms-key-import/bin/*
rm -rfv ./validator-key-gen/bin/*
rm -rfv ./bip39gen/bin/*