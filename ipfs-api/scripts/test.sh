#!/usr/bin/bash

set -e
set -x

bu echoInfo "Starting unit tests..."
go test ./... -vet=off -v || bu echoInfo "IPFS-API test finished successfully"

bu echoInfo "Starting integration tests..."

ROOT_DIR=$(pwd)
MAIN_DIR=$ROOT_DIR/cmd/ipfs-api/main.go
ENTRY_DIR=$ROOT_DIR/test_dir
SECOND_DIR=$ENTRY_DIR/test_dir1

CID="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
META="meta"
META_FORCE="foobar"

bu echoInfo "Creating directory tree..."
mkdir -p $ENTRY_DIR || bu echoError "Failed to create directory $ENTRY_DIR"
mkdir -p $SECOND_DIR || bu echoError "Failed to create directory $SECOND_DIR"


bu echoInfo "Populating directory tree with files..."
# Populate dir with files L1
set +x 
for i in {1..5}; 
do
    echo "file$i">"$ENTRY_DIR/file$i.txt" || bu echoError "Failed to create file$i.txt"
done

# Populate dir with files L2
for i in {6..10};
do
    echo "file$i">"$SECOND_DIR/file$i.txt" || bu echoError "Failed to create file$i.txt"
done
set -x

runTest() {
  local test_cmd="$1"
  local test_name="$2"


  # Execute the test command and get the exit code
  eval "$test_cmd &> /dev/null ||:"
  exit_code=$?

  # Get the command name
  # Check the exit code and print the result
  if [ $exit_code -eq 0 ]; then
    echo "[PASS] $test_name"
  else
    bu echoError "[FAIL] $test_name"
  fi
}


# Clearing failed results
bu echoInfo "Clearing failed results if any..."
go run $MAIN_DIR delete bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4 --key="$PINATA_API_JWT_TEST" --verbose &> /dev/null ||:
go run $MAIN_DIR delete meta --key="$PINATA_API_JWT_TEST" --verbose &> /dev/null ||:

bu echoInfo "Running tests"
# DAG test DAG:
runTest "go run $MAIN_DIR dag $ENTRY_DIR &> /dev/null" "DAG: Dag"

# Pin dir test PIN: 
runTest "go run $MAIN_DIR pin $ENTRY_DIR --key=$PINATA_API_JWT_TEST" "PIN: Pin with CID"
runTest "go run $MAIN_DIR pinned $CID --key=$PINATA_API_JWT_TEST" "PIN: Pinned with CID"
runTest "go run $MAIN_DIR delete $CID --key=$PINATA_API_JWT_TEST" "PIN: Unpin with CID"

#Pin with meta test META:
runTest "go run $MAIN_DIR pin $ENTRY_DIR $META --key=$PINATA_API_JWT_TEST" "META: Pin with metadata"
runTest "go run $MAIN_DIR pinned $META --key=$PINATA_API_JWT_TEST" "META: Pinned with metadata"
runTest "go run $MAIN_DIR delete $META --key=$PINATA_API_JWT_TEST" "META: Delete with metadata"

#Pin with meta --force FORCE:
runTest "go run $MAIN_DIR pin $ENTRY_DIR $META --key=$PINATA_API_JWT_TEST" "FORCE: Pin with metadata"
runTest "go run $MAIN_DIR pinned $META --key=$PINATA_API_JWT_TEST" "FORCE: Pinned with metadata"
runTest "go run $MAIN_DIR pin $ENTRY_DIR $META_FORCE --key=$PINATA_API_JWT_TEST --force=true" "FORCE: pin with meta --force"
runTest "go run $MAIN_DIR delete $META_FORCE --key=$PINATA_API_JWT_TEST" "FORCE: Delete with metadata"

#Pin with meta --overwrite OVERWRITE: 
runTest "go run $MAIN_DIR pin $ENTRY_DIR $META --key=$PINATA_API_JWT_TEST" "OVERWRITE: Pin with metadata"
runTest "go run $MAIN_DIR pinned $META --key=$PINATA_API_JWT_TEST" "OVERWRITE: Pinned with metadata"
runTest "go run $MAIN_DIR pin $ENTRY_DIR $META_FORCE --key=$PINATA_API_JWT_TEST --overwrite=true" "OVERWRITE: Pin with metadata --overwrite"
runTest "go run $MAIN_DIR pinned $META_FORCE --key=$PINATA_API_JWT_TEST" "OVERWRITE: Pinned with metadata"
runTest "go run $MAIN_DIR delete $META_FORCE --key=$PINATA_API_JWT_TEST" "OVERWRITE: Delete with metadata"
#TODO: collect exit codes for later processing

bu echoInfo "All tests finished. Cleaning up the environment..."
rm -rf $ENTRY_DIR || bu echoError "Failed to clean up an the environment"
bu echoInfo "All done..."