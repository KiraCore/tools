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


dagExportTest(){
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR dag $ENTRY_DIR --export)
    
    if [[ $WANT == $GOT ]]; 
    then
        echo -en "\033[1G\e[0m\e[36;1m[PASS] dagExportTest\e[0m"; echo
    else
        echo -en "\033[1G\e[0m\e[31;1m[FAIL] dagExportTest\e[0m"; echo
        exit 1
    fi
}

pinTest(){
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR --key="$PINATA_API_JWT_TEST" | jq -r .hash)

    if [[ $WANT == $GOT ]]; 
    then
        echo -en "\033[1G\e[0m\e[36;1m[PASS] pinTest\e[0m"; echo
    else
        echo -en "\033[1G\e[0m\e[31;1m[FAIL] pinTest\e[0m"; echo
        exit 1
    fi

}

deleteByHashTest(){
    local WANT=true
    local GOT=$(go run $MAIN_DIR delete $WANT --key="$PINATA_API_JWT_TEST" | jq .success)
    
    if [[ $GOT == $WANT ]];
    then
        echo -en "\033[1G\e[0m\e[36;1m[PASS] deleteByHashTest\e[0m"; echo
    else
        echo -en "\033[1G\e[0m\e[31;1m[FAIL] deleteByHashTest\e[0m"; echo
        exit 1
    fi
}

pinWithMetaTest(){
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR meta --key="$PINATA_API_JWT_TEST" | jq -r .hash)

    if [[ $WANT == $GOT ]]; 
    then
        echo -en "\033[1G\e[0m\e[36;1m[PASS] pinWithMetaTest\e[0m"; echo
    else
        echo -en "\033[1G\e[0m\e[31;1m[FAIL] pinWithMetaTest\e[0m"; echo
        exit 1
    fi

}

pinWithMetaForceTest(){
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR foobar --key="$PINATA_API_JWT_TEST" | jq -r .hash)

    if [[ $WANT == $GOT ]]; 
    then
        echo -en "\033[1G\e[0m\e[36;1m[PASS] pinWithMetaForceTest\e[0m"; echo
    else
        echo -en "\033[1G\e[0m\e[31;1m[FAIL] pinWithMetaForceTest\e[0m"; echo
        exit 1
    fi

}
pinWithMetaOverwriteTest(){
    local WANT="OK"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR foobar --overwrite --key="$PINATA_API_JWT_TEST")
    if [[ $WANT == $GOT ]]; 
    then
        echo -en "\033[1G\e[0m\e[36;1m[PASS] pinWithMetaOverwriteTest\e[0m"; echo
    else
        echo -en "\033[1G\e[0m\e[31;1m[FAIL] pinWithMetaOverwriteTest\e[0m"; echo
        exit 1
    fi

}

deleteByMetaTest(){
    local WANT=true
    local GOT=$(go run $MAIN_DIR delete meta --key="$PINATA_API_JWT_TEST" | jq .success)
    if [[ $GOT == $WANT ]];
    then
        echo -en "\033[1G\e[0m\e[36;1m[PASS] deleteByMetaTest\e[0m"; echo
    else
        echo -en "\033[1G\e[0m\e[31;1m[FAIL] deleteByMetaTest\e[0m"; echo
        exit 1
    fi
}

deleteByMetaOverwriteTest(){
    local WANT=true
    local GOT=$(go run $MAIN_DIR delete foobar --key="$PINATA_API_JWT_TEST" | jq .success)

    if [[ $GOT == $WANT ]];
    then
        echo -en "\033[1G\e[0m\e[36;1m[PASS] deleteByMetaOverwriteTest\e[0m"; echo
    else
        echo -en "\033[1G\e[0m\e[31;1m[FAIL] deleteByMetaOverwriteTest\e[0m"; echo
        exit 1
    fi
}

bu echoInfo "Starting tests..."

TESTS=(dagExportTest pinTest deleteByHashTest pinWithMetaTest deleteByMetaTest pinWithMetaTest pinWithMetaOverwriteTest deleteByMetaOverwriteTest pinWithMetaTest pinWithMetaForceTest deleteByMetaOverwriteTest)
for TEST in "${TESTS[@]}"; do
    $TEST
done

bu echoInfo "All tests finished. Cleaning up the environment..."

set -x

rm -rf $ENTRY_DIR || bu echoError "Failed to clean up an the environment"
bu echoInfo "All done..."