#!/usr/bin/env bash
set -e
set -x
. /etc/profile

cd ./bip39 || echo "Already in the root dir"

. ../../bash-utils/bash-utils.sh

go test -v -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
go test -v -cover ./...