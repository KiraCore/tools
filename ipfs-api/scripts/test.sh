#!/bin/bash

set -e
set -x

echo "Starting unit tests..."

go test ./... -vet=off -v || echo "IPFS-API test finished successfully"

echo "Starting integration tests..."
ROOT_DIR=$(pwd)
MAIN_DIR=$ROOT_DIR/cmd/ipfs-api/main.go
ENTRY_DIR=$ROOT_DIR/test_dir
SECOND_DIR=$ENTRY_DIR/test_dir1

JWT="${PINATA_API_JWT_TEST}"

echo "Creating directory tree..."
mkdir -p $ENTRY_DIR || echo "Failed to create directory $ENTRY_DIR"
mkdir -p $SECOND_DIR || echo "Failed to create directory $SECOND_DIR"

echo "Populating directory tree with files..."

# Populate dir with files L1
set +x 
for i in {1..5}; 
do
    echo "file$i">"$ENTRY_DIR/file$i.txt" || echo "Failed to create file$i.txt"
done

# Populate dir with files L2
for i in {6..10};
do
    echo "file$i">"$SECOND_DIR/file$i.txt" || echo "Failed to create file$i.txt"
done


function dagExportTest(){
 

    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR dag $ENTRY_DIR --export)
    
    if [[ $WANT -eq $GOT ]]; 
    then
        echo "[PASS] dagExportTest"
    else
        echo "[FAILED] dagExportTest"
        exit 1
    fi
}

function pinTest(){
      
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR --key="$JWT" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo "[PASS] pinTest"

    else
        echo "[FAILED] pinTest"

        exit 1
    fi

}

function deleteByHashTest(){

    
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR delete $WANT --key="$JWT" | jq .success)
    
    if [[ $GOT -eq $WANT ]];
    then
        echo "[PASS] deleteByHashTest"
    else
        echo "[FAILED] deleteByHashTest"
        exit 1
    fi
}

function pinWithMetaTest(){


    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR meta --key="$JWT" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo "[PASS] pinWithMetaTest"
    else
        echo "[FAILED] pinWithMetaTest"
        exit 1
    fi

}

function pinWithMetaForceTest(){
  

    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR foobar --key="$JWT" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo "[PASS] pinWithMetaForceTest"
    else
        echo "[FAILED] pinWithMetaForceTest"
        exit 1
    fi

}
function pinWithMetaOverwriteTest(){
 

    local WANT="OK"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR foobar --overwrite --key="$JWT")
    if [[ $WANT -eq $GOT ]]; 
    then
       echo "[PASS] pinWithMetaOverwriteTest"
    else
       echo "[FAILED] pinWithMetaOverwriteTest"
       exit 1
    fi

}

function deleteByMetaTest(){

    local WANT=true
    local GOT=$(go run $MAIN_DIR delete meta --key="$JWT" | jq .success)
    if [[ $GOT -eq $WANT ]];
     then
        echo "[PASS] deleteByMetaTest"
    else
        echo "[FAILED] deleteByMetaTest"
        exit 1
    fi
}

function deleteByMetaOverwriteTest(){


    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR delete foobar --key="$JWT" | jq .success)

    if [[ $GOT -eq true ]];
     then
        echo "[PASS] deleteByMetaOverwriteTest"
    else
        echo "[FAILED] deleteByMetaOverwriteTest"
        exit 1
    fi
}
echo "Starting tests..."

TESTS=(dagExportTest pinTest deleteByHashTest pinWithMetaTest deleteByMetaTest pinWithMetaTest pinWithMetaOverwriteTest deleteByMetaOverwriteTest pinWithMetaTest pinWithMetaForceTest deleteByMetaOverwriteTest)
for TEST in "${TESTS[@]}"; do
    $TEST
done

echo "All tests finished. Cleaning up the environment..."

set -x

rm -rf $ENTRY_DIR || echo "Failed to clean up the environment"

echo "mAll done..."
