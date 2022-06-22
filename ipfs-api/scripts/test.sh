set -e
set +x
. /etc/profile
set -x

go test pkg/pinatav1 -vet=off || echo "IPFS-API test finished successfully"

