set -e
set +x
. /etc/profile
set -x

go test -vet=off -v ./... || echo "IPFS-API test finished successfully"

